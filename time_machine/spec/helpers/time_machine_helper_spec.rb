require "spec_helper"

module RailsConnector

  describe TimeMachineHelper do
    describe "when editor interface is enabled" do
      before do
        Configuration.stub(:editor_interface_enabled?).and_return(true)
      end
      describe "and the time machine is switched on" do
        before do
          Configuration.stub(:enabled?).with(:time_machine).and_return(true)
          helper.stub(:time_machine_url).and_return("/path/to/time_machine")
        end

        let(:html_safe_output) {
          helper.time_machine_link("Time Machine Link")
        }

        it_should_behave_like "an html safe helper"

        it "should render a link with the title provided" do
          helper.time_machine_link("Time Machine Link").should have_tag("a", "Time Machine Link")
        end

        it "should render a linked image if an image tag is provided" do
          helper.time_machine_link(image_tag("foo.png")).should have_tag("a img")
        end

        it "should call a javascript function when clicked which opens a window containing the time machine" do
          helper.time_machine_link("Time Machine Link").should =~ %r[window.open\(&#x27;/path/to/time_machine&#x27;]
        end

        it "should render some javascript which defines the function sendRequest" do
          helper.time_machine_link("Time Machine Link").should have_tag("script", /function sendRequest/)
        end
      end

      it "should render nothing when the time machine is switched off" do
        Configuration.should_receive(:enabled?).with(:time_machine).and_return(false)
        helper.time_machine_link("Time Machine Link").should == nil
      end
    end

    it "should render nothing when editor interface is disabled even when the time machine is switched on" do
      Configuration.stub(:editor_interface_enabled?).and_return(false)
      Configuration.stub(:enabled?).with(:time_machine).and_return(true)
      helper.time_machine_link("Time Machine Link").should == nil
    end
  end
end
