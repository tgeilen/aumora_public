class CreatePortfolioAssetEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_asset_entries do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.decimal :shares, precision: 15, scale: 6, null: false
      t.decimal :purchase_price, precision: 15, scale: 6
      t.date :purchase_date

      t.timestamps
    end
    
    # Add a unique constraint to prevent duplicate entries
    add_index :portfolio_asset_entries, [:portfolio_id, :asset_id], unique: true
  end
end 