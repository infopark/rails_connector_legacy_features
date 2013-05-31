require 'json'
require 'restclient'

module RailsConnector

  # This class provides a basic implementation for accessing a elasticsearch server.
  # It can be activated by making it the superclass of SearchRequest.
  # It should be customized by subclassing.
  class ElasticsearchRequest
    # Takes +query_string+ and +options+ for accessing Elasticsearch.
    #
    # +options+ is a hash and may include:
    #
    # <tt>:limit</tt>:: The maximum number of hits
    # <tt>:offset</tt>:: The search offset
    # <tt>:url</tt>:: A non-default Elasticsearch index URL
    def initialize(query_string, options = {})
      @query_string = query_string
      @options = Configuration.search_options.merge(options)
    end

    # Accesses Elasticsearch using #query and fetches search hits.
    def fetch_hits
      the_request = request_body
      (the_request[:fields] ||= []) << :obj_id
      the_request[:fields].uniq!
      the_request[:from] = @options[:offset] if @options[:offset]
      the_request[:size] = @options[:limit] if @options[:limit]

      hits = JSON.parse(
        RestClient::Request.execute(:method => :get, :url => url, :payload => the_request.to_json)
      )['hits']

      result = SES::SearchResult.new(hits['total'])
      hits['hits'].each do |hit|
        result << SES::Hit.new(hit['fields']['obj_id'], hit['_score'] / hits['max_score'], hit)
      end
      result
    end

    def request_body
      {
        :query => query,
        :filter => filter
      }
    end

    def query
      {
        :query_string => {
          :query => @query_string.
              gsub(/[^\w\*]/, ' ').
              gsub(/\b(and|or|not)\b/i, '').
              gsub(/\s+/, ' ').strip
        }
      }
    end

    def filter
      now = Time.now
      {
        :and => [
          {:not => {:term => {:obj_type => :image}}},
          {:not => {:term => {:suppress_export => true}}},
          {:not => {:range => {:valid_from => {:from => (now + 1.second).to_iso, :to => '*'}}}},
          {:not => {:range => {:valid_until => {:from => '*', :to => now.to_iso}}}}
        ]
      }
    end

    private

    def url
      "#{@options[:url]}/_search"
    end
  end

end
