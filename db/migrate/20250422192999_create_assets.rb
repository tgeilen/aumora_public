class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :asset_type
      t.string :industry
      t.string :country
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :assets, :identifier, unique: true
    add_index :assets, :name
    add_index :assets, :asset_type
    add_index :assets, :industry
    add_index :assets, :country
  end
end 