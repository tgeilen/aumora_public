class NormalizeEtfHoldingsTable < ActiveRecord::Migration[8.0]
  def up
    # First ensure all holdings have asset_id populated
    execute <<-SQL
      UPDATE etf_holdings
      SET asset_id = assets.id
      FROM assets
      WHERE etf_holdings.asset_identifier = assets.identifier AND etf_holdings.asset_id IS NULL;
    SQL
    
    # Check if any holdings still have null asset_id
    missing_assets_count = execute("SELECT COUNT(*) FROM etf_holdings WHERE asset_id IS NULL").first["count"].to_i
    
    if missing_assets_count > 0
      # This should not happen if the data migration task was run properly
      raise "Error: #{missing_assets_count} ETF holdings do not have an associated asset. Run 'rails data_migration:populate_assets' first."
    end
    
    # Make asset_id non-nullable now that all rows have it populated
    change_column_null :etf_holdings, :asset_id, false
    
    # Remove the now-redundant columns one by one (easier to rollback if needed)
    remove_column :etf_holdings, :asset_identifier if column_exists?(:etf_holdings, :asset_identifier)
    remove_column :etf_holdings, :asset_name if column_exists?(:etf_holdings, :asset_name)
    remove_column :etf_holdings, :asset_type if column_exists?(:etf_holdings, :asset_type)
    remove_column :etf_holdings, :industry if column_exists?(:etf_holdings, :industry)
    remove_column :etf_holdings, :country if column_exists?(:etf_holdings, :country)
    
    # Update the uniqueness index now that asset_identifier is gone
    # Skip adding the index if it already exists
    unless index_exists?(:etf_holdings, [:etf_id, :asset_id, :as_of_date], name: "index_etf_holdings_on_etf_asset_id_date")
      if index_exists?(:etf_holdings, "index_etf_holdings_on_etf_asset_id_date")
        remove_index :etf_holdings, name: "index_etf_holdings_on_etf_asset_id_date"
      end
      add_index :etf_holdings, [:etf_id, :asset_id, :as_of_date], unique: true, name: "index_etf_holdings_on_etf_asset_id_date"
    end
  end
  
  def down
    # Add back the removed columns if they don't exist
    add_column :etf_holdings, :asset_identifier, :string unless column_exists?(:etf_holdings, :asset_identifier)
    add_column :etf_holdings, :asset_name, :string unless column_exists?(:etf_holdings, :asset_name)
    add_column :etf_holdings, :asset_type, :string unless column_exists?(:etf_holdings, :asset_type)
    add_column :etf_holdings, :industry, :string unless column_exists?(:etf_holdings, :industry)
    add_column :etf_holdings, :country, :string unless column_exists?(:etf_holdings, :country)
    
    # Populate the columns from the associated asset
    execute <<-SQL
      UPDATE etf_holdings
      SET 
        asset_identifier = assets.identifier,
        asset_name = assets.name,
        asset_type = assets.asset_type,
        industry = assets.industry,
        country = assets.country
      FROM assets
      WHERE etf_holdings.asset_id = assets.id;
    SQL
    
    # Make the key columns non-nullable again
    change_column_null :etf_holdings, :asset_identifier, false
    change_column_null :etf_holdings, :asset_name, false
    
    # Make asset_id nullable again
    change_column_null :etf_holdings, :asset_id, true
  end
end 