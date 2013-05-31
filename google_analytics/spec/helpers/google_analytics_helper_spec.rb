require "spec_helper"

module RailsConnector
  describe GoogleAnalyticsHelper do

    it "should render the google analytics snippet" do
      tags = helper.google_analytics_after_content_tags
      tags.should have_tag("script[type='text/javascript']") do |script|
        script.inner_text.should include('_gat._getTracker("UA-test")')
      end
    end

  end
end
