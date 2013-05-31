# encoding: utf-8
require 'spec_helper'

module RailsConnector

  describe CrmFormHelper do

    describe "displaying inputs for custom fields" do
      let(:some_activity) { mock("Some Activity", :kind => 'contact form',
          :errors => ActiveModel::Errors.new(mock)) }
      let(:template) do
        %(<%= form_for :some_activity, :url => '/' do |f| %>
          <%= custom_fields_for(f) %>
        <% end %>)
      end
      let(:output) { render :inline => template }

      before do
        helper.instance_variable_set('@some_activity', some_activity)
        attribute_definitions = [
          mock({:name => 'name', :title => 'Your name', :type => 'some_type', :mandatory => true}),
          mock({:name => 'comments', :title => 'Your comments', :type => 'text',
              :mandatory => true}),
          mock({:name => 'location', :title => 'Where are you?', :type => 'enum',
              :valid_values => %w(office home), :mandatory => false})
        ]
        custom_type = mock('CustomType')
        Infopark::Crm::CustomType.stub(:find).with('contact form').and_return(custom_type)
        custom_type.stub(:custom_attributes).and_return(attribute_definitions)
        some_activity.stub(:custom_name).and_return('John Doe')
        some_activity.stub(:custom_comments).and_return('My 2 cents')
        some_activity.stub(:custom_location).and_return('home')
        helper.stub!(:allow_custom_attribute?).and_return(true)
      end

      it "should have labels for all fields" do
        output.should have_tag("div.label label[for=some_activity_custom_name]", /^Your name/)
        output.should have_tag("div.label label[for=some_activity_custom_comments]", /^Your comments/)
        output.should have_tag("div.label label[for=some_activity_custom_location]", /^Where are you?/)
      end

      it "should mark mandatory fields" do
        output.should have_tag("div.label label.mandatory[for=some_activity_custom_name] span.mandatory_star", /\*/)
        output.should have_tag("div.label label.mandatory[for=some_activity_custom_comments] span.mandatory_star", /\*/)
        output.should have_tag("div.label label[for=some_activity_custom_location]")
        output.should_not have_tag("div.label label.mandatory[for=some_activity_custom_location]")
      end

      it "should display textareas for type 'text'" do
        output.should have_tag("div.field textarea[cols='50'][rows='5'][id=some_activity_custom_comments]" \
            "[name='some_activity[custom_comments]']", "\nMy 2 cents")
      end

      it "should display selects for type 'enum'" do
        output.should have_tag("div.field") do |field|
          field.should have_tag("select[id=some_activity_custom_location]" \
              "[name='some_activity[custom_location]']") do |select|
            select.should have_tag("option[selected=selected]", "home")
            select.should have_tag("option", "office")
          end
          field.should_not have_tag("select[id=some_activity_custom_location]" \
              "[multiple=multiple][name='some_activity[custom_location]']")
        end
      end

      it "should display text input for other types" do
        output.should have_tag("div.field input[id=some_activity_custom_name]" \
            "[name='some_activity[custom_name]'][value='John Doe']")
      end

      it "should omit fields that are blacklisted" do
        helper.stub(:allow_custom_attribute?).with("custom_location").and_return(false)
        markup = render(:inline => template)
        markup.should_not have_tag("label[for=some_activity_custom_location]")
        markup.should_not have_tag("select[id=some_activity_custom_location]")
      end

      it "should highlight fields with errors" do
        some_activity.errors.add(:custom_location, "")
        some_activity.errors.add(:custom_name, "")
        markup = render(:inline => template)
        markup.should have_tag(".field_with_errors label[for=some_activity_custom_location]")
        markup.should have_tag(".field_with_errors label[for=some_activity_custom_name]")
      end
    end

    describe 'displaying title input field' do
      def render_form(has_title_input_field)
        helper.should_receive(:has_title_input_field?).and_return(has_title_input_field)
        render :inline => <<-HTML
          <%= form_for :activity, :url => '/' do |f| %>
            <%= title_field_for(f) %>
          <% end %>
        HTML
      end

      it 'should render nothing if has_title_input_field? is false' do
        render_form(false).should_not have_tag('input[id=activity_title]')
      end

      it 'should render an input field if has_title_input_field? is true' do
        markup = render_form(true)
        markup.should have_tag('label[for=activity_title][class=mandatory]')
        markup.should have_tag('input[id=activity_title]')
      end
    end

    describe 'displaying errors' do
      let(:user) {
        Infopark::Crm::Contact.new.tap do |u|
          u.errors.add(:nothing, "muss für den User was sein")
        end
      }

      let(:activity) {
        Infopark::Crm::Activity.new(:kind => "contact form").tap do |a|
          a.errors.add(:nothing, "muss für die Activity was sein")
        end
      }

      let(:rendered_error_messages) {
        helper.error_messages(user, activity)
      }


      describe 'when a model is nil' do
        let(:activity) {nil}

        it "should display messages for all remaining non-nil models" do
          lambda {
            rendered_error_messages
          }.should_not raise_error
          rendered_error_messages.should include("den User")
          rendered_error_messages.should_not include("die Activity")
        end
      end

      it "should render an error message box with css classes and all error messages" do
        rendered_error_messages.should have_tag('div.errorExplanation') do |div|
          div.should have_tag('ul') do |ul|
            ul.should have_stripped_text('li', "Nothing muss für den User was sein")
            ul.should have_stripped_text('li', "Nothing muss für die Activity was sein")
          end
        end
      end

      let(:html_safe_output) {rendered_error_messages}
      it_should_behave_like "an html safe helper"
    end

    it 'displays "logged in as X"' do
      helper.logged_in_as('John Doe').should have_tag('em', /logged in as/) do |em|
        em.should have_tag("strong", 'John Doe')
      end
    end
  end
end
