# Ensure our service classes are autoloaded by Rails
Rails.application.config.autoload_paths += %W[
  #{Rails.root}/app/services
] 