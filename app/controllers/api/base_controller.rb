module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_user!, except: [:options]
    
    respond_to :json
    
    # Handle OPTIONS request for CORS preflight
    def options
      head :ok
    end
    
    # Handle common API errors
    rescue_from StandardError do |e|
      respond_with_error(e.message, :internal_server_error)
    end
    
    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_with_error(e.message, :not_found)
    end
    
    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_with_error(e.message, :unprocessable_entity)
    end
    
    private
    
    def respond_with_error(message, status)
      render json: { error: message }, status: status
    end
  end
end 