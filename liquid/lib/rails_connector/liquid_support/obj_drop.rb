module RailsConnector::LiquidSupport

  # Dieser Drop kapselt ein Obj. Der Zugriff auf das Obj ist nur für [] und ausgewählte Methoden erlaubt.
  class ObjDrop < Liquid::Drop
    def initialize(obj)
      @obj = obj
    end

    def __drop_content
      @obj
    end

    def before_method(method)
      raw_value = @obj[method]
      if raw_value
        value = if raw_value.kind_of?(Time)
          raw_value
        else
          @context.registers[:action_view].display_value(raw_value)
        end
        if value.kind_of?(::RailsConnector::LinkList)
          value
        else
          FieldValueDrop.new(@obj, method, value, use_edit_markers?)
        end
      else
        @obj.__send__(method) if @obj.respond_to?(method)
      end
    end

    private

    def use_edit_markers?
      if RailsConnector::Configuration.auto_liquid_editmarkers.nil?
        true
      else
        RailsConnector::Configuration.auto_liquid_editmarkers
      end
    end

  end

end
