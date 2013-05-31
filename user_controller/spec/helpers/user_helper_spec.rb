require "spec_helper"

module RailsConnector

  describe UserHelper do

    before do
      assign(:user, Infopark::Crm::Contact.new({
        :language => "de",
      }))
    end

    describe "#user_fields_for" do
      it 'should render labels and fields for the given attributes' do
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => '/' do |f| %>
            <%= user_fields_for(f, "contact", :first_name, :last_name, :email) %>
          <% end %>
        HTML
        markup.should have_tag('label[for=user_first_name]')
        markup.should have_tag('label[for=user_last_name]')
        markup.should have_tag('label[for=user_email]')
        markup.should have_tag('input[id=user_first_name]')
        markup.should have_tag('input[id=user_last_name]')
        markup.should have_tag('input[id=user_email]')
      end

      it "should work with an array of attributes" do
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => '/' do |f| %>
            <%= user_fields_for(f, "contact", [:first_name, :last_name]) %>
          <% end %>
        HTML
        markup.should have_tag('label[for=user_first_name]')
        markup.should have_tag('label[for=user_last_name]')
        markup.should have_tag('input[id=user_first_name]')
        markup.should have_tag('input[id=user_last_name]')
      end

      it "renders selects for gender, title, and language" do
        Infopark::Crm::CustomType.should_receive(:find).with('contact').and_return(
            mock(:languages => %w(en de)))
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => '/' do |f| %>
            <%= user_fields_for(f, "contact", :gender, :language) %>
          <% end %>
        HTML
        markup.should have_tag("select[id=user_gender] option[value=F]")
        markup.should have_tag("select[id=user_gender] option[value=M]")
        markup.should have_tag("select[id=user_gender] option[value=N]")
        markup.should have_tag("select[id=user_language] option[value=de][selected=selected]")
        markup.should have_tag("select[id=user_language] option[value=en]")
      end

      it 'defaults to certain mandatory fields' do
        helper.mandatory_user_fields.should include(:email)
        helper.mandatory_user_fields.should include(:language)
      end

      it 'indicates mandatory fields' do
        helper.should_receive(:mandatory_user_fields).and_return([:email])
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => '/' do |f| %>
            <%= user_fields_for(f, "contact", :email) %>
          <% end %>
        HTML
        markup.should have_tag('label[for=user_email][class=mandatory]') do |label|
          label.should have_tag("span.mandatory_star", /\*/)
        end
      end

      it 'does not render other fields as mandatory' do
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => '/' do |f| %>
            <%= user_fields_for(f, "contact", :first_name) %>
          <% end %>
        HTML
        markup.should_not have_tag('label[for=user_first_name][class=mandatory]')
      end

      it "renders user_fields_for automagically and nested-mass-assignable" do
        markup = render :inline => <<-HTML
          <%= form_for @user, :as => :user, :url => "/" do |f| %>
            <%= profile_fields_for(f, {
                  :contact => [:first_name, :locality],
                }) %>
          <% end %>
        HTML
        markup.should have_tag("label[for=user_first_name]")
        markup.should have_tag("input[id=user_first_name][name='user[first_name]']")
        markup.should have_tag("label[for=user_locality]")
        markup.should have_tag("input[id=user_locality][name='user[locality]']")
      end
    end

    describe "#genders_for_select" do
      it "should return the options for the gender select field" do
        options = helper.genders_for_select
        options.map(&:second).should == ['N', 'F', 'M']
      end

      it "should return the options for the languages select field (with the given codes as values)" do
        options = helper.languages_for_select_for(['en', 'de'])
        options.map(&:second).should == ['en', 'de']
      end

      it "should work without array argument as well" do
        options = helper.languages_for_select_for('en', 'de')
        options.map(&:second).should == ['en', 'de']
      end
    end
  end

end
