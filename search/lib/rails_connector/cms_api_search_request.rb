module RailsConnector

  # This class provides a basic implementation for accessing the search using the cms api.
  # It can be activated by making it the superclass of SearchRequest.
  # It should be customized by subclassing.
  class CmsApiSearchRequest

    # Takes +query_string+ and +options+ for accessing Cms Api Search.
    #
    # +options+ is a hash and may include:
    #
    # <tt>:limit</tt>:: The maximum number of hits
    # <tt>:offset</tt>:: The search offset
    def initialize(query_string, options = {})
      @query_string = query_string
      @options = options
    end

    # Accesses Cms Api Search using #query and fetches search hits.
    def fetch_hits
      search_enum = search_results

      result = SES::SearchResult.new(search_enum.size)
      search_enum.take(@options[:limit] || 10).each do |obj|
        hard_coded_score = 1
        result << SES::Hit.new(obj.id, hard_coded_score, {}, obj)
      end

      result
    end

    private

    def search_results
      now = Time.now
      search_enum = Obj.where(:_valid_from, :is_less_than, now.to_iso
          ).and_not(:_valid_until, :is_less_than, now.to_iso
          ).and_not(:_obj_class, :equals, 'Image'
          ).offset(@options[:offset] || 0
          ).batch_size(@options[:limit] || 10)

      @query_string.strip.split(/[\s]+/).each do |word|
        search_enum.and(:*, :contains_prefix, word)
      end

      search_enum
    end
  end

end
