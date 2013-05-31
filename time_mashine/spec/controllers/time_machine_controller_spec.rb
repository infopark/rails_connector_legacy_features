require "spec_helper"

module RailsConnector
  describe TimeMachineController, "(Routing)" do
    it "should be active when the timemachine and the editor interface is enabled" do
      Configuration.stub(:enabled?).and_return(true)
      Configuration.stub(:editor_interface_enabled?).and_return(true)
      reload_routes_for_this_test
      {:get => time_machine_path}.should route_to(
          :controller => "rails_connector/time_machine", :action => "index")
    end

    it "should not be active when the timemachine is disabled" do
      Configuration.stub(:enabled?).and_return(false)
      Configuration.stub(:editor_interface_enabled?).and_return(true)
      reload_routes_for_this_test
      {:get => "/time_machine/index"}.should_not route_to(
          :controller => "rails_connector/time_machine", :action => "index")
    end

    it "should not be active when the editor interface is disabled" do
      Configuration.stub(:enabled?).and_return(true)
      Configuration.stub(:editor_interface_enabled?).and_return(false)
      reload_routes_for_this_test
      {:get => "/time_machine/index"}.should_not route_to(
          :controller => "rails_connector/time_machine", :action => "index")
    end
  end

  describe TimeMachineController, "when showing the editor interface" do

    before do
      Configuration.stub(:editor_interface_enabled?).and_return(true)
      reload_routes_for_this_test
    end

    describe "receiving an index request" do
      it "should render the view" do
        get 'index'
        response.should render_template("index")
      end

      it "should set the default language" do
        get 'index'
        assigns[:language].should == 'de'
      end

      it "should restore the preview time from the session" do
        @some_time = 2.days.ago
        session[:preview_time] = @some_time
        get 'index'
        assigns[:preview_time].should == @some_time
      end

      it "should use Time.now when no preview time is stored in the session" do
        @some_time = 2.days.ago
        Time.stub(:now).and_return(@some_time)
        session[:preview_time] = nil
        get 'index'
        assigns[:preview_time].should == @some_time
      end
    end

    describe "receiving an index request with parameters" do
      it "should set the language from request" do
        get 'index', :language => 'en'
        assigns[:language].should == 'en'
      end
    end

    describe "receiving a set request with preview time" do

      it "should respond with javascript reload for an AJAX request" do
        xhr :post, :set_preview_time, :preview_time => '20071011121314'
        response.should be_success
        response.body.should == "window.location.reload();"
        response.headers['Content-Type'].should =~ /^text\/javascript/
      end

      it "should respond empty success for other request" do
        post :set_preview_time, :preview_time => '20071011121314'
        response.should be_success
        response.body.should be_blank
      end

      it "should store the preview time in the session for an AJAX request" do
        preview_time = 1.year.from_now
        xhr :post, :set_preview_time, :preview_time => preview_time.to_iso
        session[:preview_time].should == Time.from_iso(preview_time.to_iso)
      end

      it "should store the preview time in the session" do
        preview_time = 1.year.from_now
        post :set_preview_time, :preview_time => preview_time.to_iso
        session[:preview_time].should == Time.from_iso(preview_time.to_iso)
      end

      it "should clear the preview time from the session for a date in the past" do
        preview_time = -1.day.from_now
        post :set_preview_time, :preview_time => preview_time.to_iso
        session[:preview_time].should be_nil
      end

    end

    describe "receiving a reset request" do

      it "should clear the preview time from the session" do
        session[:preview_time] = Time.now
        post :reset_preview_time
        session[:preview_time].should be_nil
      end

      it "should respond with javascript reload for an AJAX request" do
        xhr :post, :reset_preview_time
        response.should be_success
        response.body.should == "window.location.reload();"
        response.headers['Content-Type'].should =~ /^text\/javascript/
      end

      it "should respond empty success for other request" do
        post :reset_preview_time
        response.should be_success
        response.body.should be_blank
      end
    end

  end

  describe TimeMachineController,
    "when not showing editor interface but controller is somehow accessible" do

    before do
      # load routing with editor interface enabled, so time machine controller is accessible
      Configuration.stub(:editor_interface_enabled?).and_return(true)
      reload_routes_for_this_test

      Configuration.stub(:editor_interface_enabled?).and_return(false)
    end

    it "should not allow any get requests" do
      get 'index'
      response.should render_template("errors/403_forbidden")
    end

    it "should not allow any ajax requests" do
      xhr :post, :set_preview_time
      response.should render_template("errors/403_forbidden")
    end

    it "should not allow any post requests" do
      post :reset_preview_time
      response.should render_template("errors/403_forbidden")
    end

  end

end