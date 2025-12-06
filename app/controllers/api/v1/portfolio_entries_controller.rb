module Api
  module V1
    class PortfolioEntriesController < BaseController
      before_action :authenticate_user!
      before_action :set_portfolio
      before_action :set_entry, only: [:show, :update, :destroy]

      def index
        entries = @portfolio.portfolio_entries.includes(:etf)
        render json: entries, include: :etf, status: :ok
      end

      def show
        render json: @entry, include: :etf, status: :ok
      end

      def create
        entry = @portfolio.portfolio_entries.build(entry_params)

        if entry.save
          render json: entry, include: :etf, status: :created
        else
          render json: { errors: entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @entry.update(entry_params)
          render json: @entry, include: :etf, status: :ok
        else
          render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @entry.destroy
        head :no_content
      end

      private

      def set_portfolio
        @portfolio = current_user.portfolios.find(params[:portfolio_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Portfolio not found' }, status: :not_found
      end

      def set_entry
        @entry = @portfolio.portfolio_entries.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Entry not found' }, status: :not_found
      end

      def entry_params
        params.require(:entry).permit(:etf_id, :shares, :purchase_price, :purchase_date)
      end
    end
  end
end 