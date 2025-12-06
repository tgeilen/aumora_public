module Api
  module V1
    class BaseController < ApplicationController
      # Disable CSRF protection for API requests
      skip_before_action :verify_authenticity_token
      
      # Add authentication for API controllers
      before_action :authenticate_user!
      
      # Handle CORS preflight OPTIONS requests
      def options
        head :ok
      end
      
      protected
      
      # Use Devise JWT authentication
      # Let Devise handle the JWT token authentication
      # The authenticate_user! method is provided by Devise
      
      def current_user
        @current_user ||= warden.authenticate(:scope => :user)
      end
    end
  end
end 