require "spec_helper"

describe CmsController, "is_permitted" do
  it "should delegate to Obj#permitted_for_user?" do
    obj = mock_model(Obj, :permitted_for_user? => true)
    controller.__send__(:is_permitted, obj).should == true
    obj = mock_model(Obj, :permitted_for_user? => false)
    controller.__send__(:is_permitted, obj).should == false
  end
end


describe CmsController, "before filter ensure_object_is_permitted, where the user is permitted to see the object" do
  before do
    controller.instance_variable_set("@obj", mock_model(Obj, :permitted_for_user? => true))
  end

  it "should pass" do
    controller.__send__(:ensure_object_is_permitted).should == true
  end
end


describe CmsController, "before filter ensure_object_is_permitted, where the user is not permitted to see the object" do
  before do
    @obj = mock_model(Obj, :mime_type => 'text/html', :permitted_for_user? => false)
    request.for_cms_object(@obj)
    controller.stub(:ensure_object_is_active).and_return(true)
  end

  it "should stop the filter chain" do
    controller.should_not_receive(:index)
    get 'index'
  end

  it "should render a default error view" do
    get "index"
    response.should render_template("errors/403_forbidden")
    response.content_type.should == Mime::HTML.to_s
    response.code.should == "403"
  end

  it "should force html format" do
    request.should_receive(:format=).with(:html)
    get "index"
  end

  it "should should use customize render logic if given" do
    def controller.render_obj_error(status, name)
      render :template => "errors/403_forbidden_custom"
    end
    get "index"
    response.should render_template("403_forbidden_custom")
  end

  it "should remove the Obj from the view assigns" do
    get 'index'
    assigns[:obj].should be_nil
  end
end


describe CmsController, "accessible object" do
  before do
    @obj = mock_model(Obj)
    controller.should_receive(:is_permitted).with(@obj).and_return(true)
    controller.instance_variable_set("@obj", @obj)
  end

  it "should pass" do
    controller.__send__(:ensure_object_is_permitted).should == true
  end
end
