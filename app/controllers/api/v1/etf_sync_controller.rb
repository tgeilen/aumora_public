module Api
  module V1
    class EtfSyncController < BaseController
      include ExchangeRateUpdater
      
      skip_before_action :authenticate_user!
      before_action :ensure_exchange_rates_updated, only: [:sync]
      
      def sync
        # Step 1: Import ETFs from iShares-Germany.xls
        file_path = Rails.root.join('db', 'seed_data', 'iShares-Germany.xls')
        
        unless File.exist?(file_path)
          render json: { error: "ETF list file not found" }, status: :not_found
          return
        end
        
        begin
          # Import ETFs from XLS file
          importer = EtfData::Importers::IsharesEtfImporter.new(file_path)
          etfs = importer.import
          
          # Step 2: Queue jobs to fetch holdings for each ETF with staggered execution
          etf_sync_job = EtfSyncJob.perform_later(etfs.pluck(:id), force_fetch: true)
          
          render json: {
            message: "ETF sync initiated",
            etfs_imported: etfs.size,
            job_id: etf_sync_job.job_id,
            exchange_rates_updated: true
          }, status: :ok
        rescue => e
          Rails.logger.error("ETF sync failed: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render json: { error: "ETF sync failed: #{e.message}" }, status: :internal_server_error
        end
      end
    end
  end
end 