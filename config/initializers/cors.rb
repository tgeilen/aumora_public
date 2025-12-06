# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5173', '127.0.0.1:5173', 'localhost:5174', '127.0.0.1:5174',
            'localhost:3000', '127.0.0.1:3000', 'localhost:3036', '127.0.0.1:3036',
            '192.168.178.123:3000', '192.168.178.123:3036',
            /\A192\.168\.\d+\.\d+:3000\z/, /\A192\.168\.\d+\.\d+:3036\z/,
            'https://app.aumora.tech', 'app.aumora.tech'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end 