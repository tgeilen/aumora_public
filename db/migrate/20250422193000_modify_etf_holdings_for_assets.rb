class ModifyEtfHoldingsForAssets < ActiveRecord::Migration[8.0]
  def change
    # Add asset_id column to etf_holdings
    add_column :etf_holdings, :asset_id, :bigint
    
    # Create index for the new column
    add_index :etf_holdings, :asset_id
    
    # Add foreign key constraint
    add_foreign_key :etf_holdings, :assets
    
    # Remove the uniqueness constraint that would conflict with the new structure
    remove_index :etf_holdings, name: "index_etf_holdings_on_etf_asset_date"
    
    # Add a new constraint that includes asset_id
    add_index :etf_holdings, [:etf_id, :asset_id, :as_of_date], unique: true, name: "index_etf_holdings_on_etf_asset_id_date"
  end
end 