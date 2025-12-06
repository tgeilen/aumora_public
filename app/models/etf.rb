require 'activerecord-import'

class Etf < ApplicationRecord
  belongs_to :provider, class_name: 'EtfProvider'
  has_many :holdings, class_name: 'EtfHolding', dependent: :destroy
  has_many :assets, through: :holdings
  has_many :portfolio_entries, dependent: :destroy
  has_many :portfolios, through: :portfolio_entries
  
  validates :ticker, presence: true
  validates :name, presence: true
  validates :ticker, uniqueness: { scope: :provider_id }
  
  def formatted_metadata
    metadata || {}
  end
  
  def update_holdings_from_data(holdings_data, as_of_date)
    # Use transaction to ensure atomicity
    transaction do
      # Clear existing holdings from the same date
      holdings.where(as_of_date: as_of_date).delete_all
      
      # Process holdings data
      new_holdings = []
      seen_identifiers = {}
      
      # Debug: Log sample of holding data to check for price and currency
      Rails.logger.info("Saving holdings for ETF #{ticker} with as_of_date: #{as_of_date}")
      if holdings_data.any?
        sample_holdings = holdings_data.first(3)
        Rails.logger.info("Sample of holdings data:")
        sample_holdings.each do |h|
          has_price = h[:price].present?
          Rails.logger.info("  #{h[:ticker] || h[:name]}: price=#{h[:price].inspect}, currency=#{h[:currency].inspect}, has_price=#{has_price}")
        end
        
        # Count holdings with price data
        with_price = holdings_data.count { |h| h[:price].present? }
        Rails.logger.info("Holdings with price data: #{with_price}/#{holdings_data.size}")
      end
      
      holdings_data.each do |holding_data|
        # Generate a base identifier
        base_identifier = holding_data[:ticker].presence || holding_data[:identifier]
        
        # If this identifier has been seen before, append a counter
        # This handles duplicate identifiers within a single ETF
        if seen_identifiers[base_identifier]
          seen_identifiers[base_identifier] += 1
          final_identifier = "#{base_identifier}_#{seen_identifiers[base_identifier]}"
        else
          seen_identifiers[base_identifier] = 1
          final_identifier = base_identifier
        end
        
        # Debug: Log price info for this specific holding
        Rails.logger.debug("For holding #{base_identifier}: price=#{holding_data[:price].inspect}, currency=#{holding_data[:currency].inspect}")
        
        # Find or create the asset first
        asset_details = {
          asset_identifier: final_identifier,
          asset_name: holding_data[:name],
          asset_type: holding_data[:asset_class],
          industry: holding_data[:sector],
          country: holding_data[:country],
          price: holding_data[:price],
          currency: holding_data[:currency]
        }
        
        asset = Asset.find_or_create_by_normalized_identifier(asset_details)
        
        # Create the holding with a link to the asset
        new_holding = holdings.new(
          asset: asset,
          weight: holding_data[:weight],
          as_of_date: as_of_date
        )
        
        # Add metadata if present
        if holding_data[:metadata].present?
          new_holding.metadata = holding_data[:metadata]
        end
        
        new_holdings << new_holding
      end
      
      # Bulk insert all new holdings
      if new_holdings.any?
        import_result = EtfHolding.import new_holdings, validate: true, on_duplicate_key_ignore: true
        
        if import_result.failed_instances.any?
          # Log errors for failed instances
          import_result.failed_instances.each do |failed|
            Rails.logger.error("Failed to import holding: #{failed.errors.full_messages.join(', ')}")
          end
          
          # Only raise if all imports failed
          if import_result.failed_instances.length == new_holdings.length
            raise ActiveRecord::RecordInvalid, import_result.failed_instances.first
          end
        end
      end
      
      # Update the last_updated_at timestamp
      update!(last_updated_at: Time.current)
    end
  rescue ActiveRecord::Import::MissingColumnError => e
    Rails.logger.error("Bulk import error: #{e.message}")
    
    # Fall back to individual inserts if bulk import is not available
    holdings_data.each do |holding_data|
      begin
        # Find or create the asset
        asset_details = {
          asset_identifier: holding_data[:ticker].presence || holding_data[:identifier],
          asset_name: holding_data[:name],
          asset_type: holding_data[:asset_class],
          industry: holding_data[:sector],
          country: holding_data[:country]
        }
        
        asset = Asset.find_or_create_by_normalized_identifier(asset_details)
        
        # Create the holding with a link to the asset
        holding_attributes = {
          asset: asset,
          weight: holding_data[:weight],
          as_of_date: as_of_date
        }
        
        if holding_data[:metadata].present?
          holding_attributes[:metadata] = holding_data[:metadata]
        end
        
        holdings.create!(holding_attributes)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create holding: #{e.message}")
      end
    end
    
    # Update the last_updated_at timestamp
    update!(last_updated_at: Time.current)
  rescue => e
    Rails.logger.error("Unexpected error updating holdings: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end 