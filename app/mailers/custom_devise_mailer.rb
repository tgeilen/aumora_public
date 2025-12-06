class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  protected

  def devise_mail(record, action, opts = {}, &block)
    # Attach the logo to all Devise emails
    attachments.inline['logo-green-nobg.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'logo-green-nobg.png'))
    
    super(record, action, opts, &block)
  end
end 