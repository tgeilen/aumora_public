# This is a placeholder for the API ETFs controller
# If this file doesn't exist in your system, you'll need to create it

module Api
  module V1
    class EtfsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :holdings]
      
      def index
        # Use includes to eager load providers and avoid N+1 queries
        etfs = Etf.includes(:provider).all
        
        # Filter by provider if specified
        if params[:provider_id].present?
          etfs = etfs.where(provider_id: params[:provider_id])
        end
        
        # Handle search query
        if params[:query].present?
          search_term = "%#{params[:query]}%"
          etfs = etfs.where("ticker ILIKE ? OR name ILIKE ?", search_term, search_term)
        end
        
        # Sort by ticker by default
        etfs = etfs.where.not(last_updated_at: nil).order(:ticker)
        
        # Return etfs as an array directly (not nested in an object)
        render json: etfs.as_json(except: [:created_at, :updated_at], 
                                 include: { provider: { only: [:id, :name] } })
      end
      
      def show
        etf = Etf.find(params[:id])
        
        render json: {
          etf: etf.as_json(except: [:created_at, :updated_at], 
                           include: { provider: { only: [:id, :name] } }),
          metadata: etf.formatted_metadata,
          last_updated_at: etf.last_updated_at
        }
      end
      
      def holdings
        etf = Etf.find(params[:id])
        
        # Determine which date to use
        if params[:date].present?
          date = Date.parse(params[:date])
          holdings = etf.holdings.by_date(date)
        else
          # Use the most recent date by default
          latest_date = etf.holdings.maximum(:as_of_date)
          holdings = latest_date ? etf.holdings.by_date(latest_date) : []
          date = latest_date
        end
        
        # Apply filters if provided
        if params[:type].present?
          holdings = holdings.by_type(params[:type])
        end
        
        if params[:country].present?
          holdings = holdings.by_country(params[:country])
        end
        
        if params[:industry].present?
          holdings = holdings.by_industry(params[:industry])
        end
        
        # Include asset information
        holdings = holdings.includes(:asset)
        
        render json: {
          holdings: holdings.map { |holding| 
            {
              id: holding.id,
              asset_id: holding.asset_id,
              asset_identifier: holding.asset_identifier,
              asset_name: holding.asset_name,
              asset_type: holding.asset_type,
              weight: holding.weight,
              industry: holding.industry,
              country: holding.country,
              as_of_date: holding.as_of_date
            }
          },
          meta: {
            total_count: holdings.count,
            as_of_date: date
          }
        }
      end
    end
  end
end 