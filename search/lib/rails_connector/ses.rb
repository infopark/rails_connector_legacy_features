module RailsConnector

  # This module accesses the Infopark Search Engine Server.
  # @api public
  module SES

    autoload :VerityAccessor, "rails_connector/ses/verity_accessor"

    # This method enables Obj to perform searches using the SES Search Engine Server.
    def self.enable
      ::Obj.extend Obj::ClassMethods
    end

    module Obj
      # Extends the model class Obj with the class method find_with_ses.
      module ClassMethods
        # Queries the search engine and returns a SearchResult. The parameters
        # are passed on to a SearchRequest (a kind of DefaultSearchRequest by default).
        #
        # Exceptions:
        # * SearchError - The search engine reported an error.
        #
        def find_with_ses(query_string, options = {})
          SearchRequest.new(query_string, options).fetch_hits
        end
      end
    end

    class SearchError < StandardError
    end

    # SearchResult is the list of hits in response to a search query. Since the
    # maximum number of hits to return has been specified, there might be more
    # hits available in the search engine.
    # @api public
    class SearchResult < Array
      # The total number of hits.
      # @api public
      attr_reader :total_hits

      def initialize(total_hits)
        super()
        @total_hits = total_hits
      end
    end

    # A hit represents a found document for a particular search query.
    # @api public
    class Hit
      # The ID of the found Obj.
      # @api public
      attr_reader :id

      # The score of the hit.
      # @api public
      attr_reader :score

      # The raw result hash returned by the search engine, for a low-level access.
      # Don't use this unless you know what you're doing.
      # Be aware that this is not migration safe.
      # @api public
      attr_reader :doc

      def initialize(id, score, doc={}, obj=nil)
        @id = id
        @score = score
        @doc = doc
        @obj = obj
      end

      # Returns the hit's corresponding Obj (or nil if none found in the database).
      # @api public
      def obj
        @obj ||= ::Obj.find(@id)
      rescue RailsConnector::ResourceNotFound
        nil
      end
    end
  end

end
