# encoding: utf-8
require "spec_helper"

# make sure to autoload the module before using it
RailsConnector::LiquidSupport
module RailsConnector::LiquidSupport

  describe "enable_helpers" do
    it "should register helpers as Liquid tags" do
      RailsConnector::LiquidSupport.enable_helpers(:helper_a, :helper_b)
      Liquid::Template.tags['helper_a'].should == RailsConnector::LiquidSupport::GeneralHelperTag
      Liquid::Template.tags['helper_b'].should == RailsConnector::LiquidSupport::GeneralHelperTag
      Liquid::Template.tags['some_other_helper'].should be_nil
    end
  end

  describe LiquidTemplateHandler, "when compiling a Liquid template" do

    before do
      @template = mock("Template")
    end

    it "should tell the LiquidTemplateRepository to compile the template" do
      LiquidTemplateRepository.should_receive(:compile).with(@template)
      LiquidTemplateHandler.call(@template)
    end

    it "should return a string with ruby code that can be used to render the compiled template"  do
      LiquidTemplateRepository.stub(:compile)
      LiquidTemplateHandler.call(@template).should be_include("LiquidTemplateRepository.render")
    end

  end

  # This Tag is used to test the Liquid Integration's Error Handling
  class ErrorTag < Liquid::Tag

    def render(context)
      raise "Error raised to test error handling"
    end

    Liquid::Template.register_tag('error', ErrorTag)
  end

  describe LiquidTemplateRepository do

    before { initialize_action_view_and_obj }

    describe "after a template has been compiled" do

      before do
        @template_id = LiquidTemplateRepository.compile(
          mock_template("<h1>{{ 'Mein Titel' }}</h1>")
        )
      end

      it "should be able to render the template" do
        LiquidTemplateRepository.render(@template_id, @action_view).should == "<h1>Mein Titel</h1>"
      end

      it "should not be confused with other templates" do
        other_template_id = LiquidTemplateRepository.compile(
          mock_template("<h1>{{ 'Mein Körper' }}</h1>")
        )
        LiquidTemplateRepository.render(@template_id, @action_view).should == "<h1>Mein Titel</h1>"
        LiquidTemplateRepository.render(other_template_id, @action_view).should == "<h1>Mein Körper</h1>"
      end

    end

    describe "when errors occur during rendering" do

      before do
        @template_id = LiquidTemplateRepository.compile(mock_template("<h1>{% error %}</h1>"))
        @logger = mock("Logger")
        @action_view.stub(:logger).and_return(@logger)
        @logger.stub(:warn)
      end

      describe "in development and production" do
        before do
          ::RailsConnector::LiquidSupport.raise_template_errors = nil
        end

        after do
          ::RailsConnector::LiquidSupport.raise_template_errors = true
        end

        it "should report the errors to the ActionView logger" do
          @logger.should_receive(:warn)
          LiquidTemplateRepository.render(@template_id, @action_view)
        end

        it "should still render the template" do
          rendered = LiquidTemplateRepository.render(@template_id, @action_view)
          rendered.should be_include("<h1>")
          rendered.should be_include("</h1>")
          rendered.should be_include("Liquid error")
        end
      end

      describe "when testing" do
        before do
          ::RailsConnector::LiquidSupport.raise_template_errors = true
        end

        it "should raise the errors" do
          lambda {
            LiquidTemplateRepository.render(@template, @action_view)
          }.should raise_error
        end
      end
    end

    describe "called with an unknown template id" do
      it "should raise an error" do
        @template = mock_template("<h1>Bla</h1>")
        lambda {
          LiquidTemplateRepository.render("unknown id", @action_view)
        }.should raise_error(RuntimeError, /illegal template id/)
      end
    end

    describe "when rendering a template" do
      let(:path_to_filters) { File.join(Rails.root, %w(app filters test_filters.rb)) }

      it "should load custom filter modules stored under RAILS_APP/app/filters" do
        # Vorbedingung:
        File.should be_exist(path_to_filters)
        LiquidTemplateRepository.load_custom_filters.should == [TestFilters]
      end

      it "should cache the custom filters" do
        LiquidTemplateRepository.reset_custom_filters
        Dir.should_receive(:[]).once.and_return([path_to_filters])
        LiquidTemplateRepository.load_custom_filters.should == [TestFilters]
        LiquidTemplateRepository.load_custom_filters.should == [TestFilters]
      end

      it "should activate custom filter modules" do
        render_liquid("{{'eggs'|spamify}}").should == "spam and eggs"
      end

    end

  end

  describe TemplateTag do

    before { initialize_action_view_and_obj }

    it "should render a rails partial inside the template" do
      @action_view.controller.stub(:render_to_string).with(:partial=> "foo_template").and_return("flüssig")
      render_liquid("Ich bin {% assign my_var = 'foo_template' %}{% template my_var %}").
        should == "Ich bin flüssig"
    end

    it "should raise an error when it's argument is missing" do
      lambda { render_liquid("{% template %}") }.should raise_error(Liquid::SyntaxError, /error in tag/i)
    end

  end

end