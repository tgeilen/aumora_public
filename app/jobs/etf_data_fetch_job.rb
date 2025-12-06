class EtfDataFetchJob < ApplicationJob
  queue_as :etf_data
  
  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  # Special handling for rate limit errors - retry with longer delay
  retry_on "HTTP 429 Too Many Requests", wait: 120.seconds, attempts: 5
  
  # Log job execution
  around_perform do |job, block|
    etf_id = job.arguments.first
    start_time = Time.current
    
    if etf_id
      etf = Etf.find_by(id: etf_id)
      if etf
        Rails.logger.info("[EtfDataFetchJob] Starting ETF data fetch for #{etf.ticker} (ID: #{etf_id})")
      else
        Rails.logger.warn("[EtfDataFetchJob] ETF with ID #{etf_id} not found")
      end
    else
      Rails.logger.info("[EtfDataFetchJob] Starting ETF data fetch for all ETFs needing updates")
    end
    
    block.call
    
    elapsed = Time.current - start_time
    Rails.logger.info("[EtfDataFetchJob] Completed in #{elapsed.round(2)} seconds")
  rescue Sidekiq::Shutdown => e
    Rails.logger.info("[EtfDataFetchJob] Job interrupted by shutdown signal")
    raise e
  end

  def perform(etf_id = nil, options = {})
    if etf_id
      # Fetch a specific ETF
      etf = Etf.find_by(id: etf_id)
      if etf
        fetch_etf_data(etf, options)
      else
        Rails.logger.error("[EtfDataFetchJob] Failed to fetch ETF with ID #{etf_id}: ETF not found")
      end
    else
      # Fetch all ETFs that need updating
      etfs_to_update = Etf.where('last_updated_at IS NULL OR last_updated_at < ?', 1.day.ago)
      total_count = etfs_to_update.count
      
      Rails.logger.info("[EtfDataFetchJob] Found #{total_count} ETFs requiring updates")
      
      success_count = 0
      error_count = 0
      
      # Process in a staggered manner to avoid rate limits
      etfs_to_update.find_each.with_index do |etf, index|
        Rails.logger.info("[EtfDataFetchJob] Processing ETF #{index+1}/#{total_count}: #{etf.ticker} (ID: #{etf.id})")
        
        begin
          # Add a small delay between processing each ETF to avoid rate limits
          # Use interruptible sleep to handle shutdown signals gracefully
          if index > 0 && index % 3 == 0
            interruptible_sleep(2)
          end
          
          result = fetch_etf_data(etf, options)
          if result
            success_count += 1
          else
            error_count += 1
          end
        rescue Sidekiq::Shutdown => e
          Rails.logger.info("[EtfDataFetchJob] Job interrupted by shutdown signal during bulk processing")
          raise e
        rescue => e
          error_count += 1
          Rails.logger.error("[EtfDataFetchJob] Error processing ETF #{etf.ticker} (ID: #{etf.id}): #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end
      
      Rails.logger.info("[EtfDataFetchJob] ETF update summary: #{success_count} succeeded, #{error_count} failed, #{total_count} total")
    end
  end
  
  # Method to directly process a CSV/XLS file for a specific ETF
  def process_holdings_file(ticker, file_path, provider_name = 'iShares')
    Rails.logger.info("[EtfDataFetchJob] Processing holdings file for ETF #{ticker} from #{file_path}")
    
    provider = EtfProvider.find_by(name: provider_name)
    
    unless provider
      Rails.logger.error("[EtfDataFetchJob] Provider #{provider_name} not found")
      return false
    end
    
    # Get the correct fetcher class, handling case sensitivity
    fetcher_class_name = "EtfData::Fetchers::#{provider.name.capitalize}Fetcher"
    
    # Handle special case for iShares
    fetcher_class_name = "EtfData::Fetchers::IsharesFetcher" if provider.name.downcase == 'ishares'
    
    begin
      fetcher_class = fetcher_class_name.constantize
      fetcher = fetcher_class.new(provider)
      
      Rails.logger.info("[EtfDataFetchJob] Using fetcher class: #{fetcher_class_name}")
      
      holdings_data = fetcher.process_holdings_file(ticker, file_path)
      
      if holdings_data.present?
        Rails.logger.info("[EtfDataFetchJob] Successfully processed holdings file for ETF #{ticker}: #{holdings_data.size} holdings imported")
        return true
      else
        Rails.logger.error("[EtfDataFetchJob] Failed to process holdings file for ETF #{ticker}: No holdings data returned")
        return false
      end
    rescue NameError => e
      Rails.logger.error("[EtfDataFetchJob] Fetcher class not found: #{fetcher_class_name}")
      Rails.logger.error(e.message)
      return false
    rescue => e
      Rails.logger.error("[EtfDataFetchJob] Unexpected error processing holdings file: #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    end
  end

  private

  # Interruptible sleep that respects shutdown signals
  def interruptible_sleep(duration)
    end_time = Time.current + duration
    while Time.current < end_time
      # Sleep in small chunks to allow for interruption
      remaining = end_time - Time.current
      sleep_duration = [remaining, 0.5].min
      sleep(sleep_duration) if sleep_duration > 0
    end
  end

  def fetch_etf_data(etf, options = {})
    provider = etf.provider
    
    # Skip if no provider
    unless provider
      Rails.logger.error("[EtfDataFetchJob] Cannot fetch data for ETF #{etf.ticker} (ID: #{etf.id}): No provider associated")
      return false
    end
    
    # Add a small random delay to further spread out requests
    unless options[:skip_delay]
      delay = rand(1..3)  # Reduced from 2-5 seconds
      Rails.logger.info("[EtfDataFetchJob] Adding random delay of #{delay}s before processing ETF #{etf.ticker} (ID: #{etf.id})")
      interruptible_sleep(delay)
    end
    
    # Determine the correct fetcher class based on provider, handling case sensitivity
    fetcher_class_name = "EtfData::Fetchers::#{provider.name.capitalize}Fetcher"
    
    # Handle special case for iShares
    fetcher_class_name = "EtfData::Fetchers::IsharesFetcher" if provider.name.downcase == 'ishares'
    
    begin
      fetcher_class = fetcher_class_name.constantize
      fetcher = fetcher_class.new(provider)
      
      Rails.logger.info("[EtfDataFetchJob] Using fetcher class: #{fetcher_class_name} for ETF #{etf.ticker} (ID: #{etf.id})")
      
      # Find ETF URL if not already set
      if etf.specific_url.blank?
        Rails.logger.info("[EtfDataFetchJob] Looking up specific URL for ETF #{etf.ticker} (ID: #{etf.id})")
        specific_url = fetcher.find_etf_url(etf)
        
        # Handle rate limiting case
        if !specific_url && fetcher.respond_to?(:rate_limited?) && fetcher.rate_limited?
          Rails.logger.warn("[EtfDataFetchJob] Rate limited while looking up URL for ETF #{etf.ticker} (ID: #{etf.id})")
          raise "HTTP 429 Too Many Requests" if options[:fail_on_rate_limit]
          return false
        end
        
        # Skip if we couldn't find the URL and force_fetch is not set
        if !specific_url && !options[:force_fetch]
          Rails.logger.error("[EtfDataFetchJob] Failed to find URL for ETF #{etf.ticker} (ID: #{etf.id}) and force_fetch is not enabled")
          return false
        end
      end
      
      # Fetch ETF holdings
      Rails.logger.info("[EtfDataFetchJob] Fetching holdings for ETF #{etf.ticker} (ID: #{etf.id})")
      holdings_data = fetcher.fetch_etf_holdings(etf)
      
      # Handle rate limiting case
      if !holdings_data && fetcher.respond_to?(:rate_limited?) && fetcher.rate_limited?
        Rails.logger.warn("[EtfDataFetchJob] Rate limited while fetching holdings for ETF #{etf.ticker} (ID: #{etf.id})")
        raise "HTTP 429 Too Many Requests" if options[:fail_on_rate_limit]
        return false
      end
      
      # Log result
      if holdings_data.present?
        Rails.logger.info("[EtfDataFetchJob] Successfully fetched #{holdings_data.size} holdings for ETF #{etf.ticker} (ID: #{etf.id})")
        etf.update_column(:last_updated_at, Time.current)
        return true
      else
        Rails.logger.error("[EtfDataFetchJob] Failed to fetch holdings for ETF #{etf.ticker} (ID: #{etf.id})")
        return false
      end
    rescue NameError => e
      Rails.logger.error("[EtfDataFetchJob] Fetcher class not found: #{fetcher_class_name}")
      Rails.logger.error(e.message)
      return false
    rescue => e
      Rails.logger.error("[EtfDataFetchJob] Error fetching data for ETF #{etf.ticker} (ID: #{etf.id}): #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    end
  end
end 