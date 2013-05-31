module RailsConnector

  # This module provides high-level access to the Infopark WebCRM.
  #
  # Methods from the {AuthenticationSupport} module are included
  # in all controllers.
  module Crm

    # This method requires the infopark_crm_connector gem.
    #
    # If the gem is available, it does the following:
    #  * require it
    #  * include +AuthenticationSupport+ in +ApplicationController+
    #  * declares helper methods in +ApplicationController+
    #  * adds a class-inheritable array to +ApplicationController+ for convenience
    #    (see +session_attributes_for+)
    #
    # If not, it raises a {LoadError}.
    def self.enable
      require 'infopark_crm_connector'
      ApplicationController.__send__(:include, AuthenticationSupport)
    end

    module AuthenticationSupport

      protected

      def self.included(base)
        base.helper_method :logged_in?, :current_user, :admin?
      end

      # Returns a hash of attributes for the given user that are to be stored in the session.
      #
      # Uses the array {CurrentUserConfiguration.store_user_attrs_in_session} to determine which
      # fields to store.
      # Because the field <tt>:id</tt> must always be stored in the session, it is always in the array
      # returned by {session_attributes_for}, independent on the fields specified by
      # {CurrentUserConfiguration.store_user_attrs_in_session}.
      #
      # User live_server_groups are stored in the session by default.
      def session_attributes_for(user)
        attributes = {}
        serialized_attributes = \
            user.attributes.merge(:live_server_groups => user.live_server_groups).symbolize_keys
        (CurrentUserConfiguration.store_user_attrs_in_session + [:id]).each do |attr|
          attributes[attr.to_sym] = serialized_attributes[attr.to_sym]
        end
        attributes[:live_server_groups] = serialized_attributes[:live_server_groups]
        attributes
      end

      # Determines if the user is logged in.
      # Defined as helper method in +ApplicationController+ when enabling the Crm feature.
      # @return bool
      def logged_in?
        !session[:user].blank?
      end

      # Returns a +Contact+ object with attributes stored in the session.
      #
      # To change which fields {DefaultUserController} stores in the session use
      # {CurrentUserConfiguration.store_user_attrs_in_session}.
      # @return [Infopark::Crm::Contact]
      def current_user
        @current_user ||= if logged_in?
          incorrect_encoding = session[:user].any? do |key, value|
            value.is_a?(String) && value.encoding_aware? && value.encoding.name != 'UTF-8'
          end
          if incorrect_encoding
            self.current_user = Infopark::Crm::Contact.find(session[:user][:id])
          end

          user_session = session[:user].dup
          live_server_groups = user_session.delete(:live_server_groups)
          user = Infopark::Crm::Contact.new(user_session || {})
          user.live_server_groups = live_server_groups
          user
        end
      end

      # Takes a +Contact+ object and stores its user attributes in the session.
      #
      # This can be helpful if you want to set a user for e.g. Googlebot.
      # @param [Infopark::Crm::Contact] user
      # @return [void]
      def current_user=(user)
        @current_user = user
        session[:user] = user.nil? ? nil : session_attributes_for(user)
      end

      # Reloads the +Contact+ object in +current_user+ from the WebCRM,
      # and updates the user attribute cached in the session.
      # @return [void]
      def reload_current_user
        user = current_user
        user.reload
        self.current_user = user
      end

      # Determines if the current user is admin (+false+ by default).
      # Defined as helper method in +ApplicationController+ when enabling the CRM feature.
      #
      # To change the default behavior overwrite <tt>admin?</tt> in your ApplicationController:
      #
      #   class ApplicationController < ActionController::Base
      #
      #     private
      #
      #     def admin?
      #       logged_in? && current_user.live_server_groups.include?("admins")
      #     end
      #
      #   end
      # @return bool
      def admin?
        false
      end

    end

    module Localizable
      # --------------------------------------------
      # This module can be included in controllers
      # that interface the WebCRM so error messages
      # are localized
      # --------------------------------------------
      def self.included(base)
        base.before_filter :set_crm_language
      end

      private

      def set_crm_language
        Infopark::Crm.configure {|config| config.locale = I18n.locale.to_s }
      end
    end

    module Sanitization
      # --------------------------------------------
      # This module is included in controllers to
      # sanitize user input, in reference to a given
      # whitelist
      # --------------------------------------------

      private

      def sanitize_user_params(user_params_or_nil, whitelist)
        user_params = user_params_or_nil || {}

        filtered_contact_attrs = filter_params_hash(
          user_params, whitelist[:contact]
        )

        filtered_contact_attrs
      end

      def filter_params_hash(source_hash, allowed_keys_unstringified)
        return {} unless source_hash
        allowed_keys = allowed_keys_unstringified.map(&:to_s)
        source_hash.reject { |key, value| !allowed_keys.include?(key) }
      end
    end

    # This module is included in {DefaultUserController} to provide callbacks for user functionality.
    #
    # If you want to add behavior before or after authentication, logout or register, override any of
    # the methods included in this module in your {UserController}.
    module Callbacks

      private

      # @!group Callbacks

      # Called by {DefaultUserController} on POST requests before a user is authenticated,
      # i.e. the user has already provided credentials in a form.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def before_authenticate
      end

      # Called by {DefaultUserController} before a user is logged out,
      # i.e. the session is reset.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def before_logout
      end

      # Called by {DefaultUserController} on POST requests before a user is created,
      # i.e. the user has already provided name, e-mail etc. in a form.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def before_register
      end

      # Called by {DefaultUserController} on POST requests after a user is authenticated,
      # i.e. the user has already provided correct credentials but the session has not yet been set.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def after_authenticate
      end

      # Called by {DefaultUserController} after a user is logged out,
      # i.e. the session is reset.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def after_logout
      end

      # Called by {DefaultUserController} on POST requests after a user is created,
      # i.e. a WebCRM activity has been created or the user has been created directly in the WebCRM.
      #
      # By default, it doesn't do anything.
      # @return [void]
      def after_register
      end

      # Called by {DefaultUserController} whenever requests to the WebCRM fail.
      # This includes <tt>Errno::ECONNREFUSED</tt> or the ActiveResource errors +ForbiddenAccess+,
      # +UnauthorizedAccess+, and +BadRequest+.
      #
      # By default, it raises an error so that administrators are notified immediately
      # if the WebCRM is down or not configured properly.
      # @return [void]
      def on_crm_error(exception)
        raise exception
      end

      # @!endgroup

    end

    # Default attributes for WebCRM's Contact.
    #
    # Helpers like +form_for+ will fail on +ActiveResource+ attributes
    # until those attributes are set.
    # See http://www.ruby-forum.com/topic/113542
    #
    # This constant provides default values for nearly all attributes.
    #
    # You are free to use any of these attributes in your views.
    # If you try to use others, +form_for+ will fail.
    CONTACT_DEFAULT_ATTRS = {
      :id => '',
      :account_id => '',
      :org_name_address => '',
      :org_unit_address => '',
      :extended_address => '',
      :street_address => '',
      :postalcode => '',
      :locality => '',
      :region => '',
      :country => '',
      :email => '',
      :fax => '',
      :first_name => '',
      :gender => 'N',
      :job_title => '',
      :language => 'en',
      :last_name => '',
      :login => '',
      :mobile_phone => '',
      :name_prefix => '',
      :phone => '',
      :want_geo_location => '',
      :want_email => 0,
      :want_phonecall => 0,
      :want_snailmail => 0
    }.stringify_keys

  end

end
