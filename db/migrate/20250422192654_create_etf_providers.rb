class CreateEtfProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :etf_providers do |t|
      t.string :name, null: false
      t.string :base_url
      t.string :data_format
      t.string :url_pattern
      t.jsonb :parser_configuration, default: {}

      t.timestamps
    end
    
    add_index :etf_providers, :name, unique: true
  end
end
