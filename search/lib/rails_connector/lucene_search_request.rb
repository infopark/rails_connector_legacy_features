require 'rsolr'

module RailsConnector

  # This class provides a basic implementation for accessing a Solr search server.
  # It can be activated by making it the superclass of SearchRequest
  # (instead of DefaultSearchRequest).
  # It should be customized by subclassing.
  class LuceneSearchRequest
    attr_reader :query_string

    # Sanitizes the given +query_string+ and takes +options+ for accessing Solr.
    #
    # +options+ is a hash and may include:
    #
    # <tt>:limit</tt>:: The maximum number of hits
    # <tt>:offset</tt>:: The search offset
    # <tt>:solr_url</tt>:: A non-default Solr server URL
    # <tt>:filter_query</tt>:: See #filter_query_conditions
    # <tt>:solr_parameters</tt>:: A hash of additional query parameters (e. g. +timeAllowed+, +sort+)
    # <tt>:lazy_load</tt>:: when set to false (the default), the hits will load their associated Objs immediatley. Otherwise they will be loaded lazyly (when accessed through Hit#obj). Note that loading lazyly may expose hits that do not have an Obj, i.e. they return nil when Hit#obj is invoked. When loading immediately, those hits are filtered.
    def initialize(query_string, options = nil)
      @query_string = self.class.sanitize(query_string)
      @options = Configuration.search_options.merge(options || {})
    end

    # Accesses Solr and fetches search hits.
    #
    # Uses the #filter_query and +options+ given in #new.
    def fetch_hits
      solr = RSolr.connect(:url => @options[:solr_url])
      solr_result = solr.get("select", :params => solr_query_parameters)
      solr_response = solr_result['response']
      build_search_result(solr_response['numFound'], solr_response['docs'], solr_response['maxScore'])
    end

    # Removes unwanted characters from +text+.
    def self.sanitize(text)
      text.gsub(/[^\w\*]/, ' ').gsub(/\s+/, ' ').strip
    end

    def solr_query_for_query_string
      @query_string.downcase.split(/\s+/).map do |word|
        word unless %w(and or not).include?(word)
      end.compact.join(" AND ")
    end

    # Combines filter query conditions (see #filter_query_conditions).
    #
    # A filter query is used to reduce the number of documents before executing the actual query.
    # By default, all filter query conditions must be met, each is passed on as a separate filter query.
    def filter_query
      filter_query_conditions.values.compact
    end

    # A hash of conditions, combined to a filter query by #filter_query.
    # Note that all values of the hash must be valid Solr syntax.
    # The keys have no meaning and exist only so single conditions can be replaced
    # in a subclass:
    #
    #   class SearchRequest < LuceneSearchRequest
    #     def filter_query_conditions
    #       super.merge(:subset => 'path:/de/*')
    #     end
    #   end
    def filter_query_conditions
      conditions = {}
      conditions[:object_type] = 'NOT object_type:image'
      conditions[:suppress_export] = 'NOT suppress_export:1'
      now = Time.now
      conditions[:valid_from] = "NOT valid_from:[#{(now + 1.second).to_iso} TO *]"
      conditions[:valid_until] = "NOT valid_until:[* TO #{now.to_iso}]"
      conditions.merge(@options[:filter_query] || {})
    end

    private

    def solr_query_parameters
      {
        :q => solr_query_for_query_string,
        :fq => filter_query,
        :fl => 'id,score',
        :start => @options[:offset],
        :rows => @options[:limit]
      }.merge(@options[:solr_parameters] || {})
    end

    def build_search_result(total_hits, docs, max_score)
      result = SES::SearchResult.new(total_hits)
      docs.each do |doc|
        begin
          id = doc['id']
          score = doc['score'] / max_score
          hit = SES::Hit.new(id, score, doc)
          if @options[:lazy_load].blank? && hit.obj.blank?
            Rails.logger.warn("OBJ with ID ##{doc['id']} not found: This search result will not be shown")
          else
            result << hit
          end
        end
      end
      result
    end
  end

end
