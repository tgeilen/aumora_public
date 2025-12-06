class AddCurrentPriceToEtfs < ActiveRecord::Migration[8.0]
  def change
    add_column :etfs, :current_price, :decimal, precision: 15, scale: 6
    add_column :etfs, :currency, :string
  end
end 