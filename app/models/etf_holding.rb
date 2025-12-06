class EtfHolding < ApplicationRecord
  belongs_to :etf
  belongs_to :asset
  
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :as_of_date, presence: true
  validates :asset_id, uniqueness: { scope: [:etf_id, :as_of_date] }
  
  scope :by_date, ->(date) { where(as_of_date: date) }
  scope :latest, -> { where(as_of_date: maximum(:as_of_date)) }
  
  # Delegate asset attributes to the associated asset
  delegate :identifier, :name, :asset_type, :industry, :country, to: :asset, prefix: :asset, allow_nil: true
  
  # For backward compatibility, provide methods that return the asset's attributes
  def asset_identifier
    asset&.identifier
  end
  
  def asset_name
    asset&.name
  end
  
  def asset_type
    asset&.asset_type
  end
  
  def industry
    asset&.industry
  end
  
  def country
    asset&.country
  end
  
  # Scopes that query through the asset association
  def self.by_type(type)
    joins(:asset).where(assets: { asset_type: type })
  end
  
  def self.by_country(country)
    joins(:asset).where(assets: { country: country })
  end
  
  def self.by_industry(industry)
    joins(:asset).where(assets: { industry: industry })
  end
end 