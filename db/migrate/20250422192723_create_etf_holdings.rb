class CreateEtfHoldings < ActiveRecord::Migration[8.0]
  def change
    create_table :etf_holdings do |t|
      t.references :etf, null: false, foreign_key: true
      t.string :asset_identifier, null: false
      t.string :asset_name, null: false
      t.string :asset_type
      t.decimal :weight, precision: 10, scale: 6, null: false
      t.string :industry
      t.string :country
      t.date :as_of_date, null: false

      t.timestamps
    end
    
    add_index :etf_holdings, :asset_identifier
    add_index :etf_holdings, [:etf_id, :asset_identifier, :as_of_date], unique: true, name: 'index_etf_holdings_on_etf_asset_date'
  end
end
