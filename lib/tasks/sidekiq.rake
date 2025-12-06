namespace :sidekiq do
  desc "Load Sidekiq cron jobs from schedule.yml"
  task load_cron: :environment do
    begin
      require 'sidekiq-cron'
    rescue LoadError
      puts "❌ sidekiq-cron gem not available. Make sure it's installed."
      exit 1
    end
    
    schedule_file = Rails.root.join('config', 'schedule.yml')
    
    if File.exist?(schedule_file)
      puts "Loading Sidekiq cron jobs from #{schedule_file}..."
      
      # Clear existing cron jobs first
      Sidekiq::Cron::Job.destroy_all!
      puts "Cleared existing cron jobs"
      
      # Load new jobs
      jobs_hash = YAML.load_file(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(jobs_hash)
      
      puts "Loaded #{Sidekiq::Cron::Job.count} cron jobs:"
      Sidekiq::Cron::Job.all.each do |job|
        puts "  - #{job.name}: #{job.cron} (#{job.description})"
      end
    else
      puts "Schedule file not found at #{schedule_file}"
      exit 1
    end
  end
  
  desc "List all Sidekiq cron jobs"
  task list_cron: :environment do
    begin
      require 'sidekiq-cron'
    rescue LoadError
      puts "❌ sidekiq-cron gem not available. Make sure it's installed."
      exit 1
    end
    
    jobs = Sidekiq::Cron::Job.all
    
    if jobs.any?
      puts "Sidekiq cron jobs:"
      jobs.each do |job|
        status = job.status
        last_run = job.last_enqueue_time&.strftime('%Y-%m-%d %H:%M:%S UTC') || 'Never'
        
        # Use different method names based on what's available
        next_run = if job.respond_to?(:next_enqueue_time)
          job.next_enqueue_time&.strftime('%Y-%m-%d %H:%M:%S UTC') || 'Unknown'
        elsif job.respond_to?(:next_time)
          job.next_time&.strftime('%Y-%m-%d %H:%M:%S UTC') || 'Unknown'
        else
          'Unknown'
        end
        
        puts "  #{job.name}:"
        puts "    Cron: #{job.cron}"
        puts "    Class: #{job.klass}"
        puts "    Status: #{status}"
        puts "    Description: #{job.description || 'No description'}"
        puts "    Last run: #{last_run}"
        puts "    Next run: #{next_run}"
        puts ""
      end
    else
      puts "No cron jobs found"
    end
  end
  
  desc "Test the scheduled ETF sync job"
  task test_etf_sync: :environment do
    puts "Testing scheduled ETF sync job..."
    
    begin
      job = ScheduledEtfSyncJob.perform_now
      puts "✅ ETF sync job completed successfully"
    rescue => e
      puts "❌ ETF sync job failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end
end 