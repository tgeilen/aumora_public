class CreateEtfs < ActiveRecord::Migration[8.0]
  def change
    create_table :etfs do |t|
      t.string :ticker, null: false
      t.string :name, null: false
      t.references :provider, null: false, foreign_key: { to_table: :etf_providers }
      t.string :specific_url
      t.datetime :last_updated_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :etfs, :ticker
    add_index :etfs, [:ticker, :provider_id], unique: true
  end
end
