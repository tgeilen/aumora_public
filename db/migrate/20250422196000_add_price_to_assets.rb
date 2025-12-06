class AddPriceToAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :price, :decimal, precision: 15, scale: 6
    add_column :assets, :price_currency, :string
    add_column :assets, :price_as_of_date, :datetime
  end
end 