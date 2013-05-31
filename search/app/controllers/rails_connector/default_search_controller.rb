require 'will_paginate'

module RailsConnector

  # This class provides a default controller implementation for searching.
  # It should be customized by subclassing.
  class DefaultSearchController < ApplicationController
    class_attribute :options
    self.options = {:limit => 10}

    # Fetches search hits and paginates them.
    # In case of an error, flashes appropriate error messages.
    #
    # For use in views, hits are stored in the <tt>@hits</tt> variable.
    # Pagination is done using the limit option (defaults to 10).
    # You can change that limit by subclassing <tt>DefaultSearchController</tt>
    # and then overwriting to <tt>CustomSearchController.options = {:limit => X}</tt>.
    #
    # To customize the pagination, you should subclass DefaultSearchController:
    #
    #   class SearchController < RailsConnector::DefaultSearchController
    #     def search
    #       # What this method should do:
    #       #  * Initialize a SearchRequest obj
    #       #  * Paginate the results
    #       #  * Fill the @hits variable for your views
    #       #  * Flash on errors
    #     end
    #   end
    def search
      unless (@query = params[:q]).blank?
        @hits = WillPaginate::Collection.create(current_page, options[:limit]) do |pager|
          result = SearchRequest.new(@query, options.merge(:offset => pager.offset)).fetch_hits
          pager.replace(result)
          pager.total_entries = result.total_hits
        end
      else
        flash.now[:errors] = I18n.t(:"rails_connector.controllers.search.specify_query")
      end
    rescue SES::SearchError => e
      logger.error(e)
      flash.now[:errors] = I18n.t(:"rails_connector.controllers.search.try_another_key")
    rescue Errno::ECONNREFUSED, Errno::EAFNOSUPPORT
      flash.now[:errors] = I18n.t(:"rails_connector.controllers.search.search_disabled")
    end

    private

    # This is just a convenience wrapper so the +options+ hash can be
    # accessed easily from an instance of this class.
    def options
      self.class.options
    end

    def current_page
      [params[:page].to_i, 1].max
    end
  end

end
