require "spec_helper"

module RailsConnector
  describe TrackingHelper do

    describe "google_analytics" do
      describe "rendering the ga snippet" do

        describe "if the domain is not configured and thus invalid" do
          before do
            controller.request.host = "invalid"
          end

          it "should render nothing" do
            helper.google_analytics.should be_blank
          end
        end

        describe "if the domain is configured" do
          before do
            controller.request.host = "www.infopark.de"
          end

          let(:html_safe_output) {
            helper.google_analytics
          }

          it_should_behave_like "an html safe helper"

          it "should contain the ga account code" do
            helper.google_analytics.should include(
                '_gat._getTracker("UA-528505-1")')
          end
        end
      end
    end

  end
end
