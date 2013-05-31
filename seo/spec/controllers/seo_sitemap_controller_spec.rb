require "spec_helper"

describe SeoSitemapController do
  let(:sitemap_routing_hash) {
    {
      :controller => "seo_sitemap",
      :action => "show",
      :format => "xml",
    }
  }

  describe "(Routing)" do
    describe "when seo_sitemap is enabled" do
      before do
        RailsConnector::Configuration.stub(:enabled?).and_return {|feature|
          :seo_sitemap == feature
        }
      end

      it "should route to the seo sitemap controller" do
        reload_routes_for_this_test
        {:get => "/sitemap.xml"}.should route_to(sitemap_routing_hash)
      end

      it "should route with static format independent of Accept header" do
        reload_routes_for_this_test
        sitemap_routing_hash[:format].should == "xml"
        {:get => "/sitemap.xml"}.should route_to(sitemap_routing_hash)
      end
    end

    describe "when seo_sitemap is not enabled" do
      before do
        RailsConnector::Configuration.stub(:enabled?).and_return {|feature|
          :seo_sitemap != feature
        }
      end

      it "should not route to the seo sitemap controller" do
        reload_routes_for_this_test
        {:get => "/sitemap.xml"}.should_not route_to(sitemap_routing_hash)
      end
    end
  end

  describe "GET /show" do
    it "should render successfully" do
      get 'show', :format => :xml
      response.should be_success
    end

    it "should retrieve all sitemappable objects" do
      Obj.should_receive(:find_all_for_sitemap).and_return(:sitemap_objs)
      get 'show'
      assigns[:objects].should == :sitemap_objs
    end
  end
end
