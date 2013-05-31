module RailsConnector
  class Configuration

    # This module adds configuration options for the RSS feature.
    #
    # Specify the RSS root in
    # <code><em>RAILS_ROOT</em>/config/initializers/rails_connector.rb</code>:
    #   RailsConnector::Configuration::Rss.root = lambda { NamedLink.get_object('news') }
    module Rss

      # Raised if no RSS root object has been specified.
      class RootUndefined < StandardError; end
      # Raised if the root is missing when accessing it
      # Inherits from {RootUndefined} for compatibility reasons
      class RootNotFound < RootUndefined; end

      @root_provider = nil

      # Stores the obj providing lambda for later use
      def self.root=(obj_provider)
        case obj_provider
        when Obj
          Rails.logger.warn("Rss.root= called with an Obj. Use an Obj returning lambda instead.")
          root_id = obj_provider.id
          @root_provider = lambda { Obj.find(root_id) }
        when Proc
          @root_provider = obj_provider
        else
          raise ArgumentError.new("Rss.root= called with '#{obj_provider.class.name}' instead of a lambda.")
        end
      end

      # Returns the RSS root object.
      # If no RSS root has been specified then {Rss::RootUndefined} is raised.
      def self.root
        raise RootUndefined unless @root_provider
        begin
          @root_provider.call
        rescue RailsConnector::ResourceNotFound
          raise RootNotFound
        end
      end
    end

  end
end
