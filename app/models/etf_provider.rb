class EtfProvider < ApplicationRecord
  has_many :etfs, foreign_key: 'provider_id', dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :data_format, inclusion: { in: %w[csv xls xlsx], allow_nil: true }
 
  def formatted_parser_configuration
    parser_configuration || {}
  end
end 