class SearchConfiguration

  class << self

    # default options for {SearchRequest}
    attr_writer :search_options

    # default options for {SearchRequest}
    def search_options
      @search_options || local_config_file["search"].symbolize_keys
    end

    def initialize_addon_mixins
      ::ApplicationController.__send__(:helper, :cms)
      if enabled?(:search)
        require "rails_connector/ses"
        RailsConnector::SES.enable
      end
    end

  end
end
