class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :portfolio_entries, dependent: :destroy
  has_many :etfs, through: :portfolio_entries
  has_many :portfolio_asset_entries, dependent: :destroy
  has_many :assets, through: :portfolio_asset_entries
  
  # Alias portfolio_entries as entries for frontend consistency
  alias_method :entries, :portfolio_entries
  alias_method :asset_entries, :portfolio_asset_entries
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id }
  
  def total_allocation
    etf_allocation = portfolio_entries.sum(&:current_value)
    asset_allocation = portfolio_asset_entries.sum(&:current_value)
    etf_allocation + asset_allocation
  end
  
  def holdings_breakdown
    # Combine all ETF holdings weighted by shares in portfolio
    result = { stocks: {}, industries: {}, countries: {} }
    
    # Process ETF holdings first
    process_etf_holdings(result)
    
    # Then add direct asset holdings
    process_direct_asset_holdings(result)
    
    result
  end
  
  # ETF-specific holdings breakdown
  def etf_holdings_breakdown
    result = { stocks: {}, industries: {}, countries: {} }
    process_etf_holdings_normalized(result)
    result
  end
  
  # Asset-specific holdings breakdown
  def asset_holdings_breakdown
    result = { stocks: {}, industries: {}, countries: {} }
    process_direct_asset_holdings_normalized(result)
    result
  end
  
  # Calculate total exposure to individual securities (direct + via ETFs)
  def total_holdings_exposure
    # Initialize result hash
    result = {
      securities: [],
      total_portfolio_value: 0
    }
    
    # Track securities by identifier for consolidation
    securities_map = {}
    
    # Calculate total portfolio value
    total_etf_value = portfolio_entries.sum(&:current_value)
    total_asset_value = portfolio_asset_entries.sum(&:current_value)
    result[:total_portfolio_value] = total_etf_value.to_f + total_asset_value.to_f
    
    # Process direct asset holdings first
    portfolio_asset_entries.each do |entry|
      asset = entry.asset
      shares = entry.shares.to_f
      value = entry.current_value.to_f
      
      key = asset.identifier
      
      if securities_map[key].nil?
        securities_map[key] = {
          identifier: asset.identifier,
          name: asset.name,
          security_type: asset.asset_type,
          total_shares: shares,
          total_value: value,
          direct_shares: shares,
          direct_value: value,
          etf_shares: 0.0,
          etf_value: 0.0
        }
      else
        # Update existing entry
        securities_map[key][:total_shares] = (securities_map[key][:total_shares].to_f + shares).to_f
        securities_map[key][:total_value] = (securities_map[key][:total_value].to_f + value).to_f
        securities_map[key][:direct_shares] = (securities_map[key][:direct_shares].to_f + shares).to_f
        securities_map[key][:direct_value] = (securities_map[key][:direct_value].to_f + value).to_f
      end
    end
    
    # Process ETF holdings - optimize to avoid N+1 queries
    if portfolio_entries.any?
      # Collect all ETFs
      etfs = portfolio_entries.map(&:etf)
      etf_ids = etfs.map(&:id)
      
      # Get latest dates for each ETF
      etf_dates = {}
      EtfHolding.where(etf_id: etf_ids).group(:etf_id).select('etf_id, MAX(as_of_date) as max_date').each do |record|
        etf_dates[record.etf_id] = record.max_date
      end
      
      # Preload all holdings with their assets
      all_holdings = EtfHolding.includes(:asset)
                      .where(etf_id: etf_ids)
                      .where(as_of_date: etf_dates.values.uniq)
      
      # Group holdings by ETF for efficient processing
      holdings_by_etf = all_holdings.group_by(&:etf_id)
      
      # Create a map of portfolio entries by ETF ID for quick lookup
      entries_by_etf = portfolio_entries.index_by(&:etf_id)
      
      # Process each ETF's holdings
      etf_ids.each do |etf_id|
        entry = entries_by_etf[etf_id]
        next unless entry
        
        etf_value = entry.current_value.to_f
        
        # Skip if no value
        next if etf_value.zero?
        
        # Get the latest holdings for this ETF
        latest_date = etf_dates[etf_id]
        next unless latest_date
        
        etf_holdings = holdings_by_etf[etf_id]&.select { |h| h.as_of_date == latest_date } || []
        next if etf_holdings.empty?
        
        etf_holdings.each do |holding|
          asset = holding.asset
          weight = holding.weight.to_f
          
          # Calculate estimated shares and value based on ETF weight
          security_value = (etf_value * weight).to_f
          
          # Estimate shares based on current market price
          # This is a rough approximation - in a real app, you'd use actual security prices
          security_shares = (security_value / 1.0).to_f
          
          key = asset.identifier
          
          if securities_map[key].nil?
            securities_map[key] = {
              identifier: asset.identifier,
              name: asset.name,
              security_type: asset.asset_type,
              total_shares: security_shares,
              total_value: security_value,
              direct_shares: 0.0,
              direct_value: 0.0,
              etf_shares: security_shares,
              etf_value: security_value
            }
          else
            # Update existing entry
            securities_map[key][:total_shares] = (securities_map[key][:total_shares].to_f + security_shares).to_f
            securities_map[key][:total_value] = (securities_map[key][:total_value].to_f + security_value).to_f
            securities_map[key][:etf_shares] = (securities_map[key][:etf_shares].to_f + security_shares).to_f
            securities_map[key][:etf_value] = (securities_map[key][:etf_value].to_f + security_value).to_f
          end
        end
      end
    end
    
    # Convert the map to an array
    result[:securities] = securities_map.values
    
    result
  end
  
  # Get the time of the last ETF data sync (most recent updated_at from assets table)
  def last_etf_sync_at
    Asset.maximum(:updated_at)
  end
  
  private
  
  def total_shares
    portfolio_entries.sum(:shares)
  end
  
  def process_etf_holdings(result)
    # Return early if no ETFs
    return if portfolio_entries.empty?
    
    # Calculate total portfolio value
    total_value = total_allocation
    return if total_value <= 0
    
    # Collect all ETFs first
    etfs = portfolio_entries.map(&:etf)
    
    # Get latest dates for each ETF to avoid multiple DB calls
    etf_dates = {}
    EtfHolding.where(etf_id: etfs.map(&:id)).group(:etf_id).select('etf_id, MAX(as_of_date) as max_date').each do |record|
      etf_dates[record.etf_id] = record.max_date
    end
    
    # Preload all holdings with their assets in a single query
    all_holdings = EtfHolding.includes(:asset)
                    .where(etf_id: etfs.map(&:id))
                    .where(as_of_date: etf_dates.values.uniq)
    
    # Group holdings by ETF for efficient processing
    holdings_by_etf = all_holdings.group_by(&:etf_id)
    
    portfolio_entries.each do |entry|
      # Calculate weight based on entry's value relative to total portfolio value
      weight_multiplier = entry.current_value / total_value
      
      # Get the latest holdings for this ETF (already preloaded)
      latest_date = etf_dates[entry.etf_id]
      next unless latest_date
      
      etf_holdings = holdings_by_etf[entry.etf_id]&.select { |h| h.as_of_date == latest_date } || []
      next if etf_holdings.empty?
      
      etf_holdings.each do |holding|
        weighted_percent = holding.weight * weight_multiplier
        
        # Add to stocks breakdown
        asset_key = "#{holding.asset.identifier}:#{holding.asset.name}"
        result[:stocks][asset_key] ||= 0
        result[:stocks][asset_key] += weighted_percent
        
        # Add to industry breakdown
        if holding.industry.present?
          result[:industries][holding.industry] ||= 0
          result[:industries][holding.industry] += weighted_percent
        end
        
        # Add to country breakdown
        if holding.country.present?
          result[:countries][holding.country] ||= 0
          result[:countries][holding.country] += weighted_percent
        end
      end
    end
  end
  
  # Process ETF holdings with percentages normalized to only the ETF portion
  def process_etf_holdings_normalized(result)
    # Return early if no ETFs
    return if portfolio_entries.empty?
    
    # Calculate total ETF value
    total_etf_value = portfolio_entries.sum(&:current_value)
    
    # Return early if no value
    return if total_etf_value.zero?
    
    # Collect all ETFs first
    etfs = portfolio_entries.map(&:etf)
    
    # Get latest dates for each ETF to avoid multiple DB calls
    etf_dates = {}
    EtfHolding.where(etf_id: etfs.map(&:id)).group(:etf_id).select('etf_id, MAX(as_of_date) as max_date').each do |record|
      etf_dates[record.etf_id] = record.max_date
    end
    
    # Preload all holdings with their assets in a single query
    all_holdings = EtfHolding.includes(:asset)
                    .where(etf_id: etfs.map(&:id))
                    .where(as_of_date: etf_dates.values.uniq)
    
    # Group holdings by ETF for efficient processing
    holdings_by_etf = all_holdings.group_by(&:etf_id)
    
    portfolio_entries.each do |entry|
      etf = entry.etf
      
      # Calculate this ETF's proportion based on its current value
      etf_proportion = entry.current_value / total_etf_value
      
      # Get the latest holdings for this ETF (already preloaded)
      latest_date = etf_dates[etf.id]
      next unless latest_date
      
      etf_holdings = holdings_by_etf[etf.id]&.select { |h| h.as_of_date == latest_date } || []
      next if etf_holdings.empty?
      
      # Apply this proportion to each holding
      etf_holdings.each do |holding|
        weighted_percent = holding.weight * etf_proportion
        
        # Add to stocks breakdown
        asset_key = "#{holding.asset.identifier}:#{holding.asset.name}"
        result[:stocks][asset_key] ||= 0
        result[:stocks][asset_key] += weighted_percent
        
        # Add to industry breakdown
        if holding.industry.present?
          result[:industries][holding.industry] ||= 0
          result[:industries][holding.industry] += weighted_percent
        end
        
        # Add to country breakdown
        if holding.country.present?
          result[:countries][holding.country] ||= 0
          result[:countries][holding.country] += weighted_percent
        end
      end
    end
  end
  
  def process_direct_asset_holdings(result)
    total_value = total_allocation
    
    portfolio_asset_entries.each do |entry|
      asset = entry.asset
      entry_value = entry.current_value
      
      # Skip if there's no total value to avoid division by zero
      next if total_value.zero?
      
      # Calculate weight as percentage of total portfolio value
      weight_percent = entry_value / total_value
      
      # Add to stocks breakdown
      asset_key = "#{asset.identifier}:#{asset.name}"
      result[:stocks][asset_key] ||= 0
      result[:stocks][asset_key] += weight_percent
      
      # Add to industry breakdown
      if asset.industry.present?
        result[:industries][asset.industry] ||= 0
        result[:industries][asset.industry] += weight_percent
      end
      
      # Add to country breakdown
      if asset.country.present?
        result[:countries][asset.country] ||= 0
        result[:countries][asset.country] += weight_percent
      end
    end
  end
  
  # Process direct asset holdings with percentages normalized to only the asset portion
  def process_direct_asset_holdings_normalized(result)
    # Calculate total direct asset value
    total_asset_value = portfolio_asset_entries.sum { |entry| entry.current_value }
    
    # Return early if no assets or total value is zero
    return if total_asset_value.zero?
    
    portfolio_asset_entries.each do |entry|
      asset = entry.asset
      entry_value = entry.current_value
      
      # Calculate weight as percentage of only the direct asset value
      weight_percent = entry_value / total_asset_value
      
      # Add to stocks breakdown
      asset_key = "#{asset.identifier}:#{asset.name}"
      result[:stocks][asset_key] ||= 0
      result[:stocks][asset_key] += weight_percent
      
      # Add to industry breakdown
      if asset.industry.present?
        result[:industries][asset.industry] ||= 0
        result[:industries][asset.industry] += weight_percent
      end
      
      # Add to country breakdown
      if asset.country.present?
        result[:countries][asset.country] ||= 0
        result[:countries][asset.country] += weight_percent
      end
    end
  end
end 