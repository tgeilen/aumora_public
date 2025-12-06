class ExchangeRate < ApplicationRecord
  validates :currency, presence: true
  validates :rate_to_usd, presence: true, numericality: { greater_than: 0 }
  validates :as_of_date, presence: true
  validates :currency, uniqueness: { scope: :as_of_date, message: "already has an exchange rate for this date" }
  
  # Get the current exchange rate for a currency
  def self.current_rate(currency)
    where(currency: currency.upcase).order(as_of_date: :desc).first&.rate_to_usd
  end
  
  # Convert an amount from USD to another currency
  def self.convert_from_usd(amount, to_currency)
    return amount if to_currency.upcase == 'USD'
    
    rate = current_rate(to_currency)
    return nil unless rate
    
    amount * rate
  end
  
  # Convert an amount from another currency to USD
  def self.convert_to_usd(amount, from_currency)
    return amount if from_currency.upcase == 'USD'
    
    rate = current_rate(from_currency)
    return nil unless rate
    
    amount * (1.0 / rate)
  end
  
  # Convert between two non-USD currencies
  def self.convert(amount, from_currency, to_currency)
    return amount if from_currency.upcase == to_currency.upcase
    
    # Convert to USD first, then to the target currency
    usd_amount = convert_to_usd(amount, from_currency)
    return nil unless usd_amount
    
    convert_from_usd(usd_amount, to_currency)
  end
  
  # Update or create an exchange rate for a currency
  def self.update_rate(currency, rate_to_usd, as_of_date = Time.current)
    find_or_initialize_by(currency: currency.upcase, as_of_date: as_of_date).tap do |exchange_rate|
      exchange_rate.rate_to_usd = rate_to_usd
      exchange_rate.save!
    end
  end
  
  # Import multiple exchange rates at once
  def self.import_rates(rates_data, as_of_date = Time.current)
    rates_data.each do |currency, rate|
      update_rate(currency, rate, as_of_date)
    end
  end
end 