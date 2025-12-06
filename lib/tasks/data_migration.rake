namespace :data_migration do
  desc "Populate assets table and link existing ETF holdings"
  task populate_assets: :environment do
    puts "Starting asset population and linking..."
    
    # Track progress
    total_holdings = EtfHolding.count
    processed = 0
    linked = 0
    
    # Create a hash to track assets by normalized identifier
    asset_cache = {}
    
    # Check if asset_identifier column exists
    if !EtfHolding.column_names.include?('asset_identifier')
      puts "The ETF holdings table has already been normalized (asset_identifier column missing)."
      puts "This task is intended to run before removing the asset columns."
      exit 1
    end
    
    # Process holdings in batches to avoid memory issues
    EtfHolding.find_in_batches(batch_size: 1000) do |holdings_batch|
      # Group holdings by asset identifier to reduce database queries
      holdings_by_identifier = holdings_batch.group_by(&:asset_identifier)
      
      # Process each unique asset identifier
      holdings_by_identifier.each do |identifier, holdings|
        # Use the first holding as a reference for this asset
        reference_holding = holdings.first
        
        # Normalize the identifier
        normalized_id = identifier.strip.upcase
        
        # Skip if we've already processed this identifier
        unless asset_cache[normalized_id]
          # Create or find the asset
          asset = Asset.find_or_create_by!(
            identifier: normalized_id,
            name: reference_holding.asset_name,
            asset_type: reference_holding.asset_type,
            industry: reference_holding.industry,
            country: reference_holding.country
          )
          
          # Cache the asset for future holdings
          asset_cache[normalized_id] = asset.id
        end
        
        # Link all holdings to this asset
        asset_id = asset_cache[normalized_id]
        EtfHolding.where(id: holdings.map(&:id)).update_all(asset_id: asset_id)
        
        linked += holdings.size
      end
      
      processed += holdings_batch.size
      puts "Processed #{processed}/#{total_holdings} holdings (#{(processed.to_f / total_holdings * 100).round(2)}%)"
    end
    
    puts "Migration complete! Linked #{linked} holdings to #{asset_cache.size} unique assets."
  end
  
  desc "Validate all ETF holdings have associated assets"
  task validate_holdings_assets: :environment do
    puts "Validating ETF holdings assets..."
    
    missing_asset_count = EtfHolding.where(asset_id: nil).count
    
    if missing_asset_count > 0
      puts "WARNING: #{missing_asset_count} ETF holdings do not have an associated asset!"
      puts "Run 'rake data_migration:populate_assets' before normalizing the database."
    else
      puts "All ETF holdings have associated assets. Safe to proceed with normalization."
    end
  end
end 