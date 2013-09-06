class Spree::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Auth

  layout false

  def self.provides_callback_for(*providers)
    providers.each do |provider|
      class_eval %Q{
        def #{provider}
          if request.env["omniauth.error"].present?
            render 'failure'
            return
          end

          authentication = Spree::UserAuthentication.find_by_provider_and_uid(auth_hash['provider'], auth_hash['uid'])

          if authentication.present?
            sign_in :spree_user, authentication.user
            @url = after_sign_in_url
            render 'success'
          elsif spree_current_user
            spree_current_user.apply_omniauth(auth_hash)
            if spree_current_user.save
              render 'success'
            else
              render 'failure'
            end
          else
            user = Spree::User.find_by_email(auth_hash['info']['email']) || Spree::User.new
            user.apply_omniauth(auth_hash)
            if user.new_record?
              password = SecureRandom.hex(24)
              user.password = password
              user.password_confirmation = password
            end
            if user.save
              sign_in :spree_user, user
              @url = after_sign_in_url
              render 'success'
            else
              session[:omniauth] = auth_hash.except('extra')
              render 'failure'
            end
          end

          if current_order
            user = spree_current_user || authentication.user
            current_order.associate_user!(user)
            session[:guest_token] = nil
          end
        end
      }
    end
  end

  SpreeSocial::OAUTH_PROVIDERS.each do |provider|
    provides_callback_for provider[1].to_sym
  end

  def failure
    render
  end

  def passthru
    render :file => "#{Rails.root}/public/404", :formats => [:html], :status => 404, :layout => false
  end

  def auth_hash
    request.env["omniauth.auth"]
  end

  private

    def after_sign_in_url
      session.delete('spree_user_return_to') || root_url
    end
end 
