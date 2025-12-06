class EtfSyncJob < ApplicationJob
  queue_as :etf_sync
  
  # Configuration for job throttling
  STAGGER_INTERVAL = ENV.fetch('ETF_SYNC_STAGGER_INTERVAL', '10').to_i  # Seconds between ETF jobs (reduced from 30)
  BATCH_SIZE = ENV.fetch('ETF_SYNC_BATCH_SIZE', '2').to_i              # Number of jobs to launch at once (increased from 10)
  BATCH_INTERVAL = ENV.fetch('ETF_SYNC_BATCH_INTERVAL', '10').to_i     # Seconds between batches (reduced from 20)
  
  # Log job execution
  around_perform do |job, block|
    etf_ids = job.arguments.first
    options = job.arguments.second || {}
    
    if etf_ids.is_a?(Array)
      count = etf_ids.size
      Rails.logger.info("[EtfSyncJob] Starting ETF sync for #{count} ETFs with options: #{options}")
    else
      Rails.logger.info("[EtfSyncJob] Starting ETF sync with unknown ETF count with options: #{options}")
    end
    
    start_time = Time.current
    block.call
    
    elapsed = Time.current - start_time
    Rails.logger.info("[EtfSyncJob] ETF sync job completed in #{elapsed.round(2)} seconds")
  rescue Sidekiq::Shutdown => e
    Rails.logger.info("[EtfSyncJob] Job interrupted by shutdown signal, jobs may have been partially scheduled")
    raise e
  end

  def perform(etf_ids, options = {})
    # Safety check
    unless etf_ids.is_a?(Array)
      Rails.logger.error("[EtfSyncJob] Expected an array of ETF IDs, got: #{etf_ids.class.name}")
      return
    end
    
    # Skip empty array
    if etf_ids.empty?
      Rails.logger.info("[EtfSyncJob] No ETF IDs to process")
      return
    end
    
    Rails.logger.info("[EtfSyncJob] Processing #{etf_ids.size} ETFs with throttling" + 
                     " (batch size: #{BATCH_SIZE}, stagger interval: #{STAGGER_INTERVAL}s, batch interval: #{BATCH_INTERVAL}s)")
    
    # Process ETFs in batches - schedule all batches upfront instead of sleeping
    etf_ids.each_slice(BATCH_SIZE).with_index do |batch_ids, batch_index|
      # Calculate the base delay for this batch
      batch_delay = batch_index * BATCH_INTERVAL
      
      Rails.logger.info("[EtfSyncJob] Scheduling batch #{batch_index+1} with #{batch_ids.size} ETFs" + 
                       (batch_delay > 0 ? " with #{batch_delay}s batch delay" : " immediately"))
      
      # Queue each ETF in the batch with a staggered delay
      batch_ids.each_with_index do |etf_id, index|
        # Combine batch delay with stagger delay within the batch
        total_delay = batch_delay + (index * STAGGER_INTERVAL)
        
        if total_delay > 0
          Rails.logger.info("[EtfSyncJob] Scheduling ETF #{etf_id} with a #{total_delay} second delay")
          EtfDataFetchJob.set(wait: total_delay.seconds).perform_later(etf_id, options)
        else
          Rails.logger.info("[EtfSyncJob] Scheduling ETF #{etf_id} immediately")
          EtfDataFetchJob.perform_later(etf_id, options)
        end
      end
    end
    
    Rails.logger.info("[EtfSyncJob] All ETF data fetch jobs have been scheduled")
  end
end 