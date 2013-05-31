require "spec_helper"

module RailsConnector::LiquidSupport
  describe FieldValueDrop do
    before do
      initialize_action_view_and_obj
      @drop = FieldValueDrop.new(@obj, :title, "The Title", false)
      @drop.instance_variable_set(:@context, mock("Context", :registers => {:action_view => @action_view}))
    end

    describe "when the editor interface is enabled" do
      before { RailsConnector::Configuration.stub(:editor_interface_enabled? => true) }

      it "should render it's value" do
        @drop.to_s.should == "The Title"
      end

      it "should render it's value with an editmarkers when editmarkers are enabled" do
        @drop.__marker = true
        @drop.to_s.should have_tag("span", "The Title")
      end
    end

    describe "when the editor interface is disabled" do
      before { RailsConnector::Configuration.stub(:editor_interface_enabled? => false) }

      it "should render it's value without an editmarkers even when editmarkers are enabled" do
        @drop.to_s.should == "The Title"
      end
    end
  end
end
