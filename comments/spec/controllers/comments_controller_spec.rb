require "spec_helper"

describe CommentsController, "(routing)" do
  describe "feature is enabled" do
    it "should have the actions" do
      RailsConnector::Configuration.stub(:enabled?).and_return(true)
      reload_routes_for_this_test
      {:get => '/comments/create'}.should route_to({:controller => "comments", :action => "create"})
    end
  end

  describe "feature is disabled" do
    it "should have no actions" do
      RailsConnector::Configuration.stub(:enabled?).and_return(false)
      reload_routes_for_this_test
      {:get => '/comments/create'}.should_not route_to({:controller => "comments", :action => "create"})
    end
  end
end

describe CommentsController, "AJAX /create with valid comment values for a page",
    :required_feature => "comments" do

  before do
    (@obj = Obj.root).comments.delete_all
    Obj.stub(:find).and_return(@obj)
  end

  after do
    @obj.comments.delete_all if @obj
  end

  def post_comment_via_ajax(comment_params = nil)
    comment_params ||= {:name => "ich", :email => "ich@foo.xy", :subject => "betreff", :body => "none sense"}
    xhr :post, :create, {:obj_id => "15", :comment => comment_params}, :format => "json"
  end

  describe "when anonymous comments are not allowed" do
    before do
      @obj.stub(:allow_anonymous_comments?).and_return(false)
    end

    describe "and user is not logged in" do
      before do
        controller.stub(:logged_in?).and_return(false)
        post_comment_via_ajax
      end

      it "should render 403" do
        response.code.should == '403'
        response.should render_template('/errors/403_forbidden')
      end
    end
  end

  describe "and user is logged in" do
    before do
      controller.stub(:logged_in?).and_return(true)
      controller.stub(:current_user).and_return(
        mock(Object,
          :first_name => 'max',
          :last_name => 'musterman',
          :email => 'max.musterman@example.org'
        )
      )
      post_comment_via_ajax
    end

    it "should adopt the information from current user" do
      @obj.comments.first.name.should == 'max musterman'
      @obj.comments.first.email.should == 'max.musterman@example.org'
    end
  end

  describe "if comments are allowed for the object" do
    it "should create a new comment" do
      lambda { post_comment_via_ajax }.should change(@obj.comments, :count).by(1)
    end
  end

  describe "if comments are not allowed for the object" do
    it "should not create a new comment" do
      @obj.should_receive(:allow_comments?).and_return(false)
      lambda { post_comment_via_ajax }.should change(@obj.comments, :count).by(0)
    end
  end

  describe "when rendering the response body" do
    render_views

    it "should render a json with comment's markup" do
      post_comment_via_ajax({
        :name => "Darth Vader",
        :subject => "Luke...",
        :body => "Luke, I am your father!",
        :email => "darth.vader@deathstar.com"
      })
      JSON.parse(response.body)["comment"].should have_tag("div.comment") do |comment|
        comment.should have_tag(".name", /Darth Vader/)
        comment.should have_tag(".subject", /Luke.../)
        comment.should have_tag(".body", /Luke, I am your father!/)
      end
    end

    describe "and the comment has errors" do
      it "should render json with comment's errors" do
        post_comment_via_ajax({})
        JSON.parse(response.body)["errors"].should eq(%w(name body subject email))
      end
    end
  end

  describe "when a new comment has successful been created" do
    it "should call #after_create callback" do
      controller.should_receive(:after_create).once
      post_comment_via_ajax
    end
  end

  describe "when the comment could not be created" do
    it "should not call #after_create callback" do
      controller.should_not_receive(:after_create)
      post_comment_via_ajax({})
    end
  end

  it "should define the private callback method 'after_create'" do
    lambda do
      controller.__send__(:after_create)
    end.should_not raise_error(NoMethodError)

    CommentsController.private_instance_methods.map(&:to_s).should include('after_create')
  end
end

describe CommentsController, "GET /create for a page", :required_feature => "comments" do

  it "should render nothing" do
    get :create, :obj_id => Obj.root.id
    response.body.strip.should be_empty
  end
end

describe CommentsController, "GET /delete", :required_feature => "comments" do

  let(:comment) { mock_model(Comment) }

  before do
    Comment.stub(:find).with('1234').and_return(comment)
  end

  describe "when is not admin" do
    before do
      controller.stub(:admin?).and_return(false)
    end

    it "should render 403" do
      comment.should_not_receive(:destroy)
      get :delete, :id => 1234
      response.should be_forbidden
      response.should render_template("errors/403_forbidden")
    end
  end

  describe "when is admin" do
    before do
      request.env["HTTP_REFERER"] = "/some/url"
      controller.stub(:admin?).and_return(true)
    end

    it "should destroy apropriate comment" do
      comment.should_receive(:destroy)
      get :delete, :id => '1234'
    end

    it "should redirect back" do
      get :delete, :id => '1234'
      response.should redirect_to("/some/url")
    end
  end
end
