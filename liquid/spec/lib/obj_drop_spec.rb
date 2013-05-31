require "spec_helper"

module RailsConnector::LiquidSupport
  describe ObjDrop do
    before do
      initialize_action_view_and_obj

      @obj.stub_attrs!(:title => "Page Title")
      @obj_drop = ObjDrop.new(@obj)
      @obj_drop.instance_variable_set(:@context, mock("Context", :registers => {:action_view => @action_view}))
    end

    it "should return the field value wrapped in a FieldValueDrop" do
      @obj_drop.invoke_drop(:title).should be_kind_of(FieldValueDrop)
    end

    it "should set the correct obj for the FieldValueDrop" do
      @obj_drop.invoke_drop(:title).instance_variable_get(:@obj).should == @obj
    end

    it "should set the correct field for the FieldValueDrop"  do
      @obj_drop.invoke_drop(:title).instance_variable_get(:@field).should == :title
    end

    it "should set the correct value for the FieldValueDrop" do
      @obj_drop.invoke_drop(:title).__value.should == "Page Title"
    end

    it "should enable an edit marker by default" do
      RailsConnector::Configuration.auto_liquid_editmarkers = true
      @obj_drop.invoke_drop(:title).__marker.should be_true
    end

    it "should not render an edit marker if the Configuration.auto_liquid_editmarkers is false" do
      RailsConnector::Configuration.auto_liquid_editmarkers = false
      @obj_drop.invoke_drop(:title).__marker.should be_false
    end
  end
end
