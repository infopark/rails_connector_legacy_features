module RailsConnector
  # This class provides a default controller implementation for WebCRM form using custom attributes.
  # It should be customized by subclassing.
  class DefaultCrmFormController < DefaultCmsController

    include Crm::Localizable
    include Crm::Sanitization

    before_filter :authorize

    class_attribute :editable_attributes_on_register
    self.editable_attributes_on_register = {
      :contact => [:gender, :first_name, :last_name, :email]
    }

    def index
      unless logged_in?
        @user = Infopark::Crm::Contact.new(:language => default_language)
        @user.load(sanitize_user_params(params[:user], editable_attributes_on_register))
      end
      @activity = Infopark::Crm::Activity.new(:state => activity_state, :kind => activity_kind)
      @activity.load(sanitize_activity_params(params[:activity]))
      if request.post?
        if logged_in?
          @activity.contact_id = current_user.id
        else
          if @user.email.blank?
            @user.errors.add(:email, t(:'rails_connector.errors.messages.blank'))
            raise ActiveResource::ResourceInvalid.new("E-mail can't be blank")
          end
          @user.save!
          @activity.contact_id = @user.id
        end
        before_saving_activity(@activity)
        @activity.save
        raise ActiveResource::ResourceInvalid, "activity invalid" unless @activity.valid?
        after_saving_activity(@activity)
      end
    rescue ActiveResource::ResourceInvalid => e
      flash.now[:error] = t("rails_connector.controllers.crm_form.submit_failed")
    end

    protected

    # Returns the activity kind to create.
    # Override this method for custom logic to get from a given OBJ to an activity kind.
    #
    # Defaults to +@obj[:activity_kind]+ or 'contact form' if the former is +nil+.
    def activity_kind
      @obj[:activity_kind] || 'contact form'
    end

    # Returns the state of a new activity.
    #
    # Defaults to the first state assigned to +activity_kind+.
    def activity_state
      Infopark::Crm::CustomType.find(activity_kind).states.first
    end

    # Returns the language for a new contact, in case you don't have a language field in your form.
    #
    # If you want your visitors to choose their language, don't override this method!
    # Instead, include :language in your +editable_attributes_on_register+ and add
    # an additional form field to the corresponding view.
    #
    # Defaults to the current locale.
    def default_language
      I18n.locale.to_s
    end

    # Provides a callback to change the given activity in-place before saving it.
    # Be aware that this method may modify the argument.
    #
    # This method may be used to prepend the activity's title or otherwise customize
    # the behavior without having to override #index.
    #
    # By default, it assigns a default title if +has_title_input_field?+ is +false+.
    def before_saving_activity(activity)
      activity.title = "Website form submission" unless has_title_input_field?
    end

    # Provides a callback after saving the activity.
    # This method may be overridden to render a confirmation text,
    # or redirect the user to a separate confirmation page.
    #
    # The method is also available as helper in your views.
    #
    # By default, it renders crm_form/confirmation
    def after_saving_activity(activity)
      render 'crm_form/confirmation'
    end

    # Used by views to determine if input field for title should be rendered.
    # Override this method to return +false+ if you want to set the title programmatically.
    #
    # By default, it returns +true+
    def has_title_input_field?
      true
    end
    helper_method :has_title_input_field?

    # Sanitizes the given hash of POST parameters, cleaning out any key-value pairs that are
    # potentially dangerous if set by the user.
    # This prevents users from setting arbitrary activity properties, such as kind or state,
    # and custom attributes that are not to be set by users.
    #
    # By default, it returns a hash only with title and custom values.
    def sanitize_activity_params(activity_params_or_nil)
      activity_params_whitelist = [:title]
      (activity_params_or_nil || {}).reject do |attr, value|
        !(attr.starts_with?('custom_') && allow_custom_attribute?(attr)) &&
            !activity_params_whitelist.include?(attr.to_sym)
      end
    end

    # Default before_filter for this controller that renders
    # +crm_form/not_logged_in+ if the user is not logged in.
    #
    # Drop a custom view to change the look, or override this method
    # if you want different behavior, like a redirect.
    def authorize
      render 'not_logged_in' unless logged_in? || allow_anonymous?
    end

    # Returns +true+ if users should see the form even when they are not logged in.
    # In that case, the WebCRM activity includes a registration request so that a contact
    # can be created from it.
    #
    # The method is also available as helper in your views.
    #
    # By default, it returns +false+, i.e. only logged-in users can see the form
    def allow_anonymous?
      false
    end
    helper_method :allow_anonymous?

    # Returns +true+ if users should be able to fill in the given custom attribute.
    #
    # The method is also available as helper and used in +custom_fields_for+ in
    # +CrmFormHelper+.
    #
    # By default, it returns +true+ for any attribute, i.e. every custom attribute
    # can be filled in by the user.
    def allow_custom_attribute?(attribute_name)
      true
    end
    helper_method :allow_custom_attribute?

    # Returns a hash of attributes users are allowed to change in their profile.
    # Use it in your views and your controller.
    # The hash has only one key, +:contact+, with an array of symbols.
    #
    # Do not override this (instance) method. Assign a new hash in your subclass:
    #
    #   class CrmFormController < RailsConnector::DefaultCrmFormController
    #
    #     self.editable_attributes_on_register = {
    #       :contact => [:first_name, :last_name, :email]
    #     }
    #
    #   end
    def editable_attributes_on_register
      self.class.editable_attributes_on_register
    end
    helper_method :editable_attributes_on_register
  end
end