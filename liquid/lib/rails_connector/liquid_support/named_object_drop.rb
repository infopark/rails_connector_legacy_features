require "singleton"

module RailsConnector::LiquidSupport

  # Dieser Drop realisiert den Zugriff auf Objekte, die per NamedLink referenziert werden
  class NamedObjectDrop < Liquid::Drop
    include Singleton

    def before_method(method)
      RailsConnector::NamedLink.get_object(method)
    end

  end
end
