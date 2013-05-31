require "builder"

module RailsConnector

  module SES

    class VerityAccessor
      require 'net/http'
      require 'uri'
      require "rexml/document"

      #--
      # Options: see VeritySearchRequest
      #++
      def initialize(query, options = {})
        @query = query
        @options = {
          :host => 'localhost',
          :port => 3011,
          :offset => 0,
          :limit => 10,
          :min_relevance => 50,
          :max_docs => 'unlimited',
          :parser => 'simple',
          :sort_order => [["score", "desc"], ["name", "asc"]],
          :collections => ['cm-contents'],
          :base_query => nil
        }.merge(options)
        @options[:collections] = Array(options[:collection]).flatten if options.has_key?(:collection)
      end

      # Queries the SES and returns a SearchResult.
      #
      # Exceptions:
      # * SearchError - SES reported an error.
      #
      def search
        parse_response_payload(send_to_ses(build_request_payload))
      end

      private

      def build_request_payload
        x = Builder::XmlMarkup.new
        x.instruct!
        x.tag!('ses-payload', 'payload-id' => 'd-1f6a64dec16aa328-00000020-i', 'timestamp' => Time.now.to_iso, 'version' => '6') {
          x.tag!('ses-header') {
            x.tag!('ses-sender', 'sender-id' => '42', 'name' => 'infopark-rails-connector')
          }
          x.tag!('ses-request', 'request-id' => 'd-1f6a64dec16aa328-00000021-j-1', 'preclusive' => 'false') {
            x.tag!('ses-search') {
              x.query @query, :parser => @options[:parser]
              x.resultRecord {
                x.resultField 'objId'
                x.resultField 'score'
              }
              x.offset {
                x.start @options[:offset].to_i + 1
                x.length @options[:limit]
              }
              x.minRelevance @options[:min_relevance]
              x.maxDocs @options[:max_docs]

              unless @options[:sort_order].blank?
                x.sortOrder {
                  @options[:sort_order].each do |attribute, direction|
                    x.sortField attribute, :direction => direction
                  end
                }
              end

              x.searchBase {
                @options[:collections].each {|item| x.collection item }
                x.query @options[:base_query], :parser => @options[:parser] if @options[:base_query]
              }
            }
          }
        }
      end

      def send_to_ses(payload)
        res = Net::HTTP.new(@options[:host], @options[:port].to_i).start do |http|
          req = Net::HTTP::Post.new('/xml')
          req.body = payload
          http.request(req)
        end
        res.body
      end

      def parse_response_payload(response)
        xml = REXML::Document.new(response)
        if xml.elements['/ses-payload/ses-response/ses-code'].attributes['numeric'] == "200"
          build_successful_result(xml)
        else
          handle_error(xml)
        end
      end

      def build_successful_result(response)
        result = SearchResult.new(response.elements['/ses-payload/ses-response/ses-code/searchResults'].attributes['hits'].to_i)
        response.elements.to_a('/ses-payload/ses-response/ses-code/searchResults/record').each do |record|
          hit = Hit.new(record.elements['objId'].text.to_i, record.elements['score'].text.to_f)
          if hit.obj.present?
            result << hit
          else
            Rails.logger.warn("OBJ with ID ##{record.elements['objId'].text.to_i} not found: This search result will not be shown")
          end
        end
        result
      end

      # SES raises these errors:
      # 100171: ERROR_SYSTEM_SES_INTERNALVERITYERROR_DS
      # 100230: ERROR_SYSTEM_SES_VERITYERROR_DS
      # 100099: ERROR_SYSTEM_SES_DUPLICATECOLLETION_S
      # 100173: ERROR_SYSTEM_SES_OPENCOLLECTIONFAILED
      # 100103: ERROR_SYSTEM_SEARCHENGINE_SESSIONNEWFAILED
      # 100177: ERROR_SYSTEM_SEARCHENGINE_BULKSUBMITFAILED
      def handle_error(response)
        msg = ""
        response.elements.each('/ses-payload/ses-response/ses-code/errorStack/error') do |error|
          msg << error.elements['phrase'].text
          msg << "\n"
        end
        raise SearchError, msg
      end
    end
  end

end
