require "spec_helper"

module RailsConnector
  describe RssHelper do

    describe "for the html head" do

      it "should render an rss link tag" do
        helper.rails_connector_header_tags.should have_tag(
            "link[rel=alternate][type='application/rss+xml'][title='RSS Feed'][href*='/rss']")
      end
    end

  end

end
