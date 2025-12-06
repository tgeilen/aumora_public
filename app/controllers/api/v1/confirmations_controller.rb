module Api
  module V1
    class ConfirmationsController < BaseController
      skip_before_action :authenticate_user!, only: [:show, :create]

      # GET /api/v1/confirmations?confirmation_token=xyz
      def show
        user = User.find_by(confirmation_token: params[:confirmation_token])
        
        if user.nil?
          render json: {
            message: 'Invalid confirmation token.',
            confirmed: false
          }, status: :not_found
          return
        end
        
        if user.confirmed?
          render json: {
            message: 'Email is already confirmed! You can now log in.',
            confirmed: true
          }, status: :ok
          return
        end
        
        # Try to confirm the user
        confirmed_user = User.confirm_by_token(params[:confirmation_token])
        
        if confirmed_user && confirmed_user.errors.empty?
          render json: {
            message: 'Email confirmed successfully! You can now log in.',
            confirmed: true
          }, status: :ok
        else
          render json: {
            message: 'Invalid or expired confirmation token.',
            errors: confirmed_user&.errors&.full_messages || ['Unknown error'],
            confirmed: false
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/confirmations
      def create
        email = confirmation_params[:email].downcase.strip
        Rails.logger.info "Attempting to resend confirmation for email: #{email}"
        
        user = User.find_by("LOWER(email) = ?", email)
        
        if user
          if user.confirmed?
            Rails.logger.info "User #{email} is already confirmed"
            render json: {
              message: 'Email is already confirmed. You can sign in now.',
              confirmed: true
            }, status: :ok
          else
            Rails.logger.info "Resending confirmation instructions for user #{email}"
            user.send_confirmation_instructions
            render json: {
              message: 'Confirmation instructions sent to your email address.',
              email_sent: true
            }, status: :ok
          end
        else
          Rails.logger.warn "User with email #{email} not found in database"
          render json: {
            message: 'Email address not found. Please check your email address or register for a new account.',
            email_sent: false,
            errors: ['Email address not found']
          }, status: :not_found
        end
      end

      private

      def confirmation_params
        params.require(:user).permit(:email)
      end
    end
  end
end 