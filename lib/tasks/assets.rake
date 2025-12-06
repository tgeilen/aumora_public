namespace :assets do
  desc "Update normalized USD prices for all assets"
  task update_normalized_prices: :environment do
    puts "Ensuring exchange rates are up-to-date..."
    result = ExchangeRateService.ensure_updated_rates
    
    if result[:success]
      puts "Exchange rates are current. Proceeding with price normalization..."
      
      count = Asset.update_all_normalized_prices
      
      puts "Updated normalized USD prices for #{count} assets."
      
      # Get asset counts by type
      equity_count = Asset.where(asset_type: 'equity').count
      bond_count = Asset.where(asset_type: 'bond').count
      
      # Get stats on price coverage
      total_assets = Asset.count
      assets_with_price = Asset.where.not(price: nil).count
      assets_with_usd_price = Asset.where.not(price_usd: nil).count
      
      puts "\nAsset Statistics:"
      puts "----------------"
      puts "Total assets: #{total_assets}"
      puts "Assets with prices: #{assets_with_price} (#{(assets_with_price.to_f / total_assets * 100).round(1)}%)"
      puts "Assets with USD prices: #{assets_with_usd_price} (#{(assets_with_usd_price.to_f / total_assets * 100).round(1)}%)"
      puts "Equity assets: #{equity_count}"
      puts "Bond assets: #{bond_count}"
    else
      puts "Failed to update exchange rates: #{result[:error]}"
      exit 1
    end
  end
end 