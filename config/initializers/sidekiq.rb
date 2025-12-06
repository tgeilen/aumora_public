require 'sidekiq'

# Only require sidekiq-cron if we're not precompiling assets
begin
  require 'sidekiq-cron' unless defined?(Rails) && Rails.env.development? && ENV['RAILS_ENV'] != 'production'
rescue LoadError
  Rails.logger.warn("sidekiq-cron not available") if defined?(Rails)
end

# Heroku Redis configuration
redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')

# Configure Redis connection options for Heroku
redis_options = { url: redis_url }

# Handle Heroku Redis SSL issues
if redis_url.start_with?('rediss://')
  redis_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
end

Sidekiq.configure_server do |config|
  config.redis = redis_options.merge(
    # Heroku Redis connection pool settings
    size: ENV.fetch('RAILS_MAX_THREADS', 5).to_i + 5
  )
  
  # Configure queues to process
  # Priority order: scheduled jobs first, then ETF sync, then individual ETF data, then default
  config.queues = %w[scheduled etf_sync etf_data default]
end

Sidekiq.configure_client do |config|
  config.redis = redis_options.merge(
    # Smaller connection pool for client
    size: ENV.fetch('RAILS_MAX_THREADS', 5).to_i
  )
end

# Load cron jobs after Rails and Sidekiq are fully initialized
Rails.application.config.after_initialize do
  if defined?(Sidekiq::Cron) && Sidekiq.server?
    schedule_file = Rails.root.join('config', 'schedule.yml')
    if File.exist?(schedule_file)
      Rails.logger.info("Loading Sidekiq cron jobs from #{schedule_file}")
      begin
        Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
        Rails.logger.info("Loaded #{Sidekiq::Cron::Job.count} cron jobs")
      rescue => e
        Rails.logger.error("Failed to load cron jobs: #{e.message}")
      end
    end
  end
end 