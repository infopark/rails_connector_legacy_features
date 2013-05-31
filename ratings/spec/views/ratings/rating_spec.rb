require "spec_helper"

describe "/cms/_rating", :required_feature => "ratings" do

  before do
    RailsConnector::Configuration.stub(:enabled?).with(:ratings).and_return(true)
    view.stub(:admin?).and_return(false)
  end

  describe "where ratings allowed" do
    let(:obj) do
      mock_model(Obj,
        :average_rating_in_percent => 90,
        :allow_rating? => true,
        :allow_anonymous_rating? => true
      )
    end

    before do
      assign(:obj, obj)
      view.stub(:rated_by_current_user?).and_return(false)
      view.stub(:stars_for_rating).and_return(false)
    end

    it "should render the ratings section" do
      render
      rendered.should have_tag("div#starRating")
    end

    it "should provide default description" do
      render
      rendered.should have_tag("#starRating[data-default_description='Please rate here.']")
    end

    it "should render apropriate message when already rated" do
      view.stub(:rated_by_current_user?).and_return(false)
      render
      rendered.should include("Please rate here")

      view.stub(:rated_by_current_user?).and_return(true)
      render
      rendered.should include("Thank you for rating")
    end

    describe "and anonymous ratings are not allowed" do
      before do
        obj.stub(:allow_anonymous_rating?).and_return(false)
      end

      describe "and user is logged in" do
        before do
          view.stub(:logged_in?).and_return(true)
        end

        it "should render the rating form" do
          render
          rendered.should have_tag('div#starRating')
        end

        it "should not render 'login required' message" do
          render
          rendered.should_not have_tag('div.rating_login_required')
        end
      end

      describe "and user is not logged in" do
        before do
          view.stub(:logged_in?).and_return(false)
        end

        it "should not render rating form" do
          render
          rendered.should_not have_tag('div#starRating')
        end

        it "should render an appropriate message" do
          render
          rendered.should have_tag('div.rating_login_required')
        end
      end
    end

    describe "when rendering the reset button" do
      it "should render the reset button" do
        view.stub(:admin?).and_return(true)
        render
        rendered.should have_tag("#starRating .admin a[href*='/ratings/reset/%d']" % obj.id, /Reset rating/)
      end

      it "should render the reset button only for an admin" do
        view.stub(:admin?).and_return(false)
        render
        rendered.should_not have_tag("#starRating .admin a")
      end
    end
  end

  def self.it_should_render_nothing
    it "should render nothing" do
      render
      rendered.strip.should be_empty
    end
  end

  describe "where feature is not enabled" do
    before do
      RailsConnector::Configuration.should_receive(:enabled?).with(:ratings).and_return(false)
    end

    it_should_render_nothing
  end

  describe "where ratings are not allowed" do
    before do
      assign(:obj, mock_model(Obj, :average_rating_in_percent => 90, :allow_rating? => false))
    end

    it_should_render_nothing
  end
end
