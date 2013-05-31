require "spec_helper"

def do_ajax
  xhr :post, :rate, :id => "2001", :score => "4", :format => "html"
end

describe RatingsController, "AJAX /rate for a page", :required_feature => "ratings" do

  before do
    Obj.stub(:find).and_return(
      @obj = mock_model(Obj, :allow_rating? => true, :allow_anonymous_rating? => true)
    )
    @obj.stub(:rate)
    @obj.stub(:id).and_return(2001)
  end

  context "when ratings are not allowed" do
    before do
      @obj.stub(:allow_rating?).and_return(false)
    end

    it "should not rate the object" do
      @obj.should_not_receive(:rate)
      do_ajax
    end

    it "should render nothing" do
      do_ajax
      response.body.strip.should be_empty
      response.should be_success
    end
  end

  context "when anonymous ratings are not allowed" do
    before do
      @obj.stub(:allow_anonymous_rating?).and_return(false)
    end

    context "and user is not logged in" do
      before do
        controller.stub(:logged_in?).and_return(false)
        do_ajax
      end

      it "should render 403" do
        response.code.should == '403'
        response.should render_template('/errors/403_forbidden')
      end
    end
  end

  it "should fetch the object" do
    Obj.should_receive(:find).with("2001").and_return(@obj)
    do_ajax
    assigns[:obj].should == @obj
  end

  it "should persist the rating" do
    @obj.should_receive(:rate).with(4)
    do_ajax
  end

  it "should display the new rating per AJAX" do
    do_ajax
    response.should render_template("cms/_rating")
  end

  context "and the user has not yet rated the page" do
    it "should store the rating" do
      @obj.should_receive(:rate).with(4).and_return(true)
      do_ajax
      controller.session[:rated_objs][2001].should == 4
    end
  end

  context "and the user has already rated the page" do
    it "should not store the rating" do
      controller.should_receive(:user_has_already_rated?).with(@obj.id).and_return(true)
      @obj.should_not_receive(:rate)
      controller.should_not_receive(:store_rating_in_session)
      do_ajax
    end
  end

  describe "filter: user_has_already_rated?" do
    it "should return true if the user has rated for the object" do
      controller.stub(:session).and_return({:rated_objs => {"2001" => 5}})
      controller.send(:user_has_already_rated?, "2001").should be_true
    end

    it "should return nil if the user has not already rated" do
      controller.stub(:session).and_return({:rated_objs => {}})
      controller.send(:user_has_already_rated?, "2001").should be_nil
    end

    it "should return nil if the obj has never rated" do
      controller.stub(:session).and_return({})
      controller.send(:user_has_already_rated?, "2001").should be_nil
    end
  end

  describe "when resetting a rating" do
    context "as a non-admin user" do
      before do
        controller.stub(:admin?).and_return(false)
      end

      it "should do nothing but render 403" do
        @obj.should_not_receive(:reset_rating)
        get :reset, :id => 2001
        response.should be_forbidden
        response.should render_template("errors/403_forbidden")
      end
    end

    context "as an admin" do
      before do
        request.env["HTTP_REFERER"] = "/some/url"
        controller.stub(:admin?).and_return(true)
      end

      it "should reset the rating and redirect back" do
        @obj.should_receive(:reset_rating)
        get :reset, :id => 2001
        response.should redirect_to("/some/url")
      end
    end
  end
end
