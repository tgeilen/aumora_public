namespace :exchange_rates do
  desc "Fetch current exchange rates from API"
  task fetch: :environment do
    puts "Fetching current exchange rates..."
    result = ExchangeRateService.fetch_current_rates
    
    if result[:success]
      puts "Successfully updated exchange rates for #{result[:rates].size} currencies."
      puts "Rates as of: #{result[:timestamp]}"
    else
      puts "Failed to update exchange rates: #{result[:error]}"
      exit 1
    end
  end
  
  desc "Ensure exchange rates are up-to-date (fetch only if needed)"
  task ensure_updated: :environment do
    puts "Checking if exchange rates need updating..."
    result = ExchangeRateService.ensure_updated_rates
    
    if result[:success]
      if result[:rates].nil?
        puts "Exchange rates are already up-to-date."
      else
        puts "Successfully updated exchange rates for #{result[:rates].size} currencies."
        puts "Rates as of: #{result[:timestamp]}"
      end
    else
      puts "Failed to update exchange rates: #{result[:error]}"
      exit 1
    end
  end
  
  desc "Convert a value between currencies"
  task :convert, [:amount, :from_currency, :to_currency] => :environment do |t, args|
    amount = args[:amount].to_f
    from_currency = args[:from_currency].upcase
    to_currency = args[:to_currency].upcase
    
    # Ensure we have up-to-date rates
    ExchangeRateService.ensure_updated_rates
    
    # Perform the conversion
    result = ExchangeRate.convert(amount, from_currency, to_currency)
    
    if result.nil?
      puts "Failed to convert. Missing exchange rate for #{from_currency} or #{to_currency}."
      exit 1
    else
      puts "#{amount} #{from_currency} = #{result.round(2)} #{to_currency}"
    end
  end
end 