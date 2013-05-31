# encoding: utf-8

require "spec_helper"

module RailsConnector

  class ControllerWithCrmAuth < ApplicationController

    include Crm::AuthenticationSupport
  end

  describe Crm, "enable" do

    it "should extend the application controller with the crm authentication module" do
      ApplicationController.should_receive(:include).with(Crm::AuthenticationSupport)
      DefaultCmsController.stub(:include)
      Crm.enable
    end

    it "should declare helper methods" do
      Crm.enable
      ApplicationController.helpers.should respond_to(:logged_in?, :current_user, :admin?)
    end

    it "should declare helper methods as protected" do
      Crm.enable
      ApplicationController.protected_instance_methods.map(&:to_s).should include("logged_in?", "current_user", "admin?")
    end

  end


  describe ControllerWithCrmAuth, :type => :controller do
    describe "logged_in?" do

      it "should return true if the user is logged in" do
        session[:user] = {:id => 123}
        controller.send(:logged_in?).should be_true
      end

      it "should return false if the user is logged out" do
        session[:user] = nil
        controller.send(:logged_in?).should be_false
      end

    end

    describe "current_user" do
      before(:all) do
        CurrentUserConfiguration.store_user_attrs_in_session = [:name]
      end

      describe 'setting live_server_groups' do
        it 'should be done separately' do
          attributes = {:live_server_groups => ['editors']}
          session[:user] = attributes

          current_user = controller.send(:current_user)
          current_user.live_server_groups.should == ['editors']
        end

        it 'should not mess with the session' do
          attributes = {:live_server_groups => ['editors']}
          session[:user] = attributes.dup

          current_user = controller.send(:current_user)
          session[:user].should == attributes
        end
      end

      it "should return the currently logged in user" do
        attributes = {:id => 123, :name => "Bob", :email => "bob@example.com", :live_server_groups => ['editors']}
        session[:user] = attributes

        current_user = controller.send(:current_user)
        current_user.should == Infopark::Crm::Contact.new(attributes)
      end

      it "should return nil when no user is logged in" do
        session[:user] = nil

        controller.send(:current_user).should be_nil
      end

      it "should be writable" do
        google_user = Infopark::Crm::Contact.new({
          :id => 123,
          :name => "Googlebot",
          :email => "bot@google.com",
          :live_server_groups => []
        })
        session[:user] = {:name => 'Billy'}
        lambda {
          controller.send(:current_user=, google_user)
        }.should change { session[:user][:name] }.from("Billy").to("Googlebot")
        controller.send(:current_user).should == google_user
      end

      it "support being set to nil" do
        controller.send(:current_user=, nil)
        controller.send(:current_user).should be_nil
        session[:user].should be_nil
      end

      it "should be reloadable" do
        user = Infopark::Crm::Contact.new({:id => 123, :name => 'Billy', :live_server_groups => []})
        controller.send(:current_user=, user)
        user.should_receive(:reload) { user.name = "Bob"; nil }

        lambda {
          controller.send(:reload_current_user)
        }.should change { session[:user][:name] }.from("Billy").to("Bob")
        controller.send(:current_user).name.should == "Bob"
      end

      context 'when dealing with old stored data from ruby 1.8 in an ruby 1.9 env' do
        it 'should reload the user, when accessing current_user' do
          name = 'Böb'
          ruby18_string = if String.new.encoding_aware?
            Infopark::Crm::Contact.should_receive(:find).with(123).and_return(
                Infopark::Crm::Contact.new({:name => name}))

            name.dup.force_encoding('ASCII-8BIT')
          else
            name
          end
          session[:user] = {:id => 123, :name => ruby18_string, :attr1 => nil, :attr2 => []}

          controller.send(:current_user).name.should eq('Böb')
        end
      end
    end

    describe "admin?" do
      it "should return false by default" do
        controller.send(:admin?).should be_false
      end
    end

    describe "session_attributes_for(user)" do
      let(:user) do
        mock("User", :live_server_groups => %w(admins), :attributes => {
          "login" => "roger",
          "first_name" => "Clarence",
          "not_in_session" => "Oveur",
          "id" => 42,
        })
      end

      before do
        session = {}
        CurrentUserConfiguration.store_user_attrs_in_session = [:login, :first_name]
      end

      it "should return attributes defined by #store_user_attrs_in_session" do
        controller.send(:session_attributes_for, user).should include(:login => "roger",
            :first_name => "Clarence")
      end

      it "should always include the :id field independent on configurated fields" do
        controller.send(:session_attributes_for, user).should include(:id => 42)
      end

      it 'should always include live_server_groups' do
        controller.send(:session_attributes_for, user)[:live_server_groups].should == %w(admins)
      end
    end

  end

  describe Crm::Sanitization do

    include Crm::Sanitization

    let(:filter) do
      {:contact => [:name]}
    end
    let(:input) do
      {
        'name' => 'Fred', 'age' => 25,
      }
    end

    it 'should consult the given filter' do
      sanitize_user_params(input, filter).should == {
        'name' => 'Fred',
      }
    end
  end
end
