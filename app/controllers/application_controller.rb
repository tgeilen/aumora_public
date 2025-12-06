class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Add Devise helpers
  include Devise::Controllers::Helpers

  def frontend
    render 'home/index'
  end
end
