class Asset < ApplicationRecord
  has_many :etf_holdings, dependent: :nullify
  has_many :etfs, through: :etf_holdings
  has_many :portfolio_asset_entries, dependent: :destroy
  has_many :portfolios, through: :portfolio_asset_entries
  
  validates :identifier, presence: true, uniqueness: true
  validates :name, presence: true
  
  scope :by_type, ->(type) { where(asset_type: type) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_industry, ->(industry) { where(industry: industry) }
  
  # Find or create an asset based on standard details with concurrency protection
  def self.find_or_create_by_normalized_identifier(details)
    # Normalize the identifier - could be a ticker or ISIN
    identifier = normalize_identifier(details[:asset_identifier])
    Rails.logger.info("Normalized identifier: #{identifier}")
    Rails.logger.info("Details: #{details.inspect}")
    
    # Log price information specifically 
    Rails.logger.info("Price information for #{identifier}: price=#{details[:price].inspect}, currency=#{details[:currency].inspect}")
    
    # Extract a base identifier for fuzzy matching
    base_identifier = extract_base_identifier(identifier)
    
    # Try to find by exact identifier first (outside transaction for performance)
    asset = find_by(identifier: identifier)
    
    if asset.present?
      # Update the price information if provided
      if details[:price].present?
        Rails.logger.info("Updating existing asset #{identifier} with price: #{details[:price]} #{details[:currency]}")
        asset.price = details[:price]
        asset.price_currency = details[:currency]
        asset.price_as_of_date = Time.current
        asset.update_normalized_price
        asset.save
      else
        Rails.logger.info("No price information provided for existing asset #{identifier}")
      end
      return asset
    end
    
    # Try to find by similar identifiers (outside transaction for performance)
    asset = where("identifier LIKE ?", "%#{base_identifier}%").first
    
    if asset.present?
      # Update the price information if provided
      if details[:price].present?
        Rails.logger.info("Updating similar asset #{asset.identifier} with price: #{details[:price]} #{details[:currency]}")
        asset.price = details[:price]
        asset.price_currency = details[:currency]
        asset.price_as_of_date = Time.current
        asset.update_normalized_price
        asset.save
      else
        Rails.logger.info("No price information provided for similar asset #{asset.identifier}")
      end
      return asset
    end
    
    # If not found, use a transaction with advisory lock to prevent duplicates
    transaction do
      # Use PostgreSQL advisory lock based on a hash of the base identifier
      # This ensures that only one process can create an asset with this base identifier at a time
      lock_id = Zlib.crc32(base_identifier) % 2147483647 # Generate a 32-bit integer for the lock
      connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
      
      # Check again inside the transaction in case another process created it
      # while we were waiting for the lock
      asset = find_by(identifier: identifier)
      
      if asset.present?
        # Update the price information if provided
        if details[:price].present?
          Rails.logger.info("Updating existing asset #{identifier} (inside transaction) with price: #{details[:price]} #{details[:currency]}")
          asset.price = details[:price]
          asset.price_currency = details[:currency]
          asset.price_as_of_date = Time.current
          asset.update_normalized_price
          asset.save
        else
          Rails.logger.info("No price information provided for existing asset #{identifier} (inside transaction)")
        end
        return asset
      end
      
      # Check for similar identifiers again
      asset = where("identifier LIKE ?", "%#{base_identifier}%").first
      
      if asset.present?
        # Update the price information if provided
        if details[:price].present?
          Rails.logger.info("Updating similar asset #{asset.identifier} (inside transaction) with price: #{details[:price]} #{details[:currency]}")
          asset.price = details[:price]
          asset.price_currency = details[:currency]
          asset.price_as_of_date = Time.current
          asset.update_normalized_price
          asset.save
        else
          Rails.logger.info("No price information provided for similar asset #{asset.identifier} (inside transaction)")
        end
        return asset
      end
      
      # If still not found, create a new asset
      Rails.logger.info("Creating new asset #{identifier} with price: #{details[:price].inspect} #{details[:currency].inspect}")
      new_asset = create!(
        identifier: identifier,
        name: details[:asset_name],
        asset_type: details[:asset_type],
        industry: details[:industry],
        country: details[:country],
        price: details[:price],
        price_currency: details[:currency],
        price_as_of_date: details[:price].present? ? Time.current : nil
      )
      
      # Set the normalized price for the new asset
      if details[:price].present?
        Rails.logger.info("Normalizing price for new asset #{identifier}")
        new_asset.update_normalized_price
        new_asset.save
      else
        Rails.logger.info("No price to normalize for new asset #{identifier}")
      end
      
      new_asset
    end
  end
  
  # Update the normalized USD price based on the current price and currency
  def update_normalized_price
    return unless price.present? && price_currency.present?
    
    if price_currency.upcase == 'USD'
      # If already in USD, just copy the value
      self.price_usd = price
      self.price_usd_as_of_date = price_as_of_date
    elsif is_bond_asset?
      # For bonds, we handle differently - bonds are typically quoted as a percentage
      # of face value (par), which is currency-independent
      # We simply keep the percentage value rather than converting
      self.price_usd = price
      self.price_usd_as_of_date = price_as_of_date
      Rails.logger.info("Bond asset #{identifier} - using price as is (#{price})")
    else
      # Convert to USD using exchange rate
      converted_price = ExchangeRate.convert_to_usd(price, price_currency)
      
      if converted_price.present?
        self.price_usd = converted_price
        self.price_usd_as_of_date = Time.current
        Rails.logger.info("Converted price for #{identifier}: #{price} #{price_currency} → #{price_usd} USD")
      else
        Rails.logger.warn("Could not convert price for #{identifier}: missing exchange rate for #{price_currency}")
      end
    end
  end
  
  # Check if this is a bond asset
  def is_bond_asset?
    asset_type&.downcase == 'bond'
  end
  
  # Current USD price for the asset - handles different asset types
  def current_usd_price
    if price_usd.present?
      price_usd
    elsif price.present? && price_currency.present?
      if price_currency.upcase == 'USD'
        price
      else
        # Try to convert if we don't have a stored USD price
        ExchangeRate.convert_to_usd(price, price_currency)
      end
    else
      nil
    end
  end
  
  # Standardize an asset identifier to reduce duplication
  def self.normalize_identifier(identifier)
    return nil unless identifier.present?
    
    # Remove whitespace and convert to uppercase
    id = identifier.to_s.strip.upcase
    
    # Remove common prefixes/exchange codes
    id = id.gsub(/^(NYSE:|NASDAQ:|NYSEARCA:|BATS:|TSE:|LSE:)/, '')
    
    # Normalize separators to standard form (e.g., "AAPL.US" to "AAPL_US")
    id = id.gsub(/[.:,\/\\]/, '_')
    
    # Handle ISINs (12-character alphanumeric identifiers) specially
    if id =~ /^[A-Z0-9]{12}$/
      # Leave ISINs unchanged
      return id
    end
    
    # Clean up remaining invalid characters
    id.gsub(/[^A-Z0-9_]/, '')
  end
  
  # Extract the base part of an identifier (without exchange suffix)
  def self.extract_base_identifier(identifier)
    return nil unless identifier.present?
    
    # Extract the part before any separator
    base = identifier.split(/[_.:,\/\\]/).first
    
    # Ensure we have at least 2 characters
    base.present? && base.length >= 2 ? base : identifier
  end
  
  # Find assets present in multiple ETFs
  def self.find_overlapping_assets(min_etfs = 2)
    joins(:etf_holdings)
      .select('assets.*, COUNT(DISTINCT etf_holdings.etf_id) as etf_count')
      .group('assets.id')
      .having('COUNT(DISTINCT etf_holdings.etf_id) >= ?', min_etfs)
      .order('etf_count DESC')
  end
  
  # Get all ETFs that hold this asset with their weights
  def etf_weights(as_of_date = nil)
    query = etf_holdings.includes(:etf)
    query = query.where(as_of_date: as_of_date) if as_of_date
    
    # If no date specified, get the most recent holding for each ETF
    unless as_of_date
      latest_holdings = {}
      
      etf_holdings.order(as_of_date: :desc).each do |holding|
        etf_id = holding.etf_id
        latest_holdings[etf_id] ||= holding
      end
      
      return latest_holdings.values.map do |holding|
        {
          etf_id: holding.etf_id,
          ticker: holding.etf.ticker,
          name: holding.etf.name,
          weight: holding.weight,
          as_of_date: holding.as_of_date
        }
      end
    end
    
    # Return weights for the specified date
    query.map do |holding|
      {
        etf_id: holding.etf_id,
        ticker: holding.etf.ticker,
        name: holding.etf.name,
        weight: holding.weight,
        as_of_date: holding.as_of_date
      }
    end
  end
  
  # Update normalized prices for all assets that have a non-USD price
  def self.update_all_normalized_prices
    count = 0
    
    where.not(price: nil)
         .where.not(price_currency: nil)
         .where("price_usd IS NULL OR price_usd_as_of_date < price_as_of_date")
         .find_each do |asset|
      asset.update_normalized_price
      if asset.changed?
        asset.save
        count += 1
      end
    end
    
    Rails.logger.info("Updated normalized USD prices for #{count} assets")
    count
  end
end 