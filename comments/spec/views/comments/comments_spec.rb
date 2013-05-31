# encoding: utf-8
require "spec_helper"

describe "/comments/index", :required_feature => "comments" do

  let(:obj) { Obj.root }

  before do
    RailsConnector::Configuration.stub(:enabled?).and_return(true)
    view.stub(:logged_in?).and_return(false)
    view.stub(:admin?).and_return(false)
    assign(:obj, obj)
    assign(:comment, Comment.new)
  end

  def self.it_should_render_nothing
    it "should render nothing" do
      render
      rendered.strip.should == ''
    end
  end

  describe "if feature is not enabled" do
    before do
      RailsConnector::Configuration.should_receive(:enabled?).with(:comments).and_return(false)
    end

    it_should_render_nothing
  end

  describe "if the object doesn't allow comments" do
    before do
      obj.stub(:allow_comments?).and_return(false)
    end

    it_should_render_nothing
  end

  describe "if the object allows comments" do
    before do
      obj.comments.delete_all
    end

    shared_examples_for "with or without comments" do
      it "should render a comments container" do
        rendered.should have_tag('div#comments_container')
      end

      it "should render a form" do
        rendered.should have_tag('div#comment_form_container form') do |form|
          form.should have_tag('legend')
          form.should have_tag('label#comment_form_name_label')
          form.should have_tag('input#comment_name')
          form.should have_tag('label#comment_form_email_label')
          form.should have_tag('input#comment_email')
          form.should have_tag('label#comment_form_subject_label')
          form.should have_tag('input#comment_subject')
          form.should have_tag('label#comment_form_body_label')
          form.should have_tag('textarea#comment_body')
          form.should have_tag('input[type=submit][value=send]')
        end
      end
    end

    describe "without comments" do
      before do
        obj.stub(:comments).and_return([])
        render
      end

      it_should_behave_like "with or without comments"

      it "should render a 'no comments...' notice" do
        rendered.should have_tag('span[id=no_comments]', /There are no comments yet/)
        rendered.should_not have_tag('div.comment_list_container')
        rendered.should_not have_tag('div.comment')
      end
    end

    describe "with comments" do
      before do
        @comment_a = obj.comments.create!(
          :name => 'Karel Gott',
          :email => 'karel@example.com',
          :subject => 'Biene Maja',
          :body => 'Und diese Biene, die ich meine…'
        )
        @comment_b = obj.comments.create!(
          :name => 'Hermann van Veen',
          :email => 'hermann@example.com',
          :subject => 'Alfred J. Quack',
          :body => 'Plätscher plätscher Feder, Wasser mag doch jeder…'
        )
        render
      end

      after do
        obj.comments.delete_all if platform_under_test_supports?("comments")
      end

      it_should_behave_like "with or without comments"

      it "should render a list of comments" do
        rendered.should have_tag("div.comment[id='%s']" % "comment_#{@comment_a.id}")
        rendered.should have_tag("div.comment[id='%s']" % "comment_#{@comment_b.id}")
      end
    end
  end

  describe "and the current user is logged in" do
    before do
      view.should_receive(:logged_in?).and_return(true)
      render
    end

    it "should render no form fields for name and e-mail" do
      rendered.should_not have_tag('label#comment_form_name_label')
      rendered.should_not have_tag('input#comment_name')
      rendered.should_not have_tag('label#comment_form_email_label')
      rendered.should_not have_tag('input#comment_email')
    end
  end

  describe "and no anonymous comments are allowed" do
    before do
      obj.stub(:allow_anonymous_comments?).and_return(false)
      render
    end

    it "should render an apropriate flash message" do
      rendered.should have_tag('div[class=login_required]', /Please login to leave a comment./)
    end
  end

  describe "when rendering delete buttons" do
    before do
      obj.stub(:comments).and_return([mock_model(Comment,
        :id => 1234,
        :name => "Karel Gott",
        :email => "karel@example.com",
        :subject => "Biene Maja",
        :body => "Und diese Biene, die ich meine…",
        :created_at => Date.today
      )])
    end

    it "should render delete button" do
      view.stub(:admin?).and_return(true)
      render
      rendered.should have_tag("#comment_list_container .admin a[href='/comments/delete/1234']")
    end

    it "should render delete button only for admin" do
      view.stub(:admin?).and_return(false)
      render
      rendered.should_not have_tag("#comment_list_container .admin a")
    end
  end
end
