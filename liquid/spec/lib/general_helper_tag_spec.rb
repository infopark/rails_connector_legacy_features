# encoding: utf-8
require "spec_helper"

module RailsConnector::LiquidSupport
  describe GeneralHelperTag do
    before do
      initialize_action_view_and_obj
      RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(false)
    end

    it "should not work for unregistered helpers" do
      lambda { render_liquid('{% display foo %}') }.should raise_error(Liquid::SyntaxError, /unknown tag/i)
    end

    it "should forward parameters to the target helper" do
      GeneralHelperTag << 'display_value'
      render_liquid('{% display_value foo %}').should == 'foo'
    end

    describe "interpreting parameters" do
      before do
        @obj.stub_attrs!(:title => "Page Title")
        GeneralHelperTag << 'some_helper'
      end

      it "should recognize obj" do
        GeneralHelperTag << 'display_field'
        render_liquid('{% display_field obj title %}').should == 'Page Title'
      end

      it "should recognize method calls on obj" do
        @action_view.should_receive(:some_helper).with('Page Title').and_return('abc')
        render_liquid('{% some_helper obj.title %}').should == 'abc'
      end

      it "should work with link drops" do
        Obj.stub(:find).with([98]).and_return([
          @img1 = Obj.new.stub_attrs!(:id => 98, :title => "img1", :active? => true,
              :obj_class => 'Publication')
        ])
        @obj.stub_attrs!(
          :images => RailsConnector::LinkList.new([
            {:destination => 98, :title => "image 1"}
          ])
        )
        @action_view.should_receive(:some_helper).with(@img1).and_return('abc')
        render_liquid('{% some_helper obj.images[0] %}').should == 'abc'
      end

      it "should recognize quoted params" do
        @action_view.should_receive(:some_helper).
          with(@obj, "ip_valueAddImage", "[Bild für rechte Spalte auswählen]", "oha", "noch einer").
          and_return('abc')
        render_liquid(%q({% some_helper obj ip_valueAddImage '[Bild für rechte Spalte auswählen]' oha 'noch einer' %})).
          should == 'abc'
      end
    end

  end
end
