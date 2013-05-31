require "recaptcha"

module RailsConnector

  # This module contains helpers for the {UserController} and {DefaultUserController}
  module DefaultUserHelper

    include ::ReCaptcha::ViewHelper
    include ::RailsConnector::MandatoryLabelHelper
    include ::RailsConnector::ErrorMessagesHelper

    # Returns mandatory user fields as array of symbols.
    def mandatory_user_fields
      [:email, :gender, :language, :last_name]
    end

    # Generates part of a form for the given attributes:
    #
    # In your view, use:
    #
    #   <%= form_for @user, :as => :user do |f| -%>
    #     <%= user_fields_for(f, 'contact', :first_name, :last_name) %>
    #   <% end -%>
    #
    # to generate labels and fields for the contact:
    #
    #   <form>
    #     <div class="label"><label for="user_first_name">First name</label></div>
    #     <div class="field"><input id="user_first_name" name="user[first_name]" size="30" type="text" /></div>
    #     <div class="label"><label for="user_last_name">Last name</label></div>
    #     <div class="field"><input id="user_last_name" name="user[last_name]" size="30" type="text" /></div>
    #   </form>
    #
    # Labels are localized automatically, using the scope views.contact and views.location,
    # respectively. For example:
    #
    #   views:
    #     user:
    #       first_name: First name
    #       last_name: Last name
    def user_fields_for(form, model_name, *attributes)
      output = "".html_safe
      attributes.flatten.each do |attr|
        output += content_tag(:div, :class => 'label') do
          if mandatory_user_fields.include?(attr)
            mandatory_label_for(form, attr, t("rails_connector.views.user.#{model_name}.#{attr}"))
          else
            form.label(attr, t("rails_connector.views.user.#{model_name}.#{attr}"))
          end
        end
        form_field = case attr
          when :gender
            form.select(:gender, genders_for_select)
          when :language
            languages = Infopark::Crm::CustomType.find('contact').languages
            form.select(:language, languages_for_select_for(languages),
                :selected => (@user ? @user.language : I18n.locale.to_s) )
          else
            form.text_field(attr)
          end
        output += content_tag(:div, form_field, :class => 'field')
      end
      output
    end

    def genders_for_select
      [
        ['', 'N'],
        [t('rails_connector.views.user.gender_female'),'F'],
        [t('rails_connector.views.user.gender_male'), 'M']
      ]
    end

    def languages_for_select_for(*languages)
      options = []
      languages.flatten.each do |lang|
        options << [t(:"rails_connector.views.user.languages.#{lang}"), lang]
      end
      options
    end

    def profile_fields_for(form, editable_attributes={})
      output = "".html_safe
      output += user_fields_for(form, "contact", editable_attributes[:contact])
      output
    end

  end

end
