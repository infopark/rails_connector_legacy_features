# encoding: utf-8
require 'spec_helper'

module RailsConnector
  describe ErrorMessagesHelper do

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
  end
end
