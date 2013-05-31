module RailsConnector::LiquidSupport

  class FieldValueDrop < Liquid::Drop
    attr_accessor :__value, :__marker

    def initialize(obj, field, value, marker)
      @obj, @field, @__value, @__marker = obj, field, value, marker
    end

    def to_s
      action_view = @context.registers[:action_view]
      safe_value = __value.to_s.html_safe
      if __marker
        action_view.edit_marker(@obj, @field) { safe_value }
      else
        safe_value
      end
    end

  end

end
