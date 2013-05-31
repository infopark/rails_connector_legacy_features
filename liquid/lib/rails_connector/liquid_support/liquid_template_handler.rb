module RailsConnector::LiquidSupport

  module FieldValueDropPatcher
    def self.patch(mod)
      mod.module_eval do
        return if method_defined?(:field_value_drop_patched)
        define_method :field_value_drop_patched do; end
        (public_instance_methods - Module.public_instance_methods).each do |m|
          alias_method(old_m = "infopark_rails_connector_%s" % m, m)
          define_method m do |*args|
            first_arg = args.shift
            args.map!{|arg| arg.kind_of?(FieldValueDrop) ? arg.__value : arg}
            args.unshift(first_arg)
            if (drop = args.first).kind_of? FieldValueDrop
              args[0] = drop.__value
              value = __send__(old_m, *args)
              new_drop = drop.dup
              new_drop.__value = value
              return new_drop
            else
              return __send__(old_m, *args)
            end
          end
        end
      end
    end
  end

  FieldValueDropPatcher.patch(Liquid::StandardFilters)

  # A tag for rendering partials in Liquid templates
  #
  # Example:
  #    {% template 'name-of-partial' %}
  class TemplateTag < Liquid::Tag
    Syntax = /(#{Liquid::QuotedFragment}+)/

    def initialize(tag_name, markup, tokens)

      if markup =~ Syntax
        @partial_name = $1
      else
        raise Liquid::SyntaxError.new("Error in tag 'template' - Valid syntax: template '[name-of-template]'")
      end

      super
    end

    def render(context)
      context.registers[:action_view].controller.__send__(
        :render_to_string, :partial => context[@partial_name]
      )
    end

    Liquid::Template.register_tag('template', TemplateTag)
  end

  # Das LiquidTemplateRepository kann Liquid-Templates anwenden.
  # Zunächst muss das Template kompiliert werden, danach kann es gerendert werden.
  class LiquidTemplateRepository

    cattr_accessor :compiled_templates
    self.compiled_templates = {}

    def self.compile(template)
      template_id = generate_unique_template_id
      compiled_templates[template_id] = Liquid::Template.parse(template.source)
      template_id
    end

    def self.render(template_id, action_view)
      compiled_template = compiled_templates[template_id]

      unless compiled_template
        # this should never happen
        raise "render() called with illegal template id: #{template_id}"
      end

      rendered_template = compiled_template.render(
        {
          "obj" => action_view.instance_variable_get("@obj"),
          "named_object" => NamedObjectDrop.instance
        },
        :filters => [ObjFilters] + load_custom_filters,
        :registers => {:action_view => action_view}
      )

      report_errors(compiled_template, action_view.logger) unless compiled_template.errors.blank?

      rendered_template
    end

    # Nur zum Testen gedacht
    def self.drop_all
      self.compiled_templates = {}
    end

    def self.load_custom_filters
      return @loaded_custom_filters if @loaded_custom_filters
      extract = /^#{Regexp.quote(filters_dir.to_s)}\/?(.*_filters).rb$/
      @loaded_custom_filters = Dir["#{filters_dir}/**/*_filters.rb"].map do |file|
        filename = file.sub extract, '\1'
        require File.join(filters_dir, filename)
        filename.camelcase.constantize
      end
      @loaded_custom_filters.each {|m| FieldValueDropPatcher.patch(m)}
      @loaded_custom_filters
    end

    # Nur zum Testen gedacht
    def self.reset_custom_filters
      @loaded_custom_filters = nil
    end

    class << self

      private

      def generate_unique_template_id
        @template_id_counter ||= 0
        @template_id_counter += 1
        # include object_id to generate different id's if this class is reloaded by accident
        # (which should never happen, but you never know)
        "#{object_id}-#{@template_id_counter}"
      end

      def report_errors(compiled_template, logger)
        if ::RailsConnector::LiquidSupport.raise_template_errors
          raise compiled_template.errors.first
        else
          logger.warn(
            compiled_template.errors.map do |exception|
              "[Liquid Error] #{exception.message} trace: \n#{exception.backtrace.join("\n")}"
            end.join("\n\n")
          )
        end
      end

      def filters_dir
        Rails.root.join('app', 'filters')
      end

    end

  end

  # Dieser TemplateHandler integriert Liquid in Rails.
  #
  # Die Klasse ist bewusst sehr schlank gehalten und delegiert das eigentliche
  # Verarbeiten der Templates an das LiquidTemplateRepository.
  # Der Grund ist, dass die Klassen, die in Rails als TemplateHandler registriert
  # sind von Rails eingefroren werden (mittels Object.freeze) und daher keine
  # Klassenvariablen haben können.
  class LiquidTemplateHandler
    def self.call(template)
      template_id = LiquidTemplateRepository.compile(template)
      "#{LiquidTemplateRepository}.render('#{template_id}', self)"
    end

  end

end
