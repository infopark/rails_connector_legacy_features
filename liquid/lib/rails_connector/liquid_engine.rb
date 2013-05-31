require "rails"
require "action_view"

require 'rails_connector/liquid_configuration'

module ::RailsConnector
  class LiquidEngine < Rails::Engine

    initializer "rails_connector.liquid_support" do
      # Liquid Gem integration
      ActionView::Template.register_template_handler(
        :liquid, ::RailsConnector::LiquidSupport::LiquidTemplateHandler
      )
      if Rails.env.test? && ::RailsConnector::LiquidSupport.raise_template_errors == nil
        ::RailsConnector::LiquidSupport.raise_template_errors = true
      end
    end

    config.autoload_paths += paths['lib'].to_a
    config.autoload_once_paths += paths['lib'].to_a
  end
end

