",
"require 'recaptcha'
require 'active_resource/exceptions'

module RailsConnector

  # This class provides a default controller implementation for user functionality.
  # It should be customized by subclassing.
  #
  # To change how all actions contacting the WebCRM behave in case of an WebCRM error,
  # override +on_crm_error+ in your subclassed controller. See Crm::Callbacks for details.
  #
  # To override what attributes are writable by the user when registering or editing profiles,
  # use +editable_attributes_on_register+ and +editable_attributes_on_edit+, respectively.
  # This can be done in your <tt>rails_connector.rb</tt> or in +UserController+ directly.
  #
  # By default, users can submit their first name, last name, email and company name.
  class DefaultUserController < ApplicationController

    before_filter :check_editable_attribute_configuration
    before_filter :redirect_to_login_unless_logged_in, :only => [
      :edit, :edit_password, :profile
    ]
    before_filter :check_recaptcha_keypair
    around_filter :handle_crm_errors

    cattr_accessor :editable_attributes_on_register, :editable_attributes_on_edit
    self.editable_attributes_on_register = {
      :contact => [:gender, :first_name, :last_name, :email, :phone, :language],
    }
    self.editable_attributes_on_edit = {
      :contact => [:first_name, :last_name, :email, :phone, :language],
    }

    include Crm::Localizable
    include Crm::Sanitization
    include Crm::Callbacks
    include ReCaptcha::AppHelper

    def self.store_user_attrs_in_session=(fields)
      raise %Q{
        DefaultUserController doesn't maintain which fields are stored in the session anymore.
        Please use CurrentUserConfiguration.store_user_attrs_in_session instead.
      }
    end

    # Displays a profile page containing links to all available actions
    def profile
    end

    # Logs a CRM user in.
    #
    # After successful login, user attributes are stored in <tt>session[:user]</tt>.
    #
    # To change which fields are stored in the session use
    # +CurrentUserConfiguration.store_user_attrs_in_session+.
    #
    # Use +current_user+ for a Contact object of the attributes stored in the session.
    #
    # The user will be redirected to the path given in the return_to param. If no
    # return_to param is set, the user will be redirected to the profile page.
    #
    # If you merely want to change what happens before or after a user is authenticated,
    # do not override this method but override +before_authenticate+ or +after_authenticate+.
    def login
      if request.post?
        @user = Infopark::Crm::Contact.new(params[:user] || {:login => nil, :password => nil})
        before_authenticate
        @user = Infopark::Crm::Contact.authenticate(@user.login, @user.password)
        if @user
          after_authenticate
          flash[:notice] = tcon('login_successful')
          self.current_user = @user
          redirect_to params[:return_to].blank? ?
            user_path(:action => 'profile') :
            params[:return_to]
        else
          flash.now[:error] = tcon('login_failed')
        end
      end
    rescue Infopark::Crm::Errors::AuthenticationFailed, ActiveResource::ResourceInvalid
      flash.now[:error] = tcon('login_failed')
    ensure
      @user.password = nil if @user
    end

    # Logs the user out by setting <tt>session[:user]</tt> to +nil+.
    #
    # To change the behavior before or after invalidating the session,
    # override +before_logout+ or +after_logout+.
    def logout
      before_logout
      self.current_user = nil
      after_logout
      redirect_to params[:return_to].blank? ? root_path : params[:return_to]
    end

    # Creates a WebCRM user.
    #
    # The user login is automatically set to his/her e-mail.
    #
    # If you merely want to change what happens before or after a user is registered,
    # do not override this method but override +before_register+ or +after_register+.
    def new
      @user = Infopark::Crm::Contact.new
      # Load some default attributes so that form_for is working
      @user.load(Crm::CONTACT_DEFAULT_ATTRS.merge(sanitize_user_params(params[:user],
          self.class.editable_attributes_on_register)))
      if request.post?
        if CurrentUserConfiguration.use_recaptcha_on_user_registration &&
            !validate_recap(params, @user.errors)
          raise ActiveResource::ResourceInvalid, "captcha failed"
        end
        before_register
        register
        after_register
        redirect_to(:action => "register_pending")
      end
    rescue ActiveResource::ResourceInvalid
      flash.now[:error] = tcon('registration_failed')
    end

    def register_pending
    end

    # Lets the user change his/her user details.
    def edit
      @user = Infopark::Crm::Contact.find(current_user.id)
      if request.post? || request.put?
        @user.load(sanitize_user_params(params[:user], self.class.editable_attributes_on_edit))
        @user.save
        flash[:notice] = tcon('edit_successful')
        redirect_to(:action => 'profile')
      end
    rescue ActiveResource::ResourceInvalid
      flash.now[:error] = tcon('edit_failed')
    end

    # Lets the user change his/her password.
    #
    # Validates the new password using +validate_edit_password_params_for+.
    def edit_password
      if request.post?
        validate_edit_password_params_for(params[:user])
        @user = Infopark::Crm::Contact.authenticate(current_user.login, params[:user][:old_password])
        @user.password_set(params[:user][:new_password])
        flash[:notice] = tcon('edit_password_successful')
        redirect_to(:action => "profile")
      end
    rescue ActiveResource::ResourceInvalid, Infopark::Crm::Errors::AuthenticationFailed
      flash.now[:error] = tcon('edit_password_failed')
    end

    # Lets the user request a new password (double opt-in).
    #
    # Uses the +ConfirmationMailer+ for sending out the confirmation message.
    def forgot_password
      if request.post?
        user = Infopark::Crm::Contact.search(:params => {:login => params[:user][:login]}).first
        if user
          confirmation_link = set_password_url_for(user)
          ConfirmationMailer.reset_password(user.email, confirmation_link).deliver
          flash[:notice] = tcon('reset_password_successful')
          redirect_to(:action => "forgot_password")
        else
          flash.now[:error] = tcon('request_password_failed')
        end
      end
    end

    def set_password
      if request.get? && params[:token].blank?
        flash[:error] = tcon('token_url_invalid')
      elsif request.post?
        if params[:user][:new_password].blank?
          flash.now[:error] = tcon('password_cannot_be_empty')
        elsif params[:user][:new_password] != params[:user][:new_password_confirm]
          flash.now[:error] = tcon('password_does_not_match_confirmation')
        else
          Infopark::Crm::Contact.password_set(params[:user][:new_password], params[:user][:token])
          flash[:notice] = tcon('password_set')
          redirect_to(:action => 'login')
        end
      end
    rescue ActiveResource::ResourceNotFound => e
      flash[:error] = tcon('set_password_failed')
    end

    protected

    def check_editable_attribute_configuration
      raise RuntimeError if editable_attributes_on_edit[:contact].nil? ||
          editable_attributes_on_register[:contact].nil?
    rescue
      raise ConfigurationError, "editable_attributes in UserController is not configured correctly"
    end

    def register
      if @user.email.blank?
        @user.errors.add(:base, tcon('email_blank'))
        raise ActiveResource::ResourceInvalid.new("E-mail can't be blank")
      end
      @user.login = @user.email
      @user.save!
      confirmation_link = set_password_url_for(@user)
      ConfirmationMailer.register_confirmation(@user.email, confirmation_link).deliver
      flash[:notice] = tcon('registration_successful_awaiting_confirmation')
    end

    def tcon(x)
      t("rails_connector.controllers.user.#{x}")
    end

    ALL_CRM_ERRORS = [
      Errno::ECONNREFUSED,
      ActiveResource::ForbiddenAccess,
      ActiveResource::UnauthorizedAccess,
      ActiveResource::BadRequest
    ]

    # invoke user defined callback when an error related to WebCRM occurs
    def handle_crm_errors
      yield
    rescue *ALL_CRM_ERRORS => e
      on_crm_error(e)
      default_render unless performed?
    end

    # Filter to force users to login by redirecting.
    def redirect_to_login_unless_logged_in
      redirect_to login_path unless logged_in?
    end

    # Checks if constants RCC_PUB and RCC_PRIV are set (for reCaptcha)
    #
    # Used as a filter in this controller.
    def check_recaptcha_keypair
      return true unless CurrentUserConfiguration.use_recaptcha_on_user_registration
      unless Object.const_defined?(:RCC_PUB) && Object.const_defined?(:RCC_PRIV)
        raise RuntimeError, <<-EOS

          reCaptcha requires the constants RCC_PUB and RCC_PRIV to be set.
          Please sign up for the reCaptcha webservice if you haven't already done so.

          Then set your public key in RCC_PUB and your private key in RCC_PRIV.
        EOS
      end
      true
    end

    # Validates the password for a given user.
    #
    # Used by #edit_password.
    def validate_edit_password_params_for(params)
      if params[:new_password].empty? || params[:new_password] != params[:new_password_confirm]
        raise ActiveResource::ResourceInvalid.new(
          "password is empty or does not match confirmation"
        )
      end
    end

    # Generates a URL for password confirmation.
    def set_password_url_for(user)
      url_for(
        :action => "set_password",
        :token => user.password_request(:params => {:only_get_token => true})
      )
    end
  end
end
