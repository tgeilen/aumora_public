class AddNormalizedPriceToAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :price_usd, :decimal, precision: 15, scale: 6
    add_column :assets, :price_usd_as_of_date, :datetime
  end
end 