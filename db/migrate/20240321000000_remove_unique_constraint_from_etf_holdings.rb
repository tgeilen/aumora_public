class RemoveUniqueConstraintFromEtfHoldings < ActiveRecord::Migration[7.0]
  def change
    # Remove the existing unique index
    remove_index :etf_holdings, name: "index_etf_holdings_on_etf_asset_date"
    
    # Add back a non-unique index for query performance
    add_index :etf_holdings, [:etf_id, :asset_identifier, :as_of_date], 
              name: "index_etf_holdings_on_etf_asset_date"
  end
end 