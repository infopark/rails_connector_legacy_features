require 'spec_helper'

describe "crm_form/index" do
  before do
    obj = Obj.root
    assign(:obj, obj)
    assign(:activity, mock('Activity', :kind => 'contact form', :title => ''))
    Infopark::Crm::CustomType.should_receive(:find).with('contact form') \
        .and_return(mock('ct', :custom_attributes => []))
    view.stub(:cms_path).and_return("/cms/path/to/obj")
    view.stub(:has_title_input_field?).and_return(true)
    view.stub(:logged_in?).and_return(true)
    view.stub(:display_field).and_return("some field")
    view.stub!(:current_user).and_return(mock(:login => 'hi@example.com'))
  end

  it "should render the 'cms/index' partial" do
    render
    rendered.should =~ /some field/
  end

  it "renders a POST form with action set to the OBJ itself" do
    render
    rendered.should have_tag("form[action='/cms/path/to/obj'][method=post]")
    rendered.should have_tag("form[action='/cms/path/to/obj'][method=post] input[type=submit]")
  end

  it "renders an input field for title if necessary" do
    render
    rendered.should have_tag("form div.label label[for=activity_title]")
    rendered.should have_tag("form div.field input[id=activity_title][name='activity[title]']")
  end

  it "omits the input field for title if necessary" do
    view.stub(:has_title_input_field?).and_return(false)
    render
    rendered.should_not have_tag("form div.label label[for=activity_title]")
    rendered.should_not have_tag("form div.field input[id=activity_title]")
  end

  it "does not render registration fields" do
    render
    rendered.should_not have_tag("form div.label label[for*=registration]")
    rendered.should_not have_tag("form div.field input[id*=registration]")
  end

  it "renders a 'logged in as X'" do
    view.should_receive(:logged_in_as).with('hi@example.com')
    render
  end

  describe 'when allowing anonymous users' do
    before do
      view.stub!(:logged_in?).and_return(false)
      view.stub!(:editable_attributes_on_register).and_return({:contact => [:first_name]})
    end

    it "renders fields for user registration if not logged in" do
      render
      rendered.should have_tag("form div.label label[for=user_first_name]")
      rendered.should have_tag("form div.field input[id=user_first_name][name='user[first_name]']")
    end
  end
end
