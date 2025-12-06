class CreateExchangeRates < ActiveRecord::Migration[8.0]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, null: false
      t.decimal :rate_to_usd, precision: 15, scale: 6, null: false
      t.datetime :as_of_date, null: false
      
      t.timestamps
    end
    
    add_index :exchange_rates, :currency
    add_index :exchange_rates, [:currency, :as_of_date], unique: true
  end
end 