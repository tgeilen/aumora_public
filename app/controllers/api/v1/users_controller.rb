module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_user!, except: [:create]
      before_action :set_user, only: [:show, :update, :destroy]
      
      # GET /api/v1/users/current
      def current
        render json: current_user
      end
      
      # GET /api/v1/users/:id
      def show
        render json: @user
      end
      
      # POST /api/v1/users
      def create
        # Check if user already exists (case-insensitive)
        email = user_params[:email].downcase.strip
        Rails.logger.info "User registration attempt for email: #{email}"
        
        existing_user = User.find_by("LOWER(email) = ?", email)
        
        if existing_user
          if existing_user.confirmed?
            Rails.logger.info "Registration failed: User #{email} already exists and is confirmed"
            render json: { 
              errors: ['An account with this email address already exists. Please sign in instead.'] 
            }, status: :unprocessable_entity
          else
            # User exists but not confirmed - resend confirmation
            Rails.logger.info "Resending confirmation for existing unconfirmed user: #{email}"
            existing_user.send_confirmation_instructions
            render json: {
              message: 'An account with this email already exists but is not confirmed. We have sent a new confirmation email.',
              confirmation_required: true
            }, status: :ok
          end
        else
          # Create new user
          @user = User.new(user_params.merge(email: email))
          
          # Skip automatic confirmation email from Devise
          @user.skip_confirmation_notification!
          Rails.logger.info "Creating new user: #{email} (automatic confirmation email skipped)"
          
          if @user.save
            # Manually send confirmation email only once
            Rails.logger.info "User #{email} created successfully, sending confirmation email"
            @user.send_confirmation_instructions
            render json: {
              user: @user.as_json(only: [:id, :email, :created_at, :updated_at]),
              message: 'Registration successful! Please check your email to confirm your account.',
              confirmation_required: true
            }, status: :created
          else
            Rails.logger.warn "User creation failed for #{email}: #{@user.errors.full_messages}"
            render json: { 
              errors: @user.errors.full_messages 
            }, status: :unprocessable_entity
          end
        end
      end
      
      # PUT/PATCH /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        head :no_content
      end
      
      private
      
      def set_user
        @user = if params[:id] == 'current'
                  current_user
                else
                  User.find(params[:id])
                end
      end
      
      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
 