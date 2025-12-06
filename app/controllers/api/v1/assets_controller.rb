module Api
  module V1
    class AssetsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :overlapping]
      
      def index
        assets = Asset.all
        
        # Apply filters if provided
        assets = assets.by_type(params[:type]) if params[:type].present?
        assets = assets.by_country(params[:country]) if params[:country].present?
        assets = assets.by_industry(params[:industry]) if params[:industry].present?
        
        # Handle search query
        if params[:query].present?
          search_term = "%#{params[:query]}%"
          assets = assets.where("identifier ILIKE ? OR name ILIKE ?", search_term, search_term)
        end
        
        # Get total count
        total_count = assets.count
        
        # Apply limit and offset only if explicitly requested
        if params[:limit].present?
          limit = params[:limit].to_i
          offset = params[:offset].present? ? params[:offset].to_i : 0
          assets = assets.limit(limit).offset(offset)
        end
        
        render json: {
          assets: assets.as_json(except: [:created_at, :updated_at]),
          meta: {
            total_count: total_count,
            count: assets.size
          }
        }
      end
      
      def show
        asset = Asset.find(params[:id])
        
        # Get ETFs that hold this asset
        etf_weights = asset.etf_weights(params[:as_of_date])
        
        render json: {
          asset: asset.as_json(except: [:created_at, :updated_at]),
          etfs: etf_weights
        }
      end
      
      def overlapping
        min_etfs = params[:min_etfs].to_i || 2
        
        # Apply limit only if explicitly requested
        overlapping_assets = Asset.find_overlapping_assets(min_etfs)
        overlapping_assets = overlapping_assets.limit(params[:limit].to_i) if params[:limit].present?
        
        render json: {
          assets: overlapping_assets.map do |asset|
            asset.as_json(except: [:created_at, :updated_at])
                .merge(etf_count: asset.etf_count)
          end
        }
      end
    end
  end
end 