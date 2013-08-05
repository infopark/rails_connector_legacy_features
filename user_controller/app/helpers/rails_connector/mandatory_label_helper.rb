module RailsConnector
  module MandatoryLabelHelper
    def mandatory_label_for(form, object, label)
      html = "".html_safe
      html += label
      html += content_tag(:span, " *", :class => "mandatory_star")
      form.label(object, html, :class => "mandatory")
    end
  end
end
