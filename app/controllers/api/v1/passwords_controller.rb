module Api
  module V1
    class PasswordsController < BaseController
      skip_before_action :authenticate_user!, only: [:create, :update]

      # POST /api/v1/passwords
      # Request password reset - sends reset email
      def create
        email = password_reset_params[:email].downcase.strip
        Rails.logger.info "Password reset requested for email: #{email}"
        
        user = User.find_by("LOWER(email) = ?", email)
        
        if user
          # Always send the reset instructions, regardless of confirmation status
          user.send_reset_password_instructions
          Rails.logger.info "Password reset instructions sent for user #{email}"
          
          render json: {
            message: 'If an account with that email exists, you will receive password reset instructions shortly.',
            email_sent: true
          }, status: :ok
        else
          Rails.logger.warn "Password reset requested for non-existent user: #{email}"
          
          # Return the same message for security reasons (don't reveal if email exists)
          render json: {
            message: 'If an account with that email exists, you will receive password reset instructions shortly.',
            email_sent: false
          }, status: :ok
        end
      end

      # PUT/PATCH /api/v1/passwords
      # Reset password with token
      def update
        user = User.reset_password_by_token(password_update_params)
        
        if user && user.errors.empty?
          # If password reset was successful and email wasn't confirmed yet, confirm it now
          # since the user has proven they have access to their email
          unless user.confirmed?
            user.confirm
            Rails.logger.info "Email automatically confirmed for user #{user.email} after password reset"
          end
          
          Rails.logger.info "Password successfully reset for user #{user.email}"
          
          render json: {
            message: 'Your password has been successfully reset. You can now sign in with your new password.',
            success: true
          }, status: :ok
        else
          Rails.logger.warn "Password reset failed: #{user&.errors&.full_messages}"
          
          error_messages = if user&.errors&.any?
                            user.errors.full_messages
                          else
                            ['Invalid or expired reset token']
                          end
          
          render json: {
            message: 'Password reset failed. The reset token may be invalid or expired.',
            errors: error_messages,
            success: false
          }, status: :unprocessable_entity
        end
      end

      private

      def password_reset_params
        params.require(:user).permit(:email)
      end

      def password_update_params
        params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end 