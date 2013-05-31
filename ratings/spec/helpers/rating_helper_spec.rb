require "spec_helper"

module RailsConnector

  describe DefaultRatingsHelper, "stars_for_rating", :required_feature => "ratings" do

    let(:obj) {mock_model(Obj, :id => 10)}

    let(:html_safe_output) {
      helper.stars_for_rating(obj)
    }

    it_should_behave_like "an html safe helper"

    it "should show 5 rateable stars" do
      stars_for_rating(obj).should have_tag('li a[class*="star"][href*="ratings/rate"]', :count => 5)
    end

    it "should provide descriptions for stars" do
      stars_for_rating(obj).should have_tag("li a[class*='star'][data-description='bad']")
      stars_for_rating(obj).should have_tag("li a[class*='star'][data-description='mediocre']")
      stars_for_rating(obj).should have_tag("li a[class*='star'][data-description='average']")
      stars_for_rating(obj).should have_tag("li a[class*='star'][data-description='good']")
      stars_for_rating(obj).should have_tag("li a[class*='star'][data-description='very good']")
    end

  end

end

