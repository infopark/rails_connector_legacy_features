require "spec_helper"

describe SearchController, "GET /search" do
  it "should render the view" do
    get 'search'
    response.should render_template("search")
    flash.now[:errors].should == "Please enter a search term."
  end
end


describe SearchController, "GET /search?q=foo" do
  before do
    SearchRequest.stub(:new).and_return(
      mock(SearchRequest, :fetch_hits => RailsConnector::SES::SearchResult.new(17))
    )
  end

  def do_get
    get 'search', :q => 'foo bar'
  end

  it "should perform the search" do
    SearchRequest.should_receive(:new).with('foo bar', anything).
      and_return(mock('search_request', :fetch_hits => RailsConnector::SES::SearchResult.new(17)))
    do_get
  end

  it "should assign the hits for the view" do
    do_get
    hits = assigns[:hits]
    hits.should be_kind_of(WillPaginate::Collection)
    hits.total_entries.should == 17
  end

  it "should render the view" do
    do_get
    response.should render_template("search")
  end
end

describe SearchController, "Pagination" do
  let(:search_request) {
    mock(SearchRequest, :fetch_hits => RailsConnector::SES::SearchResult.new(17))
  }

  describe "should adjust the offset according to the page parameter" do
    it "offset 0 for page 1" do
      SearchRequest.
        should_receive(:new).
        with(anything, hash_including(:offset => 0)).
        and_return(search_request)

      get 'search', :q => 'foo bar', :page => 1
    end

    it "offset #{SearchController.options[:limit]} for page 2" do
      SearchRequest.
        should_receive(:new).
        with(anything, hash_including(:offset => SearchController.options[:limit])).
        and_return(search_request)

      get 'search', :q => 'foo bar', :page => 2
    end
  end
end


describe SearchController, "GET /search?q=foo, where SES raised an error" do
  before do
    SearchRequest.stub(:new).and_raise(RailsConnector::SES::SearchError)
  end

  it "should set a flash error" do
    get 'search', :q => 'foo'
    flash[:errors].should == "Please repeat your search with a different search term."
  end
end


describe SearchController, "GET /search?q=foo, where SES is not reachable" do
  before do
    SearchRequest.stub(:new).and_raise(Errno::ECONNREFUSED)
  end

  it "should set a flash error" do
    get 'search', :q => 'foo'
    flash.now[:errors].should == "Search is currently not available due to maintenance. We apologize for this error."
  end
end
