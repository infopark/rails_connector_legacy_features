require "spec_helper"

class CustomSearchController < RailsConnector::DefaultSearchController
  self.options = {:host => 'custom_host', :port => 9876}
end

describe CustomSearchController do
  before do
    controller.stub(:render) # view custom_search/search.html.erb does not exist

    # to make sure routes are cleaned up
    reload_routes_for_this_test

    Rails.application.routes.draw do
      match "custom_search" => "custom_search#search"
    end
  end

  describe "(search)" do
    it "should run the search using the custom options" do
      SearchRequest.should_receive(:new).
        with('foo', hash_including(
          :host => 'custom_host',
          :port => 9876,
          :offset => 0
        )).and_return(mock('search_request', :fetch_hits => RailsConnector::SES::SearchResult.new(17)))
      get 'search', :q => 'foo'
    end
  end
end
