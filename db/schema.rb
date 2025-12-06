# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_24_182429) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "name", null: false
    t.string "asset_type"
    t.string "industry"
    t.string "country"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 15, scale: 6
    t.string "price_currency"
    t.datetime "price_as_of_date"
    t.decimal "price_usd", precision: 15, scale: 6
    t.datetime "price_usd_as_of_date"
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["country"], name: "index_assets_on_country"
    t.index ["identifier"], name: "index_assets_on_identifier", unique: true
    t.index ["industry"], name: "index_assets_on_industry"
    t.index ["name"], name: "index_assets_on_name"
  end

  create_table "etf_holdings", force: :cascade do |t|
    t.bigint "etf_id", null: false
    t.decimal "weight", precision: 10, scale: 6, null: false
    t.date "as_of_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "asset_id", null: false
    t.index ["asset_id"], name: "index_etf_holdings_on_asset_id"
    t.index ["etf_id", "asset_id", "as_of_date"], name: "index_etf_holdings_on_etf_asset_id_date", unique: true
    t.index ["etf_id"], name: "index_etf_holdings_on_etf_id"
  end

  create_table "etf_providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "base_url"
    t.string "data_format"
    t.string "url_pattern"
    t.jsonb "parser_configuration", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_etf_providers_on_name", unique: true
  end

  create_table "etfs", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "name", null: false
    t.bigint "provider_id", null: false
    t.string "specific_url"
    t.datetime "last_updated_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "current_price", precision: 15, scale: 6
    t.string "currency"
    t.index ["provider_id"], name: "index_etfs_on_provider_id"
    t.index ["ticker", "provider_id"], name: "index_etfs_on_ticker_and_provider_id", unique: true
    t.index ["ticker"], name: "index_etfs_on_ticker"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency", null: false
    t.decimal "rate_to_usd", precision: 15, scale: 6, null: false
    t.datetime "as_of_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency", "as_of_date"], name: "index_exchange_rates_on_currency_and_as_of_date", unique: true
    t.index ["currency"], name: "index_exchange_rates_on_currency"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "portfolio_asset_entries", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "asset_id", null: false
    t.decimal "shares", precision: 15, scale: 6, null: false
    t.decimal "purchase_price", precision: 15, scale: 6
    t.date "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_portfolio_asset_entries_on_asset_id"
    t.index ["portfolio_id", "asset_id"], name: "index_portfolio_asset_entries_on_portfolio_id_and_asset_id", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_asset_entries_on_portfolio_id"
  end

  create_table "portfolio_entries", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "etf_id", null: false
    t.decimal "shares", precision: 15, scale: 6, null: false
    t.decimal "purchase_price", precision: 15, scale: 6
    t.date "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["etf_id"], name: "index_portfolio_entries_on_etf_id"
    t.index ["portfolio_id", "etf_id"], name: "index_portfolio_entries_on_portfolio_id_and_etf_id", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_entries_on_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_portfolios_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "etf_holdings", "assets"
  add_foreign_key "etf_holdings", "etfs"
  add_foreign_key "etfs", "etf_providers", column: "provider_id"
  add_foreign_key "portfolio_asset_entries", "assets"
  add_foreign_key "portfolio_asset_entries", "portfolios"
  add_foreign_key "portfolio_entries", "etfs"
  add_foreign_key "portfolio_entries", "portfolios"
  add_foreign_key "portfolios", "users"
end
