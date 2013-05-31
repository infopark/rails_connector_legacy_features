require "spec_helper"

module RailsConnector::LiquidSupport
  describe "Obj Support in Liquid Templates" do
    before do
      initialize_action_view_and_obj
      RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(false)
    end

    describe "accessing the Obj's methods" do
      it "should give access to all custom methods of the Obj" do
        class << @obj
          def foo_method
            "Spam"
          end

          def an_array
            [1,2,3]
          end
        end

        liq('{{ obj.foo_method }} and Eggs').should == "Spam and Eggs"
        liq('{{ obj.an_array.size }}').should == "3"
      end

      it "should ignore undefined method calls on Objs" do
        liq('{{ obj.foo_method }} and Eggs').should == " and Eggs"
      end
    end

    describe "accessing the Obj's fields" do
      before do
        @obj.stub_attrs!(
          :string_field => "<img/>",
          :html_field => ::RailsConnector::StringTagging.tag_as_html("<img/>", mock(Obj)),
          :freak_field => mock(:to_s => "freak &amp;")
        )
      end

      describe "when no edit markers are being rendered" do
        before do
          RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(false)
        end

        it "should escape non-html-safe output from the Obj's methods" do
          liq('{{ obj.string_field }}').should == "&lt;img/&gt;"
        end

        it "should not escape html-safe output from the Obj's methods" do
          liq('{{ obj.html_field }}').should == "<img/>"
        end

        it "should not fail on unexpected field values" do
          liq('{{ obj.freak_field }}').should == "freak &amp;"
        end
      end

      describe "when edit markers are being rendered" do
        before do
          RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(true)
          RailsConnector::Configuration.auto_liquid_editmarkers = nil
        end

        it "should escape non-html-safe output from the Obj's methods" do
          liq('{{ obj.string_field }}').should have_tag("span", "&lt;img/&gt;")
        end

        it "should not escape html-safe output from the Obj's methods" do
          liq('{{ obj.html_field }}').should have_tag("span img")
        end

        it "should not fail on unexpected field values" do
          liq('{{ obj.freak_field }}').should have_tag("span", "freak &amp;")
        end
      end
    end

    describe "accessing link lists" do
      before do
        @obj.stub_attrs!(
          :related_links => RailsConnector::LinkList.new([{:url => "http://example.net"}]),
          :empty_links => RailsConnector::LinkList.new([])
        )
      end

      it "should give access to links in a link list" do
        liq('{{ obj.related_links[0].url }}').should == "http://example.net"
        liq('{{ obj.related_links.first.url }}').should == "http://example.net"
        liq('{{ obj.related_links.last.url }}').should == "http://example.net"
      end

      it "should let the user iterate over the links" do
        liq('{% for link in obj.related_links %}{{ link.url }}{% endfor %}').should == "http://example.net"
      end

      it "should let the user access link lists like arrays" do
        liq('{{ obj.related_links.size }}').should == "1"
        liq_condition('obj.related_links == blank').should be_false
        liq_condition('obj.related_links == empty').should be_false
        liq_condition('obj.empty_links == blank').should be_true
        liq_condition('obj.empty_links == empty').should be_true
      end

      it "should ignore out-of-range accesses to link lists" do
        liq('link: {{ obj.related_links[2].url }}').should == "link: "
      end
    end

    describe "accessing links" do
      before do
        Obj.stub(:find).with([23]).and_return([
          Obj.new.stub_attrs!(:id => 23, :title => "Linked Spam", :active? => true)
        ])
        @obj.stub_attrs!(
          :external_links => RailsConnector::LinkList.new([{:url => "http://example.net"}, {:url => "http://nother.example.net"}]),
          :internal_links => RailsConnector::LinkList.new([{:destination => 23, :title => "Foo Titles"}])
        )
      end

      it "should check if a link is external" do
        liq_condition('obj.external_links.first.external?').should be_true
        liq_condition('obj.internal_links.first.external?').should be_false
      end

      it "should check if a link is internal" do
        liq_condition('obj.external_links.first.internal?').should be_false
        liq_condition('obj.internal_links.first.internal?').should be_true
      end

      it "should let the user access the link destination for internal links" do
        liq('{{ obj.internal_links.first.destination.title }}').should == "Linked Spam"
      end

      it "should let the user access the link title" do
        liq('{{ obj.internal_links.first.title }}').should == "Foo Titles"
      end
    end
  end
end

def liq_condition(condition)
  result = liq('{% if '+condition.to_s+' %}wahr{% else %}falsch{% endif %}')
  return true if result == "wahr"
  return false if result == "falsch"
  raise "Unexpected Result #{result} in Liquid Condition Spec"
end

def liq(template)
  render_liquid(template)
end
