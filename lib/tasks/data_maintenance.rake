namespace :data_maintenance do
  desc "Find and merge potential duplicate assets"
  task merge_duplicate_assets: :environment do
    Rails.logger.info("Starting duplicate asset detection and merging...")
    
    # Get all assets
    assets = Asset.all
    total_assets = assets.count
    merged_count = 0
    
    # Group assets by their base identifier
    base_identifiers = {}
    
    assets.each do |asset|
      base = Asset.extract_base_identifier(asset.identifier)
      next unless base.present?
      
      base_identifiers[base] ||= []
      base_identifiers[base] << asset
    end
    
    # Process each group of potentially duplicate assets
    base_identifiers.each do |base, asset_group|
      # Skip if there's only one asset with this base identifier
      next if asset_group.size <= 1
      
      Rails.logger.info("Found #{asset_group.size} potential duplicates for base '#{base}': #{asset_group.map(&:identifier).join(', ')}")
      
      # Sort by criteria to determine which asset to keep
      # Prioritize:
      # 1. Assets with more holdings
      # 2. Assets with more complete data (non-nil fields)
      # 3. Assets with shorter identifiers (often cleaner)
      sorted_assets = asset_group.sort_by do |asset|
        holding_count = asset.etf_holdings.count
        non_nil_fields = [asset.name, asset.asset_type, asset.industry, asset.country].compact.size
        [-holding_count, -non_nil_fields, asset.identifier.length]
      end
      
      # The first asset after sorting is the one to keep
      primary_asset = sorted_assets.first
      duplicates = sorted_assets[1..-1]
      
      # Merge duplicates into the primary asset
      duplicates.each do |duplicate|
        begin
          Asset.transaction do
            # Update holdings to point to primary asset
            duplicate.etf_holdings.update_all(asset_id: primary_asset.id)
            
            # Copy any non-nil fields from duplicate to primary if primary's is nil
            primary_asset.asset_type ||= duplicate.asset_type
            primary_asset.industry ||= duplicate.industry
            primary_asset.country ||= duplicate.country
            
            # If the names differ, keep the longer name as it might be more descriptive
            if duplicate.name.present? && (primary_asset.name.nil? || duplicate.name.length > primary_asset.name.length)
              primary_asset.name = duplicate.name
            end
            
            # Save changes to primary asset
            primary_asset.save!
            
            # Delete the duplicate
            duplicate.reload.destroy!
            merged_count += 1
            
            Rails.logger.info("Merged duplicate asset #{duplicate.identifier} into #{primary_asset.identifier}")
          end
        rescue => e
          Rails.logger.error("Error merging asset #{duplicate.identifier}: #{e.message}")
        end
      end
    end
    
    Rails.logger.info("Asset merging complete. Started with #{total_assets} assets, merged #{merged_count} duplicates.")
    puts "Asset merging complete. Started with #{total_assets} assets, merged #{merged_count} duplicates."
  end

  desc "Purge all ETF holdings and assets for a fresh start"
  task purge_holdings_and_assets: :environment do
    puts "Are you sure you want to delete ALL ETF holdings and assets? This cannot be undone."
    puts "Type 'yes' to confirm or anything else to cancel:"
    
    confirmation = STDIN.gets.chomp.downcase
    
    if confirmation == 'yes'
      ActiveRecord::Base.transaction do
        # Get counts before deletion
        holdings_count = EtfHolding.count
        assets_count = Asset.count
        
        # Clear the last_updated_at timestamp on ETFs to trigger a full refresh
        puts "Resetting last_updated_at on all ETFs..."
        Etf.update_all(last_updated_at: nil)
        
        # Delete all ETF holdings first (because they reference assets)
        puts "Deleting all ETF holdings..."
        EtfHolding.delete_all
        
        # Then delete all assets
        puts "Deleting all assets..."
        Asset.delete_all
        
        puts "Purge complete!"
        puts "Deleted #{holdings_count} ETF holdings and #{assets_count} assets."
        puts "All ETFs have been marked for re-fetching."
      end
      
      puts "You can now run your ETF data fetch jobs to rebuild the data."
    else
      puts "Operation cancelled. No data was deleted."
    end
  end
  
  # Faster version without confirmation for use in development/test environments
  desc "Purge all ETF holdings and assets without confirmation (for development use)"
  task force_purge_holdings_and_assets: :environment do
    if Rails.env.production?
      puts "This task cannot be run in production. Use data_maintenance:purge_holdings_and_assets instead."
      return
    end
    
    ActiveRecord::Base.transaction do
      # Get counts before deletion
      holdings_count = EtfHolding.count
      assets_count = Asset.count
      
      # Clear the last_updated_at timestamp on ETFs to trigger a full refresh
      Etf.update_all(last_updated_at: nil)
      
      # Delete all ETF holdings first
      EtfHolding.delete_all
      
      # Then delete all assets
      Asset.delete_all
      
      puts "Forced purge complete! Deleted #{holdings_count} ETF holdings and #{assets_count} assets."
      puts "All ETFs have been marked for re-fetching."
    end
  end
end 