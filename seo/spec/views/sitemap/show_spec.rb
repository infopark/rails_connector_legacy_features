require "spec_helper"

describe "/seo_sitemap/show" do

  before do
    obj = mock_model(Obj)
    obj.stub(:permissions).and_return(mock('permissions', :live => []))
    obj.stub(:active?).and_return(true)
    obj.stub(:id).and_return(2001)
    obj.stub(:binary?).and_return(false)
    obj.stub(:root?).and_return(true)
    obj.stub(:name).and_return("test")
    last_changed = Time.now
    obj.stub(:last_changed).and_return(@last_changed)
    assign(:objects, [obj])
    view.stub(:cms_path).with(obj).and_return('/cms/path/to/obj')
    render
  end

  it "should render sitemap xml" do
    rendered.should include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
  end

  it "should render url element" do
    rendered.should include('<url>')
    rendered.should include('<loc>http://test.host/cms/path/to/obj</loc>')
  end

  it "should render 1.0 priority for root" do
    rendered.should include('<priority>1.0</priority>')
  end

end
