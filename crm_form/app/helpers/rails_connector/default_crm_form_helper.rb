module RailsConnector

  module DefaultCrmFormHelper

    include ::RailsConnector::DefaultUserHelper
    include ::RailsConnector::MandatoryLabelHelper
    include ::RailsConnector::ErrorMessagesHelper

    def custom_fields_for(form)
      activity = instance_variable_get("@#{form.object_name}")
      custom_attribute_defs = Infopark::Crm::CustomType.find(activity.kind).custom_attributes
      content = "".html_safe
      custom_attribute_defs.each do |attribute|
        custom_attr = "custom_#{attribute.name}"
        next unless allow_custom_attribute?(custom_attr)
        value = activity.__send__(custom_attr).to_s
        input_field =
          case attribute.type
          when 'enum'
            form.select(custom_attr, [''] + attribute.valid_values, :value => value)
          when 'text'
            form.text_area(custom_attr, :value => value, :cols => 50, :rows => 5)
          else
            form.text_field(custom_attr, :value => value, :size => "40")
          end
        content << content_tag(:div, :class => 'label') do
          if attribute.mandatory
            mandatory_label_for(form, custom_attr, h(attribute.title))
          else
            form.label(custom_attr, h(attribute.title))
          end
        end
        content << content_tag(:div, input_field, :class => 'field')
      end
      content
    end

    def title_field_for(form)
      content = "".html_safe
      if has_title_input_field?
        content << content_tag(:div, :class => 'label') do
          mandatory_label_for(form, :title, t(:"rails_connector.views.crm_form.title"))
        end
        content << content_tag(:div, :class => 'field') do
          form.text_field :title
        end
      end
      content
    end

    def logged_in_as(user)
      content_tag(:em) do
        t('rails_connector.views.crm_form.logged_in_as',
            :user => content_tag(:strong, user)).html_safe
      end
    end
  end
end
