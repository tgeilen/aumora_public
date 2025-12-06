class PortfolioAssetEntry < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  
  validates :shares, presence: true, numericality: { greater_than: 0 }
  validates :asset_id, uniqueness: { scope: :portfolio_id }
  
  # Get the current price for this asset entry
  def current_price
    # Try to use the asset's current USD price first, then purchase price, then default to 1.0
    asset.current_usd_price || purchase_price || 1.0
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