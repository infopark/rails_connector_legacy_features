require "spec_helper"

module RailsConnector

  describe MicronavHelper, "micronav" do
    before do
      @ancestors = []
      @ancestors << @ancestor1 = mock_model(Obj, :display_title => "ancestor1's title")
      @ancestors << @ancestor2 = mock_model(Obj,
          :display_title => "<script>ancestor2's title</script>")
      @obj = mock_model(Obj, :display_title => "object's title", :ancestors => @ancestors)
      helper.stub(:cms_path).and_return("/path/to/ancestor")
    end

    it "should render one item for each ancestor and one item for the context object" do
      helper.micronav(@obj).should have_tag('ul li', :count => 3)
    end

    it "should link all but the last item" do
      helper.micronav(@obj).should have_tag('ul li:nth-child(1) a')
      helper.micronav(@obj).should have_tag('ul li:nth-child(2) a')
    end

    it "should decorate the last item with <span>" do
      helper.micronav(@obj).should have_tag('ul li:last-child span')
    end

    it "should render the quoted titles" do
      helper.micronav(@obj).should have_tag("ul li", /ancestor1's title/)
      helper.micronav(@obj).should have_tag("ul li a", "&lt;script&gt;ancestor2's title&lt;/script&gt;")
      helper.micronav(@obj).should have_tag("ul li", /object's title/)
    end

    it "should render <ul id='micronav'>" do
      helper.micronav(@obj).should have_tag('ul#micronav')
    end

    it "should mark the first item" do
      helper.micronav(@obj).should have_tag('li:first-child.first')
    end

    it "should mark the last item" do
      helper.micronav(@obj).should have_tag('li:last-child.last')
    end
  end


  describe MicronavHelper, "micronav", "with option :start => n given" do
    before do
      @ancestors = []
      @ancestors << @ancestor1 = mock_model(Obj, :display_title => "ancestor1's title")
      @ancestors << @ancestor2 = mock_model(Obj, :display_title => "ancestor2's title")
      @obj = mock_model(Obj, :display_title => "object's title", :ancestors => @ancestors)
      helper.stub(:cms_path).and_return("/path/to/ancestor")
    end

    it "should ignore an invalid start" do
      html = helper.micronav(@obj, :start => 0)
      html.should have_tag('ul li', :count => 3)
      html = helper.micronav(@obj, :start => -1)
      html.should have_tag('ul li', :count => 3)
    end

    it "should start at the 1st level if n == 1" do
      html = helper.micronav(@obj, :start => 1)
      html.should have_tag('ul li', :count => 3)
      html.should have_tag('ul li', /ancestor1's title/)
      html.should have_tag('ul li', /ancestor2's title/)
      html.should have_tag('ul li', /object's title/)
    end

    it "should start at the n-th level if n > 1" do
      html = helper.micronav(@obj, :start => 2)
      html.should have_tag('ul li', :count => 2)
      html.should have_tag('ul li', /ancestor2's title/)
      html.should have_tag('ul li', /object's title/)
    end

    it "should render only the context object if n == the level of the last item" do
      html = helper.micronav(@obj, :start => 3)
      html.should have_tag('ul li', :count => 1)
      html.should have_tag('ul li', /object's title/)
    end

    it "should render only the context object if n > the level of the last item" do
      html = helper.micronav(@obj, :start => 4)
      html.should have_tag('ul li', :count => 1)
      html.should have_tag('ul li', /object's title/)
    end
  end


  describe MicronavHelper, "micronav", "with option :micronav_id given" do
    before do
      @obj = mock_model(Obj, :display_title => "object's title", :ancestors => [])
      helper.stub(:cms_path).and_return("/path/to/ancestor")
    end

    it "should use this ID for <ul>" do
      helper.micronav(@obj, :micronav_id => 'my_nav').should have_tag('ul#my_nav')
    end
  end

end
