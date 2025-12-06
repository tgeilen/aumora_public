class PortfolioEntry < ApplicationRecord
  belongs_to :portfolio
  belongs_to :etf
  
  validates :shares, presence: true, numericality: { greater_than: 0 }
  validates :etf_id, uniqueness: { scope: :portfolio_id }
  
  # Get the current price for this ETF entry
  def current_price
    # Try to use the ETF's current price first, then purchase price, then default to 1.0
    etf.current_price || purchase_price || 1.0
  end
  
  def current_value
    shares * current_price
  end
  
  def weight_in_portfolio
    if portfolio.total_allocation.zero?
      0
    else
      current_value / portfolio.total_allocation
    end
  end
end 