class ExchangeRateService
  # Currency API endpoint
  API_ENDPOINT = "https://api.currencyapi.com/v3/latest"
  
  def self.fetch_current_rates
    begin
      # Get API key from environment variable
      api_key = ENV.fetch('CURRENCY_API_KEY', nil)
      
      unless api_key.present?
        Rails.logger.error("CURRENCY_API_KEY environment variable is not set")
        return { success: false, error: "API key not configured" }
      end
      
      # Build the request URL with API key
      url = "#{API_ENDPOINT}?apikey=#{api_key}"
      
      response = HTTParty.get(url)
      
      if response.success?
        data = JSON.parse(response.body)
        
        if data["data"].present?
          # Extract the timestamp from meta data
          timestamp = if data["meta"] && data["meta"]["last_updated_at"]
            Time.parse(data["meta"]["last_updated_at"])
          else
            Time.current
          end
          
          # Process the new response format
          # Convert from { "EUR": { "code": "EUR", "value": 0.87 } } to { "EUR": 0.87 }
          rates = {}
          data["data"].each do |code, currency_data|
            rates[code] = currency_data["value"]
          end
          
          Rails.logger.info("Successfully fetched exchange rates for #{rates.size} currencies from Currency API")
          
          # Update all rates in the database
          ExchangeRate.import_rates(rates, timestamp)
          
          return { success: true, rates: rates, timestamp: timestamp }
        else
          Rails.logger.error("API response missing data: #{response.body}")
          return { success: false, error: "Invalid API response format" }
        end
      else
        Rails.logger.error("Failed to fetch exchange rates: HTTP #{response.code}")
        return { success: false, error: "HTTP #{response.code}" }
      end
    rescue => e
      Rails.logger.error("Error fetching exchange rates: #{e.message}")
      return { success: false, error: e.message }
    end
  end
  
  # Try to update rates if they're older than the specified duration
  def self.ensure_updated_rates(max_age = 12.hours)
    latest_rate = ExchangeRate.order(as_of_date: :desc).first
    
    # If no rates exist or the latest rate is older than max_age, fetch new rates
    if latest_rate.nil? || (Time.current - latest_rate.as_of_date > max_age)
      fetch_current_rates
    else
      Rails.logger.info("Exchange rates are current (last updated at #{latest_rate.as_of_date})")
      { success: true, rates: nil, timestamp: latest_rate.as_of_date }
    end
  end
end 