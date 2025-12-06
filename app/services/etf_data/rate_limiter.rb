module EtfData
  class RateLimiter
    # Default rate limits (can be overridden with env vars)
    DEFAULT_MAX_REQUESTS = 30       # Maximum requests allowed in the time window (increased from 20)
    DEFAULT_TIME_WINDOW = 90        # Time window in seconds (1.5 minutes - decreased from 120)
    DEFAULT_COOLDOWN_PERIOD = 180   # Cooldown period after hitting a rate limit (3 minutes - decreased from 300)
    
    class << self
      # Get a singleton instance
      def instance
        @instance ||= new
      end
      
      # Convenience method to perform with rate limiting
      def with_rate_limiting(provider_name = 'justetf', &block)
        instance.with_rate_limiting(provider_name, &block)
      end
    end
    
    def initialize
      @mutex = Mutex.new
      @request_timestamps = {}
      @cooldown_until = {}
    end
    
    # Execute a block with rate limiting
    # Returns [success, result_or_error]
    def with_rate_limiting(provider_name = 'justetf', &block)
      provider_name = provider_name.to_s.downcase
      
      # Check if we can make a request
      unless can_make_request?(provider_name)
        delay = next_available_slot(provider_name)
        Rails.logger.info("Rate limiting #{provider_name} request. Next available in #{delay.round(1)} seconds")
        
        # If configured to wait, sleep until the next slot is available
        if wait_on_rate_limit?
          interruptible_sleep(delay) if delay > 0
        else
          return [false, "Rate limit exceeded for #{provider_name}. Try again in #{delay.round(1)} seconds"]
        end
      end
      
      # Record this request
      record_request(provider_name)
      
      # Execute the provided block
      begin
        result = block.call
        return [true, result]
      rescue => e
        # If we get a rate limit error, mark the provider as in cooldown
        if e.respond_to?(:response) && e.response && e.response.code.to_i == 429
          start_cooldown(provider_name)
        end
        return [false, e]
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
    
    # Record a request timestamp for a provider
    def record_request(provider_name)
      @mutex.synchronize do
        @request_timestamps[provider_name] ||= []
        @request_timestamps[provider_name] << Time.now.to_f
        # Prune old timestamps outside the window
        current_time = Time.now.to_f
        @request_timestamps[provider_name].reject! { |ts| current_time - ts > time_window(provider_name) }
      end
    end
    
    # Start a cooldown period for a provider after hitting a rate limit
    def start_cooldown(provider_name)
      @mutex.synchronize do
        @cooldown_until[provider_name] = Time.now.to_f + cooldown_period(provider_name)
        Rails.logger.warn("Rate limit hit for #{provider_name}. Starting cooldown for #{cooldown_period(provider_name)} seconds")
      end
    end
    
    # Check if we can make a request for a provider
    def can_make_request?(provider_name)
      @mutex.synchronize do
        # If in cooldown, check if it's over
        if @cooldown_until[provider_name] && Time.now.to_f < @cooldown_until[provider_name]
          return false
        end
        
        # Otherwise, check the number of recent requests
        @request_timestamps[provider_name] ||= []
        current_time = Time.now.to_f
        recent_requests = @request_timestamps[provider_name].count { |ts| current_time - ts < time_window(provider_name) }
        
        return recent_requests < max_requests(provider_name)
      end
    end
    
    # Calculate the time until the next available request slot
    def next_available_slot(provider_name)
      @mutex.synchronize do
        # If in cooldown, return time until cooldown is over
        if @cooldown_until[provider_name] && Time.now.to_f < @cooldown_until[provider_name]
          return @cooldown_until[provider_name] - Time.now.to_f
        end
        
        # Otherwise calculate based on request history
        @request_timestamps[provider_name] ||= []
        return 0 if @request_timestamps[provider_name].empty?
        
        current_time = Time.now.to_f
        # Sort and take the oldest timestamps that will expire from our window
        sorted_timestamps = @request_timestamps[provider_name].sort
        
        if sorted_timestamps.size < max_requests(provider_name)
          return 0  # We have room for more requests
        else
          # Calculate when the oldest request will expire from the window
          oldest_relevant = sorted_timestamps[-(max_requests(provider_name))]
          return (oldest_relevant + time_window(provider_name)) - current_time
        end
      end
    end
    
    # Maximum requests allowed in the time window
    def max_requests(provider_name = 'justetf')
      provider_name = provider_name.to_s.downcase
      @max_requests ||= {}.tap do |limits|
        limits['justetf'] = ENV.fetch('JUSTETF_MAX_REQUESTS', DEFAULT_MAX_REQUESTS).to_i
        limits['ishares'] = ENV.fetch('ISHARES_MAX_REQUESTS', DEFAULT_MAX_REQUESTS).to_i
        # Add more providers as needed
      end
      
      @max_requests[provider_name] || DEFAULT_MAX_REQUESTS
    end
    
    # Time window in seconds
    def time_window(provider_name = 'justetf')
      provider_name = provider_name.to_s.downcase
      @time_window ||= {}.tap do |windows|
        windows['justetf'] = ENV.fetch('JUSTETF_TIME_WINDOW', DEFAULT_TIME_WINDOW).to_i
        windows['ishares'] = ENV.fetch('ISHARES_TIME_WINDOW', DEFAULT_TIME_WINDOW).to_i
        # Add more providers as needed
      end
      
      @time_window[provider_name] || DEFAULT_TIME_WINDOW
    end
    
    # Cooldown period in seconds after hitting a rate limit
    def cooldown_period(provider_name = 'justetf')
      provider_name = provider_name.to_s.downcase
      @cooldown_period ||= {}.tap do |periods|
        periods['justetf'] = ENV.fetch('JUSTETF_COOLDOWN_PERIOD', DEFAULT_COOLDOWN_PERIOD).to_i
        periods['ishares'] = ENV.fetch('ISHARES_COOLDOWN_PERIOD', DEFAULT_COOLDOWN_PERIOD).to_i
        # Add more providers as needed
      end
      
      @cooldown_period[provider_name] || DEFAULT_COOLDOWN_PERIOD
    end
    
    # Whether to wait/sleep when rate limited or return immediately
    def wait_on_rate_limit?
      @wait_on_rate_limit ||= ENV.fetch('JUSTETF_WAIT_ON_RATE_LIMIT', 'false') == 'true'
    end
  end
end 