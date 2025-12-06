module ExchangeRateUpdater
  extend ActiveSupport::Concern
  
  # Ensure exchange rates are updated before processing
  def ensure_exchange_rates_updated
    Rails.logger.info("Ensuring exchange rates are up-to-date before ETF data fetch")
    result = ExchangeRateService.ensure_updated_rates
    
    unless result[:success]
      Rails.logger.error("Failed to update exchange rates: #{result[:error]}")
      # Continue anyway since this shouldn't block ETF data fetching
    end
  end
end 