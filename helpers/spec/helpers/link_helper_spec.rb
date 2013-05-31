require "spec_helper"
include ActionView::Helpers::NumberHelper

module RailsConnector

  shared_examples_for "every generated markup" do
    before do
      helper.stub(:cms_path)
    end

    let(:html_safe_output) {
      helper.link(link)
    }

    it_should_behave_like "an html safe helper"

    it "should render an <a class='link'>" do
      helper.link(link).should have_tag("a.link")
    end

    it "should render a <span> inside the <a> tag" do
      helper.link(link).should have_tag("a span")
    end

    it "should render the display title as content of the first <span>" do
      helper.link(link).should have_tag("a > span", /^#{@title}/)
    end
  end


  describe LinkHelper, "link(internal link)" do
    let(:path) {'/path/to/object'}
    let(:title) {'irgendwat'}
    let(:dest_obj) {mock_model(Obj, :body_length => 4096, :binary? => true)}

    let(:link) {
      mock_model(Link, {
        :destination_object => dest_obj,
        :display_title => title,
        :internal? => true,
        :file_extension => "pdf",
        :target => 'bla',
      })
    }

    before do
      helper.stub(:cms_path).and_return(path)
    end

    it_should_behave_like "every generated markup"

    it "should render an <a> tag that links to the destination object" do
      helper.should_receive(:cms_path).with(link).and_return(path)
      helper.link(link).should have_tag("a[href='#{path}']")
    end

    it "should render the destination object's content type into the CSS class of the first <span>" do
      helper.link(link).should have_tag("a span.pdf")
    end

    it "should render the file size in human-readable form" do
      helper.link(link).should have_tag("a span span.link_size", " (4 KB)")
    end

    it "should set the target attribute" do
      helper.link(link).should have_tag("a[target=bla]")
    end

    it "should not set the target attribute if not available" do
      link.stub(:target)
      helper.link(link).should have_tag("a")
      helper.link(link).should_not have_tag("a[target=bla]")
    end
  end


  describe LinkHelper, "link(external link with query params)" do
    let(:url) {"ftp://ftp.infopark.de/main.asp?request=blah&foo=bar"}
    let(:title) {'titel des links'}
    let(:link) {
      mock_model(Link, {
        :display_title => title,
        :internal? => false,
        :file_extension => "",
        :target => 'bla',
        :external_prefix? => true,
        :url => url,
        :search => "",
        :fragment => "",
      })
    }

    it_should_behave_like "every generated markup"

    it "should render an <a> that links to the external url" do
      helper.stub(:cms_path).with(link).and_return(url)
      helper.link(link).should have_tag("a[href='#{url}']")
    end

    it "should set the target attribute" do
      helper.link(link).should have_tag("a[target=bla]")
    end
  end


  describe LinkHelper, "link(external link with query params and :file_extension => foo)" do
    let(:link) {
      mock_model(Link, {
        :display_title => "Titel",
        :internal? => false,
        :target => nil,
      })
    }

    before do
      helper.stub(:cms_path)
    end

    it "should encode the content type 'foo' into the CSS class of the first <span>" do
      helper.link(link, :file_extension => "foo").should have_tag("span.foo")
    end
  end


  describe LinkHelper, "link(external link with a file extension)" do
    let(:link) {
      mock_model(Link, {
        :display_title => "Titel",
        :internal? => false,
        :file_extension => "pdf",
        :target => nil,
      })
    }

    before do
      helper.stub(:cms_path)
    end

    it "should encode the content type 'pdf' into the CSS class of the first <span>" do
      helper.link(link).should have_tag("span.pdf")
    end
  end


  describe LinkHelper, "link(broken internal link)" do
    let(:title) {"Title"}
    let(:link) {
      mock_model(Link, {
        :destination_object => nil,
        :internal? => true,
        :display_title => title,
        :file_extension => "",
        :target => nil,
      })
    }

    it "should render just the title" do
      helper.link(link).should have_tag("span", /^#{title}/)
    end
  end


  describe LinkHelper, "link(non-binary internal link)" do
    let(:title) {"TI&TEL"}
    let(:dest_obj) {mock_model(Obj, :binary? => false)}
    let(:link) {
      mock_model(Link, {
        :destination_object => dest_obj,
        :display_title => title,
        :internal? => true,
        :file_extension => "",
        :target => nil,
      })
    }

    before do
      helper.stub(:cms_path).and_return("/path")
    end

    it "should render the destination object's title as content of the first <span>" do
      helper.link(link).should have_tag("a > span", "TI&amp;TEL")
    end

    it "should not render a nested <span class='link_size'>" do
      helper.link(link).should_not have_tag("a span span.link_size")
    end
  end


  describe LinkHelper, "link_list(list of links)" do
    let(:html_safe_output) {
      helper.should_receive(:link).with('test_link', {}).and_return('test_link')

      helper.link_list(['test_link'])
    }

    it_should_behave_like "an html safe helper"

    it "should render a <ul class='linklist'> with a <li> for each link" do
      helper.should_receive(:link).with(1, "options").and_return("1 options")
      helper.should_receive(:link).with(2, "options").and_return("2 options")
      helper.should_receive(:link).with(3, "options").and_return("3 options")
      markup = helper.link_list([1, 2, 3], "options")
      markup.should have_tag("ul.linklist li", "1 options")
      markup.should have_tag("ul.linklist li", "2 options")
      markup.should have_tag("ul.linklist li", "3 options")
    end
  end


  describe LinkHelper, "link_list(empty list)" do
    it "should render nothing" do
      helper.link_list([]).should be_nil
    end
  end


  describe LinkHelper, "link_list(nil)" do
    it "should render nothing" do
      helper.link_list(nil).should be_nil
    end
  end

end
