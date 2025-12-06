class ScheduledEtfSyncJob < ApplicationJob
  queue_as :scheduled
  
  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  # Don't retry on specific errors that won't resolve with retries
  discard_on ActiveRecord::RecordNotFound
  discard_on Errno::ENOENT # File not found

  def perform
    Rails.logger.info("[ScheduledEtfSyncJob] Starting scheduled ETF sync")
    start_time = Time.current
    
    begin
      # Step 0: Update exchange rates first
      Rails.logger.info("[ScheduledEtfSyncJob] Ensuring exchange rates are up-to-date")
      exchange_rate_result = ExchangeRateService.ensure_updated_rates
      
      if exchange_rate_result[:success]
        if exchange_rate_result[:rates].nil?
          Rails.logger.info("[ScheduledEtfSyncJob] Exchange rates are already current")
        else
          Rails.logger.info("[ScheduledEtfSyncJob] Successfully updated exchange rates for #{exchange_rate_result[:rates].size} currencies")
        end
      else
        Rails.logger.warn("[ScheduledEtfSyncJob] Failed to update exchange rates: #{exchange_rate_result[:error]}")
        # Continue anyway since this shouldn't block ETF data fetching
      end
      
      # Step 1: Import ETFs from iShares-Germany.xls
      file_path = Rails.root.join('db', 'seed_data', 'iShares-Germany.xls')
      
      unless File.exist?(file_path)
        Rails.logger.error("[ScheduledEtfSyncJob] ETF list file not found at #{file_path}")
        raise Errno::ENOENT, "ETF list file not found at #{file_path}"
      end

      # Import ETFs from XLS file
      importer = EtfData::Importers::IsharesEtfImporter.new(file_path)
      etfs = importer.import
      
      Rails.logger.info("[ScheduledEtfSyncJob] Imported #{etfs.size} ETFs")

      # Step 2: Queue jobs to fetch holdings for each ETF with staggered execution
      etf_sync_job = EtfSyncJob.perform_later(etfs.pluck(:id), force_fetch: true)
      
      elapsed = Time.current - start_time
      Rails.logger.info("[ScheduledEtfSyncJob] ETF sync initiated successfully in #{elapsed.round(2)}s, job ID: #{etf_sync_job.job_id}")
      
      # Log success metrics
      Rails.logger.info("[ScheduledEtfSyncJob] Sync summary: #{etfs.size} ETFs queued for processing, exchange rates updated: #{exchange_rate_result[:success]}")
      
    rescue => e
      elapsed = Time.current - start_time
      Rails.logger.error("[ScheduledEtfSyncJob] ETF sync failed after #{elapsed.round(2)}s: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      # In production, you might want to send notifications here
      # notify_error(e) if Rails.env.production?
      
      raise # Re-raise to mark job as failed and trigger retries
    end
  end
  
  private
  
  # Uncomment and implement if you want error notifications
  # def notify_error(error)
  #   # Send to error tracking service (e.g., Sentry, Rollbar)
  #   # Or send email notification
  #   Rails.logger.error("[ScheduledEtfSyncJob] Sending error notification for: #{error.message}")
  # end
end 