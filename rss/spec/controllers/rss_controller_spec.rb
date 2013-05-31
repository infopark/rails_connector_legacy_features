require "spec_helper"

describe "(Routing)" do
  subject { RssController.new }

  let(:rss_routing_hash) {{:controller => "rss", :action => "index", :format => "rss"}}

  describe "when rss feature is enabled" do
    before do
      RailsConnector::Configuration.stub(:enabled?).and_return {|feature|
        feature == :rss
      }
    end

    it "should route to rss#index" do
      reload_routes_for_this_test
      {:get => "/rss"}.should route_to(rss_routing_hash)
    end

    it 'should route statically to the format rss independently of Accept header' do
      reload_routes_for_this_test
      # anybody seen route hash slicing yet?
      rss_routing_hash[:format].should == "rss"
      {:get => "/rss"}.should route_to(rss_routing_hash)
    end
  end

  describe "when the feature is not enabled" do
    before do
      RailsConnector::Configuration.stub(:enabled?).and_return {|feature|
        feature != :rss
      }
    end

    it "should not route to rss#index" do
      reload_routes_for_this_test
      {:get => "/rss"}.should_not route_to(rss_routing_hash)
    end
  end
end

describe RssController do
  it "should inherit from DefaultCmsController" do
    RssController.ancestors.should include(RailsConnector::DefaultCmsController)
  end
end

describe RssController, "#index" do
  let(:root) {mock_model(Obj)}

  before do
    controller.stub(:ensure_object_is_permitted).and_return(true)
    controller.stub(:ensure_object_is_active).and_return(true)
    controller.stub(:set_google_expire_header)
    # see initializers/rails_connector.rb
    Obj.stub(:root).and_return(root)
  end

  it "should assign the rss root object to @obj" do
    get :index
    assigns[:obj].should == root
  end

  it "should respond to rss" do
    get :index, :format => :rss
    response.should be_success
    response.headers['Content-Type'].should =~ /^application\/rss\+xml/
  end
end
