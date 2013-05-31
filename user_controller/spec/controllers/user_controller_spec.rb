require "spec_helper"

CRM_ERRORS = [
  Errno::ECONNREFUSED,
  ActiveResource::ForbiddenAccess,
  ActiveResource::UnauthorizedAccess,
  ActiveResource::BadRequest
]

describe UserController, "GET /login" do

  it "should render the login view" do
    get 'login'
    response.should render_template("login")
  end

end

def post_login(options = {})
  post 'login', {:user => {'login' => "root", 'password' => "root"}}.merge(options)
end

def post_new(user_options = {})
  post 'new', {:user => {"email" => "joe@example.org"}.merge(user_options)}
end

describe UserController, "when logging in" do

  before do
    @mock_user = mock("Contact", :contact_id => 123, :name => "John Smith")
    Infopark::Crm::Contact.stub(:authenticate).and_return(@mock_user)
  end

  describe 'and the user credentials are valid' do
    before do
      @attributes = {:id => 12, :login => 'login', :first_name => 'John', :last_name => 'Smith',
          :email => 'mail@'}
      @mock_user = mock("Contact", :attributes => @attributes, :live_server_groups => [])
      @mock_user.stub(:password=)
      Infopark::Crm::Contact.stub(:authenticate).and_return(@mock_user)
    end

    it 'should contact the CRM to authenticate' do
      Infopark::Crm::Contact.should_receive(:authenticate).and_return(@mock_user)

      post_login
    end

    it "should fetch the user's details" do
      Infopark::Crm::Contact.should_receive(:authenticate).with("root", "root").and_return(@mock_user)

      post_login

      assigns(:user).should == @mock_user
    end

    it "should store the user attributes into the session" do
      post_login
      session[:user].should == @attributes.merge(:live_server_groups => [])
    end

    it "should redirect to the return_to param if login was successful" do
      post_login("return_to" => "/asdf")
      response.should redirect_to("/asdf")
    end

    it "should redirect to the profile page if login was successful and no return_to param was given" do
      post_login
      response.should redirect_to("/user/profile")

      post_login("return_to" => "")
      response.should redirect_to("/user/profile")
    end

  end

  describe "and the user's credentials are invalid" do

    before do
      Infopark::Crm::Contact.stub(:authenticate).
        and_raise(Infopark::Crm::Errors::AuthenticationFailed.new(""))
    end

    it 'should not log the user in' do
      post_login

      response.cookies["authentication"].should be_nil
    end

    it 'should inform the user that the login was unsuccessful' do
      post_login

      flash.now[:error].should_not be_nil
    end

    it 'should render the login page' do
      post_login

      response.should render_template('login')
    end

    it "should not preset the password field" do
      post_login

      assigns(:user).password.should be_nil
    end

  end

  describe "and the user exists but has no roles" do

    before do
      Infopark::Crm::Contact.stub(:authenticate).and_return nil
    end

    it 'should not log the user in' do
      post_login

      response.cookies["authentication"].should be_nil
    end

    it 'should inform the user that the login was unsuccessful' do
      post_login
      assigns(:user).should be_nil
      flash.now[:error].should_not be_nil
    end

    it 'should render the login page' do
      post_login

      response.should render_template('login')
    end

  end

  it "should raise an error if the crm cannot be reached (for any reason)" do
    CRM_ERRORS.each do |error|
      Infopark::Crm::Contact.should_receive(:authenticate).and_raise(error.new("error"))
      lambda { post_login }.should raise_error(error)
    end

    response.cookies["authentication"].should be_nil
  end

end

describe UserController, "when logging out" do

  before do
    session[:user] = {:id => 123}
  end

  it "should remove the user's id from the session" do
    session[:user][:id].should == 123
    get 'logout'
    session[:user].should be_nil
  end

  it "should redirect to the return_to param was given" do
    get 'logout', :return_to => "/asdf"
    response.should redirect_to("/asdf")
  end

  it "should redirect to the homepage if no return_to param was given" do
    get 'logout'
    response.should redirect_to(root_path)

    get 'logout', :return_to => ""
    response.should redirect_to(root_path)
  end


end

describe UserController, "creating a new user" do

  before do
    @user = Infopark::Crm::Contact.new(:email => 'bob@example.com')
    Infopark::Crm::Contact.stub(:new).and_return(@user)

    @user.stub(:password_request)
    @user.stub(:save!)
    @user.stub(:create_registration_request).and_return(
      @inquiry = mock('Inquiry', :save => true, :valid? => true)
    )
    controller.stub(:validate_recap).and_return(true)

    ConfirmationMailer.stub(:register_confirmation).and_return(mock({:deliver => nil}))
  end

  it "should render the new user view" do
    get 'new'
    response.should render_template("new")
  end

  it "should assign an empty contact to the view" do
    get 'new'
    assigns(:user).should be_a(Infopark::Crm::Contact)
  end

  describe "validating captcha" do

    it 'should not flash if captcha is correct' do
      controller.should_receive(:validate_recap).and_return(true)
      post_new

      flash.now[:error].should be_nil
    end

    it 'should flash if captcha is incorrect' do
      controller.should_receive(:validate_recap).and_return(false)
      post_new

      flash.now[:error].should_not be_nil
    end

    it 'should skip validation if configured to do so' do
      CurrentUserConfiguration.stub(:use_recaptcha_on_user_registration).and_return(false)
      controller.should_not_receive(:validate_recap)
      post_new
    end

  end

  it "should set the WebCRM language to the current locale" do
    I18n.stub(:locale).and_return(:hi)

    lambda {
      get "new"
    }.should change { Infopark::Crm::Configuration.locale.to_s }.from('en').to('hi')
  end

  it 'should create Contacts with default attributes' do
    @user.should_receive(:load).with(RailsConnector::Crm::CONTACT_DEFAULT_ATTRS)
    post 'new'
  end

  it 'should create Contacts with default attributes merged with POST params' do
    merged_attributes = RailsConnector::Crm::CONTACT_DEFAULT_ATTRS.merge(
        "email" => 'bob@example.com')
    @user.should_receive(:load).with(merged_attributes)
    post_new(@user.attributes)
  end

  it 'should force the presence of an e-mail address' do
    post_new("email" => '')

    assigns(:user).should have(1).error
    assigns(:user).errors[:base].to_s.should =~ /e-mail/i
    response.should render_template("new")
  end

  describe "Registration" do

    before do
      Infopark::Crm::Contact.stub(:new).and_return(@user)
    end

    it "should create an user and display a flash message" do
      @user.should_receive(:save!)

      post_new(@user.attributes)

      flash[:notice].should_not be_empty
    end

    it "should set the login to email" do
      @user.should_receive(:login=).with(@user.email)

      post_new(@user.attributes)
    end

    it "should send a confirmation email" do
      controller.stub(:set_password_url_for).and_return("http://confirmationurl")
      mailer = mock(ConfirmationMailer)
      ConfirmationMailer.should_receive(:register_confirmation).with(
          "bob@example.com", "http://confirmationurl").and_return(mailer)
      mailer.should_receive(:deliver)
      post_new(@user.attributes)
    end
  end

  it "should ignore arbitrary user attributes" do
    Infopark::Crm::Contact.stub(:new).and_return(@user)

    post_new(@user.attributes.merge(:want_snailmail => 'my value'))
    @user.attributes['want_snailmail'].should_not == 'my value'
  end

  it "should raise an error if the crm cannot be reached (for any reason)" do
    CRM_ERRORS.each do |error|
      Infopark::Crm::Contact.should_receive(:new).and_raise(error.new("error"))
      lambda { post_new(@user.attributes) }.should raise_error(error)
    end
  end

end

describe UserController, "editing the users base data" do

  before do
    @attributes = {:id => 12, :login => 'john', :first_name => 'John', :last_name => 'Smith', :email => 'john@smith.com'}
    @user = Infopark::Crm::Contact.new(@attributes)
    Infopark::Crm::Contact.stub(:find).and_return(@user)
    @user.stub(:save)
    controller.stub(:current_user).and_return(@user)
    controller.stub(:logged_in?).and_return(true)
  end

  it "should render the edit user view" do
    get 'edit'
    response.should render_template("edit")
  end

  it "should redirect to login if the user is not logged in" do
    controller.stub(:logged_in?).and_return(false)
    get 'edit'

    response.should redirect_to(login_path)
  end

  it "should reload the current user and assign it" do
    Infopark::Crm::Contact.should_receive(:find).with(12).and_return(
      @mock_user_reloaded = mock("Reloaded User")
    )
    get 'edit'

    assigns(:user).should == @mock_user_reloaded
  end

  it "should update the current user with the POST params" do
    updated_attributes = {
      :first_name => 'new John',
      :last_name => 'new Smith',
      :email => 'new john@smith.com'
    }.stringify_keys

    post 'edit', :user => updated_attributes
    assigns(:user).attributes.should include(updated_attributes)
  end

  it "should save the current user with the updated attributes" do
    updated_attributes = {:email => 'new john@smith.com'}.stringify_keys
    @user.should_receive(:load).with(updated_attributes)
    @user.should_receive(:save)

    post 'edit', :user => updated_attributes
    flash[:notice].should_not be_nil
  end

  it "should redirect to profile after updating the the user attributes" do
    post 'edit', :user => {:email => 'mail@test.de'}
    response.should redirect_to(:action => 'profile')
  end

  it "should ignore arbitrary user attributes" do
    @user.should_receive(:load).with(hash_not_including(:login => 'bobby'))

    post 'edit', :user => {:login => 'bobby'}
  end

  it "should display an error if the users input is invalid" do
    @user.stub(:save).and_raise(ActiveResource::ResourceInvalid.new("invalid"))
    post 'edit', :user => {:email => 'bob@example.com'}
    flash.now[:error].should_not be_nil
  end

  it "should raise an error if the crm cannot be reached (for any reason)" do
    CRM_ERRORS.each do |error|
      Infopark::Crm::Contact.should_receive(:find).and_raise(error.new("error"))
      lambda { post 'edit', :user => {:email => 'bob@example.com'} }.should raise_error(error)
    end
  end

end

describe UserController, "editing the users password" do

  before do
    @user = Infopark::Crm::Contact.new({:login => 'joe'})
    @user.stub(:password_set)
    Infopark::Crm::Contact.stub(:authenticate).and_return(@user)
    controller.stub(:current_user).and_return(@user)
    controller.stub(:logged_in?).and_return(true)

    @regular_password_params = {
      :old_password => "old", :new_password => "new", :new_password_confirm => "new"
    }
  end

  it "should render the edit password view" do
    get 'edit_password'
    response.should render_template("edit_password")
  end

  it "should redirect to login if the user is not logged in" do
    controller.stub(:logged_in?).and_return(false)
    get 'edit_password'

    response.should redirect_to(login_path)
  end

  it "should display an error if new password is empty" do
    @user.should_not_receive(:password_set)
    post 'edit_password', :user => {:old_password => "old", :new_password => ""}

    flash.now[:error].should_not be_nil
  end

  it "should display an error if new password does not match confirmation" do
    @user.should_not_receive(:password_set)
    post 'edit_password', :user => {:new_password => "new", :new_password_confirm => "new2"}

    flash.now[:error].should_not be_nil
  end

  it "should contact the crm to change the password" do
    user = mock(Infopark::Crm::Contact)
    Infopark::Crm::Contact.should_receive(:authenticate).with('joe', 'old').and_return(user)
    user.should_receive(:password_set).with("new")
    post 'edit_password', :user => @regular_password_params
  end

  it "should display a notice after changing the pasword" do
    post 'edit_password', :user => @regular_password_params

    flash[:notice].should_not be_empty
  end

  it "should redirect to profile after changing the password" do
    post 'edit_password', :user => @regular_password_params

    response.should redirect_to(:action => 'profile')
  end

  describe "if the users input is invalid" do
    before do
      @user.stub(:password_set).and_raise(ActiveResource::ResourceInvalid.new("invalid"))
    end

    it "should display an error" do
      post 'edit_password', :user => @regular_password_params
      flash.now[:error].should_not be_nil
    end
  end

  describe "if the users current password is invalid" do
    before do
      Infopark::Crm::Contact.stub(:authenticate).and_raise(
          Infopark::Crm::Errors::AuthenticationFailed)
    end

    it "should display an error" do
      post 'edit_password', :user => @regular_password_params
      flash.now[:error].should_not be_nil
    end
  end

  it "should raise an error if the crm cannot be reached (for any reason)" do
    CRM_ERRORS.each do |error|
      @user.should_receive(:password_set).and_raise(error.new("error"))
      lambda {
        post 'edit_password', :user => {:old_password => "old", :new_password => "new", :new_password_confirm => "new"}
      }.should raise_error(error)
    end
  end

end

describe UserController, "supporting users who forgot their password" do

  before do
    @user = Infopark::Crm::Contact.new({:login => "john", :email => "john@smith.com"})
    @user.stub(:password_request)
    Infopark::Crm::Contact.stub(:search).and_return([@user])

    ConfirmationMailer.stub(:reset_password).and_return(mock({:deliver => nil}))
  end

  it "should render the request password view" do
    get 'forgot_password'
    response.should render_template("forgot_password")
  end

  it "should display an error if the login does not exists" do
    Infopark::Crm::Contact.stub(:search).and_return([])
    post 'forgot_password', :user => {:login => 'foo'}

    flash.now[:error].should_not be_nil
  end

  it "should send an email to the user to confirm the request (double opt in)" do
    controller.stub(:set_password_url_for).and_return("http://confirmationurl")
    mailer = mock(ConfirmationMailer)
    ConfirmationMailer.should_receive(:reset_password).with(
        "john@smith.com", "http://confirmationurl").and_return(mailer)
    mailer.should_receive(:deliver)
    post 'forgot_password', :user => {:login => 'foo'}
  end

  it "should display a message if the login exists" do
    post 'forgot_password', :user => {:login => 'foo'}

    flash[:notice].should_not be_empty
  end

  it "should redirect to self after resetting password" do
    post 'forgot_password', :user => {:login => 'foo'}

    response.should redirect_to(:action => 'forgot_password')
  end

  it "should raise an error if the crm cannot be reached (for any reason)" do
    CRM_ERRORS.each do |error|
      Infopark::Crm::Contact.should_receive(:search).and_raise(error.new("error"))
      lambda { post 'forgot_password', :user => {:login => 'foo'} }.should raise_error(error)
    end
  end

end

describe UserController, "returning a URL to set the password" do

  it "should contain the corresponding action and code parameter created by LinkTool" do
    user = Infopark::Crm::Contact.new(:id => 123)
    user.should_receive(:password_request).and_return('secret')
    controller.should_receive(:url_for).with(:action => 'set_password',
        :token => 'secret').and_return('http://my_confirmation_url')

    controller.send(:set_password_url_for, user).should == 'http://my_confirmation_url'
  end

end

describe UserController, ".set_password" do

  context 'when rendering the form' do
    render_views

    it "should render the request password confirmation view" do
      get 'set_password'
      response.should render_template("set_password")
    end

    it "should render a hidden field with the token" do
      get 'set_password', :token => 'some_token'
      response.body.should have_tag("form input[type=hidden][id=user_token][value=some_token]")
    end

    it "should not contact the CRM" do
      Infopark::Crm::Contact.should_not_receive(:password_set)
      get 'set_password', :token => 'some_token'
    end

    it "should display an error if the token param is empty" do
      get 'set_password'
      flash.now[:error].should_not be_nil
    end
  end

  context 'when processing the form' do
    it 'should not contact the CRM without password' do
      Infopark::Crm::Contact.should_not_receive(:password_set)
      post 'set_password', :user => {:token => 'my_token'}
    end

    it 'should not contact the CRM with wrong password confirmation' do
      Infopark::Crm::Contact.should_not_receive(:password_set)
      post 'set_password', :user => {:token => 'my_token', :new_password => 'new',
          :new_password_confirm => 'new2'}
    end

    it 'should contact the CRM with the given token' do
      Infopark::Crm::Contact.should_receive(:password_set).with('new', 'my_token')
      post 'set_password', :user => {:token => 'my_token', :new_password => 'new',
          :new_password_confirm => 'new'}
    end

    it "should raise an error if the crm cannot be reached (for any reason)" do
      CRM_ERRORS.each do |error|
        Infopark::Crm::Contact.should_receive(:password_set).and_raise(error.new("error"))
        lambda {
          post 'set_password', :user => {:token => 'my_token', :new_password => 'new',
              :new_password_confirm => 'new'}
        }.should raise_error(error)
      end
    end
  end
end

describe UserController, "callbacks" do

  it 'should not be exposed as controller actions' do
    RailsConnector::Crm::Callbacks.instance_methods.each do |method|
      lambda { get method }.should raise_error(/Unknown action/)
    end
  end

  describe "when an crm error occurs" do
    before do
      controller.stub(:new).and_raise CRM_ERRORS.first.new("test error message")
    end

    it "should send the on_crm_error callback" do
      controller.should_receive(:on_crm_error)
      get :new
    end

    it "should be reraised when the default implementation of on_crm_error is in place" do
      lambda { get :new }.should raise_error(CRM_ERRORS.first)
    end

    it "should be rescued when on_crm_error is replaced by a non-reraising version" do
      controller.stub(:on_crm_error)
      lambda { get :new }.should_not raise_error
    end

    it "should render the default view when on_crm_error does not perform a render or redirect" do
      controller.stub(:on_crm_error)

      get :new
      response.should render_template("user/new")
    end

    it "should allow on_crm_error to render a different view" do
      controller.stub(:on_crm_error) do
        controller.__send__("render", :error)
      end

      get :new
      response.should render_template("user/error")
    end

    it "should allow on_crm_error to redirect" do
      controller.stub(:on_crm_error) do
        controller.__send__("redirect_to", "/")
      end

      get :new
      response.should redirect_to("/")
    end
  end

  describe "before and after authenticate" do

    it "should not be sent at all when request is GET" do
      controller.should_not_receive(:before_authenticate)
      controller.should_not_receive(:after_authenticate)
      get :login
    end

    it "should not be sent both when authentication fails" do
      controller.should_receive(:before_authenticate).once.ordered
      Infopark::Crm::Contact.should_receive(:authenticate).once.ordered
      controller.should_not_receive(:after_authenticate)
      post_login
    end

    it "should be sent in the correct order on POST if user is authenticated" do
      controller.should_receive(:before_authenticate).once.ordered
      Infopark::Crm::Contact.should_receive(:authenticate).once.ordered.and_return(user = mock('User'))
      user.stub(:password=)
      controller.should_receive(:after_authenticate).once.ordered
      controller.stub(:session_attributes_for)
      post_login
    end

  end

  describe "before and after logout" do

    it "should be sent in the correct order (before and after session resetting)" do
      controller.should_receive(:before_logout).once.ordered
      controller.should_receive(:session).any_number_of_times.ordered.and_return({})
      controller.should_receive(:after_logout).once.ordered
      get :logout
    end

  end

  describe "before and after registration" do

    before do
      ConfirmationMailer.stub(:register_confirmation).and_return(mock({:deliver => nil}))
      ConfirmationMailer.stub(:reset_password).and_return(mock({:deliver => nil}))
    end

    it "should not be called on GET requests" do
      controller.should_not_receive(:validate_recap)
      controller.should_not_receive(:before_register)
      controller.should_not_receive(:after_register)
      get :new
    end

    it 'should not be called when captcha is incorrect' do
      controller.should_receive(:validate_recap).and_return(false)
      controller.should_not_receive(:before_register)
      controller.should_not_receive(:after_register)
      post_new
    end

    it "calls callbacks in the correct order" do
      controller.should_receive(:validate_recap).and_return(true)
      controller.should_receive(:before_register).once.ordered
      controller.should_receive(:after_register).once.ordered
      Infopark::Crm::Contact.any_instance.stub(:save!)
      Infopark::Crm::Contact.any_instance.stub(:password_request)

      post 'new', :user => {:email => 'bob@bar.de'}
    end

  end

end

describe UserController, 'checking for reCaptcha keypair' do


  it 'should return true if both keys are set' do
    Object.should_receive(:const_defined?).twice.and_return(true)
    controller.send(:check_recaptcha_keypair).should be_true
  end

  it 'should raise an error if public key is not set' do
    Object.should_receive(:const_defined?).with(:RCC_PUB).and_return(false)
    lambda { controller.send(:check_recaptcha_keypair) }.should raise_error(RuntimeError, /reCaptcha requires the constants RCC_PUB and RCC_PRIV to be set/)
  end

  it 'should raise an error if private key is not set' do
    Object.stub(:const_defined?).with(:RCC_PUB).and_return(true)
    Object.stub(:const_defined?).with(:RCC_PRIV).and_return(false)
    lambda { controller.send(:check_recaptcha_keypair) }.should raise_error(RuntimeError, /reCaptcha requires the constants RCC_PUB and RCC_PRIV to be set/)
  end

  it 'should skip the check if configured to do so' do
    Object.stub(:const_defined?).with(:RCC_PUB).and_return(false)
    CurrentUserConfiguration.stub(:use_recaptcha_on_user_registration).and_return(false)
    controller.send(:check_recaptcha_keypair).should be_true
  end

end

describe UserController, 'customizing session attributes' do
  let(:user) do
    mock('Contact', :attributes => {'my_field' => 'what', 'id' => 123}, :live_server_groups => [])
  end

  before(:all) do
    CurrentUserConfiguration.store_user_attrs_in_session = [:my_field]
  end

  subject { CustomController.new }

  it "should raise an error if using old API" do
    lambda do
      UserController.store_user_attrs_in_session = [:foo, :bar]
    end.should raise_error(RuntimeError, /use CurrentUserConfiguration.store_user_attrs_in_session/)
  end

  it 'should store my_field in the session' do
    controller.send(:session_attributes_for, user)[:my_field].should == 'what'
  end

  it 'should always include the contact ID' do
    controller.send(:session_attributes_for, user)[:id].should == 123
  end
end

describe UserController, "profile" do

  before do
    controller.stub(:logged_in?).and_return(true)
  end

  it "should render the profile view" do
    get 'profile'
    response.should render_template("profile")
  end

end

describe UserController, "where editable_attributes does not contain required keys" do
  before do
    @stash = UserController.editable_attributes_on_register
    UserController.editable_attributes_on_register = ["foo", "bar"]
  end

  after do
    UserController.editable_attributes_on_register = @stash
  end

  it "should raise an error" do
    lambda { get "login" }.should raise_error(
      RailsConnector::ConfigurationError,
      "editable_attributes in UserController is not configured correctly"
    )
  end
end
