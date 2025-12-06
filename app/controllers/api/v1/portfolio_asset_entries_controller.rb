module Api
  module V1
    class PortfolioAssetEntriesController < BaseController
      before_action :set_portfolio
      before_action :set_portfolio_asset_entry, only: [:show, :update, :destroy]
      
      def index
        @portfolio_asset_entries = @portfolio.portfolio_asset_entries.includes(:asset)
        
        render json: @portfolio_asset_entries.map { |entry| 
          entry_json(entry)
        }
      end
      
      def show
        render json: entry_json(@portfolio_asset_entry)
      end
      
      def create
        @portfolio_asset_entry = @portfolio.portfolio_asset_entries.new(portfolio_asset_entry_params)
        
        if @portfolio_asset_entry.save
          render json: entry_json(@portfolio_asset_entry), status: :created
        else
          render json: { errors: @portfolio_asset_entry.errors }, status: :unprocessable_entity
        end
      end
      
      def update
        if @portfolio_asset_entry.update(portfolio_asset_entry_params)
          render json: entry_json(@portfolio_asset_entry)
        else
          render json: { errors: @portfolio_asset_entry.errors }, status: :unprocessable_entity
        end
      end
      
      def destroy
        @portfolio_asset_entry.destroy
        head :no_content
      end
      
      private
      
      def set_portfolio
        @portfolio = current_user.portfolios.find(params[:portfolio_id])
      end
      
      def set_portfolio_asset_entry
        @portfolio_asset_entry = @portfolio.portfolio_asset_entries.find(params[:id])
      end
      
      def portfolio_asset_entry_params
        params.require(:portfolio_asset_entry).permit(:asset_id, :shares, :purchase_price, :purchase_date)
      end
      
      def entry_json(entry)
        {
          id: entry.id,
          asset_id: entry.asset_id,
          asset_identifier: entry.asset.identifier,
          asset_name: entry.asset.name,
          asset_type: entry.asset.asset_type,
          shares: entry.shares,
          purchase_price: entry.purchase_price,
          purchase_date: entry.purchase_date,
          current_price: entry.current_price,
          current_value: entry.current_value,
          weight_in_portfolio: entry.weight_in_portfolio,
          created_at: entry.created_at,
          updated_at: entry.updated_at
        }
      end
    end
  end
end 