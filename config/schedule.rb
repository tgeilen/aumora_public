# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Set environment variables
set :environment, ENV['RAILS_ENV'] || 'development'
set :output, "#{path}/log/cron.log"

# ETF sync job - runs daily at 6 AM
every 1.day, at: '6:00 am' do
  runner "ScheduledEtfSyncJob.perform_later"
end

# Alternative schedules (uncomment the one you prefer):

# Run every weekday at 6 AM
# every :weekday, at: '6:00 am' do
#   runner "ScheduledEtfSyncJob.perform_later"
# end

# Run twice daily
# every 1.day, at: ['6:00 am', '6:00 pm'] do
#   runner "ScheduledEtfSyncJob.perform_later"
# end

# Run weekly on Sundays
# every :sunday, at: '6:00 am' do
#   runner "ScheduledEtfSyncJob.perform_later"
# end 