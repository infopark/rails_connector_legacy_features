require "spec_helper"

describe "/rss/index" do
  let(:rss) { Nokogiri::XML(rendered) }

  before do
    @pub_date = Time.now
    toclist = []
    (1..3).each do |i|
      toclist << mock_model(Obj,
        :name => "item_#{i}",
        :title => "Item #{i}",
        :rss_description => "Item description #{i}",
        :binary? => false,
        :permalink => "item_#{i}",
        :valid_from => @pub_date,
        :permitted_for_user? => true
      )
    end

    no_valid_from = mock_model(Obj,
      :name => "item_4",
      :title => "Item 4",
      :rss_description => "Item description 4",
      :permalink => "item_4",
      :binary? => false,
      :valid_from => nil,
      :permitted_for_user? => true
    )

    forbidden = mock_model(Obj,
      :permitted_for_user? => false
    )

    toclist << no_valid_from
    toclist << forbidden

    description_with_tags = RailsConnector::StringTagging.tag_as_html(
      "Get it while it's <strong>hot</strong>!",
      mock("Source")
    )
    assign(:obj, mock_model(Obj,
      :name => "news",
      :title => 'Latest News',
      :rss_description => description_with_tags,
      :permalink => 'news_permalink',
      :binary? => false,
      :sorted_toclist => toclist,
      :permitted_for_user? => true
    ))

    class << view
      include RailsConnector::DisplayHelper
      include RailsConnector::TableOfContentsHelper
    end

    view.stub(:current_user).and_return(mock)
  end

  it "should render a valid rss feed" do
    render
    rendered.should include('<?xml version="1.0" encoding="UTF-8"?>')
    rss.should have_tag("rss[version='2.0']")
  end

  it "should have a title" do
    render
    rss.should have_tag("rss > channel > title", "Latest News")
  end

  it "should have a link" do
    render
    rss.should have_tag("rss > channel > link", "http://test.host/news_permalink")
  end

  it "should have a description without html tags" do
    render
    rss.should have_tag("rss > channel > description", "Get it while it's hot!")
  end

  it 'should not choke on a feed without items' do
    assign(:obj, mock_model(Obj,
      :name => "nonews",
      :title => 'No News today',
      :rss_description => "",
      :permalink => 'no_news',
      :sorted_toclist => [],
      :permitted_for_user? => true
    ))
    lambda { render }.should_not raise_error
  end

  it "should have 4 items" do
    render
    rss.should have_tag("rss > channel > item", :count => 4)
  end

  it "should have items with title, description, pubDate, link and guid" do
    render
    (1..3).each do |i|
      rss.should have_tag("rss > channel > item > title", "Item #{i}")
      rss.should have_tag("rss > channel > item > description", "Item description #{i}")
      rss.should have_tag("rss > channel > item > pubDate", @pub_date.rfc2822)
      rss.should have_tag("rss > channel > item > link", %r|http://test.host/item_#{i}|)
      rss.should have_tag("rss > channel > item > guid", %r|http://test.host/item_#{i}|)
    end
  end

  describe "when rendering SEO links" do
    it "should render SEO links if Google Analytics is enabled" do
      RailsConnector::Configuration.stub(:enabled?).with(:google_analytics).and_return(true)
      render
      (1..3).each do |i|
        rss.should have_tag("rss > channel > item > link",
            "http://test.host/item_#{i}#utm_medium=rss&amp;utm_source=rss&amp;utm_campaign=/item_#{i}")
      end
    end

    it "should render SEO links only if Google Analytics is enabled" do
      RailsConnector::Configuration.stub(:enabled?).with(:google_analytics).and_return(false)
      render
      (1..3).each do |i|
        rss.should_not have_tag("rss > channel > item > link",
            "http://test.host/item_#{i}#utm_medium=rss&amp;utm_source=rss&amp;utm_campaign=/item_#{i}")
      end
    end
  end

  it "should have a pubDate only for items with valid_from" do
    render
    rss.should have_tag("rss > channel > item:last-child") do |last_item|
      last_item.should_not have_tag("pubDate")
    end
  end
end
