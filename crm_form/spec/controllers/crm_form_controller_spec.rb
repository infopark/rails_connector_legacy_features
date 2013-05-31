require 'spec_helper'

describe CrmFormController do

  let(:mock_activity) do
    mock('Activity',
      :custom_attributes => [mock(:name => 'phone'), mock(:name => 'email')],
      :load => nil,
      :save => true,
      :contact_id= => nil,
      :valid? => true
    )
  end
  let(:mock_user) do
    mock('User',
      :email => 'jd@example.com',
      :load => nil,
      :save! => true,
      :id => '1337'
    )
  end

  before do
    @obj = CrmForm.new
    @obj.stub_attrs!(:activity_kind => nil)
    request.for_cms_object(@obj)

    controller.stub(:ensure_object_is_active).and_return(true)
    controller.stub(:ensure_object_is_permitted).and_return(true)
    controller.stub(:enable_gui_to_update_its_menu_selection_in_preview_mode).and_return(true)
    controller.stub(:set_google_expire_header)
    controller.stub(:logged_in?).and_return(true)
    controller.stub(:current_user).and_return(mock_user)
    controller.stub(:activity_state).and_return('created')

    Infopark::Crm::Activity.stub(:new).and_return(mock_activity)
  end

  describe 'rendering a form' do
    it "renders the new form view" do
      get 'index'
      response.should render_template("crm_form/index")
    end

    it "should set the CRM language to the current locale" do
      I18n.stub(:locale).and_return(:hi)

      lambda {
        get "index"
      }.should change { Infopark::Crm::Configuration.locale.to_s }.from('en').to('hi')
    end

    it "defaults to the attribute :activity_kind" do
      @obj.stub_attrs!(:activity_kind => 'asdf')
      Infopark::Crm::Activity.should_receive(:new).with({:kind => 'asdf',
          :state => 'created'}).and_return(mock_activity)
      get 'index'
    end

    it "falls back to activity kind 'contact form'" do
      Infopark::Crm::Activity.should_receive(:new).with({:kind => 'contact form',
          :state => 'created'}).and_return(mock_activity)
      get 'index'
    end

    it "assigns the activity as @activity" do
      Infopark::Crm::Activity.should_receive(:new).and_return(mock_activity)
      get 'index'
      assigns[:activity].should == mock_activity
    end

    describe "customizing the activity kind and state" do
      it "works when overriding the 'activity_kind' method" do
        def controller.activity_kind
          'custom activity kind'
        end
        def controller.activity_state
          'custom state'
        end

        Infopark::Crm::Activity.should_receive(:new).with({:kind => 'custom activity kind',
            :state => 'custom state'})
        get 'index'
      end
    end

    describe "when not logged in" do
      before do
        controller.should_receive(:logged_in?).and_return(false)
        Infopark::Crm::Activity.should_not_receive(:new)
      end

      it "renders another template when not logged in" do
        get 'index'
        response.should render_template('not_logged_in')
      end

      describe "customizing the behavior when not logged in" do
        it "works when overriding the 'authorize' method" do
          def controller.authorize
            redirect_to '/' unless logged_in?
          end

          get 'index'
          response.should redirect_to('/')
        end
      end
    end

    describe "allowing anonymous use" do
      it "renders the form, not the warning" do
        def controller.allow_anonymous?
          true
        end

        controller.stub!(:logged_in?).and_return(false)

        get 'index'
        response.should_not render_template('not_logged_in')
      end
    end

    describe "overriding editable_attributes_on_register in a subclass" do
      it "returns the customized editable attributes" do
        def controller.editable_attributes_on_register
          {:contact => [:email]}
        end

        controller.__send__(:editable_attributes_on_register)[:contact].should have(1).item
      end

    end
  end

  describe 'POSTing the form' do
    it "should set the CRM language to the current locale" do
      I18n.stub(:locale).and_return(:hi)

      lambda {
        post "index"
      }.should change { Infopark::Crm::Configuration.locale.to_s }.from('en').to('hi')
    end

    it 'saves the activity' do
      mock_activity.should_receive(:save)
      post 'index'
    end

    describe "customizing the activity before saving" do
      it "works when overriding the 'before_saving_activity' method" do
        def controller.before_saving_activity(activity)
          activity.change_slightly
        end

        mock_activity.should_receive(:change_slightly)
        post 'index'
      end
    end

    it 'prevents setting arbitrary activity properties' do
      mock_activity.should_receive(:load).with({'custom_phone' => '123', 'title' => 'Payment'})
      post 'index', :activity => {'kind' => 'invoice', 'state' => 'paid', 'evil' => 'yes',
          'custom_phone' => '123', 'title' => 'Payment'}
    end

    describe "customizing the activity before saving" do
      it "works when overriding the 'sanitize_activity_params' method" do
        def controller.sanitize_activity_params(params)
          params.reject{|attr, value| attr == "not_allowed" }
        end
        mock_activity.should_receive(:load).with({'allowed' => 'WOHOO'})
        post 'index', :activity => {'allowed' => 'WOHOO', 'not_allowed' => 'Bah'}
      end
    end

    describe "allowing/denying custom attributes" do
      it 'is enforced' do
        def controller.allow_custom_attribute?(attribute_name)
          attribute_name == "custom_phone"
        end

        mock_activity.should_receive(:load).with({"custom_phone" => '123'})
        post 'index', :activity => {"custom_phone" => '123', "custom_email" => 'a@b'}
      end
    end

    it 'saves the activity with the given parameters' do
      mock_activity.should_receive(:load).with(hash_including({"custom_phone" => '123', "custom_email" => 'a@b'}))
      post 'index', :activity => {"custom_phone" => '123', "custom_email" => 'a@b'}
    end

    it 'renders an error message' do
      mock_activity.should_receive(:valid?).and_return(false)
      post 'index'
      flash.now[:error].should_not be_nil
    end

    it 'renders the confirmation view by default after saving' do
      post 'index'
      response.should render_template("crm_form/confirmation")
    end

    it 'does not render the confirmation view when save failed' do
      mock_activity.should_receive(:valid?).and_return(false)
      post 'index'
      response.should_not render_template("crm_form/confirmation")
    end

    it 'declares helper methods' do
      controller.class.helpers.should respond_to(:has_title_input_field?)
      controller.class.helpers.should respond_to(:allow_anonymous?)
      controller.class.helpers.should respond_to(:allow_custom_attribute?)
      controller.class.helpers.should respond_to(:editable_attributes_on_register)
    end

    describe "customizing the activity after saving" do
      it "works when overriding 'after_saving_activity' save succeeded" do
        def controller.after_saving_activity(activity)
          activity.render_some_confirmation
        end

        mock_activity.should_receive(:render_some_confirmation)
        post 'index'
      end

      it "does not work when overriding 'after_saving_activity' but saved failed" do
        mock_activity.should_receive(:valid?).and_return(false)
        mock_activity.should_not_receive(:render_some_confirmation)
        post 'index'
      end
    end

    describe "using the default title" do
      it 'assigns a default title' do
        def controller.has_title_input_field?; false; end
        mock_activity.should_receive(:title=).with(instance_of(String))
        post 'index'
      end
    end

    it "sets the activity's contact ID if user is logged in" do
      controller.should_receive(:logged_in?).and_return(true)
      controller.should_receive(:current_user).and_return(Infopark::Crm::Contact.new(:id => 123))
      mock_activity.should_receive(:contact_id=).with(123)
      mock_activity.should_receive(:save)
      post 'index'
    end

    describe "when not logged in" do
      before { controller.stub!(:logged_in?).and_return(false) }

      it "does not save the activity" do
        mock_activity.should_not_receive(:contact_id=).with(123)
        mock_activity.should_not_receive(:save)
        post 'index'
      end

      it 'does not create a contact' do
        Infopark::Crm::Contact.any_instance.should_not_receive(:save)
        post 'index'
      end

      it "renders a warning" do
        post 'index'
        response.should render_template('not_logged_in')
      end

      describe "and anonymous use is allowed " do

        before do
          def controller.allow_anonymous?
            true
          end
          Infopark::Crm::Contact.any_instance.stub(:save!)
        end

        let(:user_attrs) do
          {"first_name" => 'John', "last_name" => 'Doe', "email" => "john.doe@example.com"}
        end

        it "creates an activity" do
          Infopark::Crm::Activity.should_receive(:new).with(hash_including(:kind, :state))
          post 'index', :user => user_attrs
        end

        it "sets the activity's contact_id to the email from the registration info" do
          Infopark::Crm::Contact.should_receive(:new).and_return(mock_user)
          mock_activity.should_receive(:contact_id=).with('1337')
          mock_activity.should_receive(:save)
          post 'index', :user => user_attrs
        end

        it "should ignore arbitrary user attributes" do
          post 'index', :user => user_attrs.merge(:want_snailmail => 'my value')
          assigns[:user].attributes['want_snailmail'].should_not == 'my value'
          assigns[:user].attributes['first_name'].should == 'John'
        end

        it 'forces the presence of an e-mail address' do
          post 'index', :user => user_attrs.merge("email" => '')

          response.should render_template("index")
          assigns[:user].errors[:email].first.should match(/blank/)
          flash.now[:error].should_not be_nil
        end
      end
    end
  end
end