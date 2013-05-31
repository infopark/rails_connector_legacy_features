module RailsConnector::LiquidSupport

  # This is a wrapper class used internally to make helper methods available in
  # Liquid templates. Helpers have to be enabled in the app initialization like this:
  #
  #    RailsConnector::LiquidSupport.enable_helpers(
  #       :helper_a,
  #       :helper_b
  #     )
  class GeneralHelperTag < Liquid::Tag
    attr_reader :params

    def initialize(tag_name, markup, tokens)
      @tag_name = tag_name
      @params = markup.to_s.scan(/(#{::Liquid::Expression})*/).flatten.compact.map(&:strip)
      super
    end

    def render(context)
      context.registers[:action_view].__send__(@tag_name, *params(context))
    end

    def self.<<(helper)
      Liquid::Template.register_tag(helper, self)
      self
    end

  protected

    def params(context)
      @params.map { |p| context[p] || p }.map do |item|
        case item
        when LinkDrop
          item.destination.__drop_content
        when ObjDrop
          item.__drop_content
        else
          item.to_s
        end
      end
    end
  end

end
