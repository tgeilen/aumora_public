module Api
  module V1
    class PortfoliosController < BaseController
      before_action :authenticate_user!
      before_action :set_portfolio, only: [:show, :update, :destroy, :holdings_breakdown, :etf_holdings_breakdown, :asset_holdings_breakdown, :total_holdings_exposure]

      def index
        portfolios = current_user.portfolios
                       .includes(portfolio_entries: :etf)
                       .includes(portfolio_asset_entries: :asset)
        
        render json: portfolios.map { |portfolio|
          portfolio.as_json(
            include: { 
              portfolio_entries: { 
                include: :etf,
                methods: [:current_price, :current_value]
              },
              portfolio_asset_entries: { 
                include: :asset,
                methods: [:current_price, :current_value]
              }
            }
          ).merge(
            'total_value' => portfolio.total_allocation,
            'last_etf_sync_at' => portfolio.last_etf_sync_at
          )
        }, status: :ok
      end

      def show
        render json: @portfolio.as_json(
          include: { 
            portfolio_entries: { 
              include: :etf,
              methods: [:current_price, :current_value]
            },
            portfolio_asset_entries: { 
              include: :asset,
              methods: [:current_price, :current_value]
            }
          }
        ).merge(
          'total_value' => @portfolio.total_allocation,
          'last_etf_sync_at' => @portfolio.last_etf_sync_at
        ), status: :ok
      end

      def create
        portfolio = current_user.portfolios.build(portfolio_params)
        if portfolio.save
          render json: portfolio.as_json(
            include: { 
              portfolio_entries: { 
                include: :etf,
                methods: [:current_price, :current_value]
              },
              portfolio_asset_entries: { 
                include: :asset,
                methods: [:current_price, :current_value]
              }
            }
          ).merge(
            'total_value' => portfolio.total_allocation,
            'last_etf_sync_at' => portfolio.last_etf_sync_at
          ), status: :created
        else
          render json: { errors: portfolio.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @portfolio.update(portfolio_params)
          render json: @portfolio.as_json(
            include: { 
              portfolio_entries: { 
                include: :etf,
                methods: [:current_price, :current_value]
              },
              portfolio_asset_entries: { 
                include: :asset,
                methods: [:current_price, :current_value]
              }
            }
          ).merge(
            'total_value' => @portfolio.total_allocation,
            'last_etf_sync_at' => @portfolio.last_etf_sync_at
          ), status: :ok
        else
          render json: { errors: portfolio.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @portfolio.destroy
        head :no_content
      end

      def holdings_breakdown
        breakdown = @portfolio.holdings_breakdown
        render json: {
          industries: breakdown[:industries],
          countries: breakdown[:countries],
          stocks: breakdown[:stocks]
        }, status: :ok
      end
      
      def etf_holdings_breakdown
        breakdown = @portfolio.etf_holdings_breakdown
        render json: {
          industries: breakdown[:industries],
          countries: breakdown[:countries],
          stocks: breakdown[:stocks]
        }, status: :ok
      end
      
      def asset_holdings_breakdown
        breakdown = @portfolio.asset_holdings_breakdown
        render json: {
          industries: breakdown[:industries],
          countries: breakdown[:countries],
          stocks: breakdown[:stocks]
        }, status: :ok
      end
      
      def total_holdings_exposure
        exposure_data = @portfolio.total_holdings_exposure
        render json: {
          securities: exposure_data[:securities],
          total_portfolio_value: exposure_data[:total_portfolio_value]
        }, status: :ok
      end

      private

      def set_portfolio
        @portfolio = current_user.portfolios
                      .includes(portfolio_entries: { etf: { holdings: :asset } })
                      .includes(portfolio_asset_entries: :asset)
                      .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Portfolio not found' }, status: :not_found
      end

      def portfolio_params
        params.require(:portfolio).permit(:name)
      end
    end
  end
end 