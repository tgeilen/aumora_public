module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      before_action :configure_permitted_parameters, if: :devise_controller?

      # POST /api/v1/login
      def create
        email = params.dig(:user, :email) || params.dig(:session, :user, :email)
        password = params.dig(:user, :password) || params.dig(:session, :user, :password)
        
        Rails.logger.info "Login attempt for email: #{email}"
        
        user = User.find_by(email: email)
        
        if user.nil?
          Rails.logger.warn "Login failed: User not found for email #{email}"
          render json: { error: 'Invalid email or password' }, status: :unauthorized
          return
        end
        
        Rails.logger.info "User found: #{user.email}, confirmed: #{user.confirmed?}"
        
        if user.valid_password?(password)
          # Check if user's email is confirmed
          unless user.confirmed?
            Rails.logger.warn "Login failed: Email not confirmed for user #{user.email}"
            return render json: { 
              error: 'Please confirm your email address before signing in.',
              confirmation_required: true 
            }, status: :unauthorized
          end
          
          Rails.logger.info "Password valid for user #{user.email}, signing in"
          
          # Sign in the user with Devise - this generates the JWT token automatically
          sign_in(user)
          
          # Get the token from the Warden JWT Auth header
          token = request.env['warden-jwt_auth.token']
          
          Rails.logger.info "Login successful for user #{user.email}"
          
          # Return user with token
          render json: {
            user: user.as_json(only: [:id, :email, :created_at, :updated_at]),
            token: token
          }, status: :ok
        else
          Rails.logger.warn "Login failed: Invalid password for user #{user.email}"
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      # DELETE /api/v1/logout
      def destroy
        # Simply return no content and let Devise JWT handle token revocation
        head :no_content
      end

      protected

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
      end
    end
  end
end 