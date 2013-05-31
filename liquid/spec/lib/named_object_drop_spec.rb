require "spec_helper"

module RailsConnector::LiquidSupport

  describe NamedObjectDrop do

    before do
      initialize_action_view_and_obj
      RailsConnector::Configuration.auto_liquid_editmarkers = false
    end

    it "should give access to the Objs referenced by NamedLinks" do
      @obj.stub_attrs!(:title => "Foo Title")
      RailsConnector::NamedLink.stub(:get_object).with("foo_object_name").and_return(@obj)

      render_liquid('{{ named_object["foo_object_name"].title }}').should == "Foo Title"
    end

    it "should be a singleton (for performance reasons)" do
      # Damit nicht bei jedem Rendern eine neue Instanz des NamedObjectDrop
      # angelegt und danach garbage-collected werden muss
      lambda { NamedObjectDrop.new }.should raise_error(NoMethodError, /private method/)
    end

  end

end