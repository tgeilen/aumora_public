class KeepAliveJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "KeepAlive job executed at #{Time.current} - Worker dyno staying awake"
    
    # Simple operation to keep the worker active
    # This could be checking system status, cleaning up old data, etc.
    Rails.cache.write('last_keepalive', Time.current)
  end
end 