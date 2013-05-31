class CurrentUserConfiguration
  # Default fields which the {DefaultUserController} will store in the session.
  DEFAULT_STORE_USER_ATTRS_IN_SESSION = [:login, :first_name, :last_name, :email, :id]

  class << self

    # Include ReCaptcha tags in user registration form and validate the captcha
    # when creating a new user registration (default: true).
    # @api public
    attr_accessor :use_recaptcha_on_user_registration

    #
    # Sets the array of fields which the +DefaultUserController+ will store in the session.
    # Defaults to {DEFAULT_STORE_USER_ATTRS_IN_SESSION}.
    #
    attr_writer :store_user_attrs_in_session

    #
    # Returns fields which the {DefaultUserController} stores in the session.
    # Defaults to {DEFAULT_STORE_USER_ATTRS_IN_SESSION}.
    #
    def store_user_attrs_in_session
      @store_user_attrs_in_session || DEFAULT_STORE_USER_ATTRS_IN_SESSION
    end
  end

  # defaults
  self.use_recaptcha_on_user_registration = true
end
