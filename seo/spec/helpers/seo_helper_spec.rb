require "spec_helper"

module RailsConnector
  shared_examples_for "all SEO headers" do
    let(:html_safe_output) {
      helper.seo_header_tags
    }

    it_should_behave_like "an html safe helper"
  end

  describe SeoHelper, "without @obj" do
    it_should_behave_like "all SEO headers"

    it "should render a title tag" do
      helper.seo_header_tags.should have_tag('title', '')
      helper.seo_header_tags(:company_name => 'Infopark AG').
        should have_tag('title', 'Infopark AG')
    end

    it "should render a meta description" do
      helper.seo_header_tags(:default_description => 'mary had a little lamb').
        should have_tag("meta[name=description][content='mary had a little lamb']")
    end

    it "should render default keywords" do
      helper.seo_header_tags(:default_keywords => 'default, key, words').
        should have_tag("meta[name=keywords][content='default, key, words']")
    end

    it "should render the object's keywords, if given" do
      helper.seo_header_tags(:default_keywords => 'default, key, words').
        should have_tag("meta[name=keywords][content='default, key, words']")
    end

    it "should render a meta content_type" do
      helper.seo_header_tags.should have_tag(
        "meta[http-equiv=Content-Type][content='text/html; charset=utf-8']")
    end
  end

  describe SeoHelper, "with assigned @obj" do
    before do
      assign(:obj, @obj = Obj.root)
      @obj.stub(:display_title).and_return('Dialog im Web.')
      @obj.stub(:body).and_return("this is the main content")
    end

    it_should_behave_like "all SEO headers"

    it "should render a title tag" do
      helper.seo_header_tags.should have_tag(
        'title', 'Dialog im Web.')
      helper.seo_header_tags(:company_name => 'Infopark AG').should have_tag(
        'title', 'Dialog im Web. | Infopark AG')
    end

    it "should render a meta description" do
      @obj.stub(:seo_description)
      helper.seo_header_tags(:default_description => 'mary had a little lamb').
        should have_tag("meta[name=description][content='mary had a little lamb']")

      @obj.should_receive(:seo_description).and_return('mary had two little lambs')
      helper.seo_header_tags.should have_tag(
        "meta[name=description][content='mary had two little lambs']")
    end

    it "should render default keywords" do
      @obj.stub(:seo_keywords).and_return('')
      helper.seo_header_tags(:default_keywords => 'default, key, words').
          should have_tag("meta[name=keywords][content='default, key, words']")
    end

    it "should render the object's keywords, if given" do
      @obj.stub(:seo_keywords).and_return('beatles, rolling stones, spinal tap')
      helper.seo_header_tags.should have_tag("meta[name=keywords][content='beatles, rolling stones, spinal tap']")
      helper.seo_header_tags(:default_keywords => 'default, key, words').
          should have_tag("meta[name=keywords][content='beatles, rolling stones, spinal tap']")
    end

    it "should render a meta content_type" do
      helper.seo_header_tags.should have_tag("meta[http-equiv=Content-Type][content='text/html; charset=utf-8']")
    end

    describe "(canonical link)" do
      before do
        @obj.stub(:permalink).and_return("my/permalink")
      end

      it "should render an http link" do
        helper.seo_header_tags.should have_tag(
            "link[rel=canonical][href='http://test.host/my/permalink']")
      end

      it "should render an https link" do
        controller.request.stub(:ssl?).and_return(true)
        helper.seo_header_tags.should have_tag(
            "link[rel=canonical][href='https://test.host/my/permalink']")
      end
    end
  end

end
