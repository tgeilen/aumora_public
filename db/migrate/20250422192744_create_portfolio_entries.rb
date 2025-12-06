class CreatePortfolioEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_entries do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :etf, null: false, foreign_key: true
      t.decimal :shares, precision: 15, scale: 6, null: false
      t.decimal :purchase_price, precision: 15, scale: 6
      t.date :purchase_date

      t.timestamps
    end
    
    add_index :portfolio_entries, [:portfolio_id, :etf_id], unique: true
  end
end
