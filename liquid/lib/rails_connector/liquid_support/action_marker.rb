module RailsConnector

# @api public
module LiquidSupport

  # Usage example for actionmarkers in Liquid templates:
  #   {% actionmarker obj.images[0] editImageWizard param_a:value_a param_b:value_b %}
  #     [Edit image]
  #   {% endactionmarker %}
  #
  # The first parameter may be an instance of {ObjDrop} (usually +obj+ in Liquid templates),
  # +Array+ (such as a +LinkList+ field), or {LinkDrop} (as in the example above).
  #
  # The second parameter is the action to be run on the target objects.
  # Additional parameters to be forwarded to the action can be added as <tt>key:value</tt> pairs.
  # All parameters are evaluated in the current Liquid context and thus may contain,
  # for example, method calls on objects.
  #
  # Internally, the parameter <tt>:context</tt> is always set to the currently viewed object (+obj+)
  # and can not be overwritten.
  #
  # The Liquid actionmarker uses {RailsConnector::MarkerHelper#action_marker}.
  # @api public
  class ActionMarker < Liquid::Block
    def initialize(tag_name, markup, tokens)
      @obj_name, @method_name = markup.to_s.split(/\s+/)
      unless @obj_name && @method_name
        raise Liquid::SyntaxError.new("Syntax Error in 'actionmarker' - Valid syntax: actionmarker obj [action] [foo:bar]")
      end
      @params = {}
      markup.scan(/#{Liquid::TagAttributes}(#{Liquid::SpacelessFilter})?/) do |key, value, spaceless_filter|
        @params[key] = spaceless_filter.blank? ? value : "#{value}|#{spaceless_filter}"
      end
      super
    end

    def render(context)
      context.registers[:action_view].action_marker(
        (context[@method_name] || @method_name).to_s,
        target_objs(context),
        :params => params(context),
        :context => context['obj'].__drop_content
      ) do
        context.stack { render_all(@nodelist, context) }
      end
    end

  protected

    def target_objs(context)
      [ context[@obj_name] ].flatten.map do |item|
        case item
        when RailsConnector::Link
          item.destination_object
        when LinkDrop
          item.destination.__drop_content
        else
          item.__drop_content
        end
      end
    end

    def params(context)
      result = {}
      @params.each do |key, value|
        result[(context[key] || key).to_s] = (context[value] || value).to_s
      end
      result
    end
  end

  Liquid::Template.register_tag('actionmarker', ActionMarker)
end

end
