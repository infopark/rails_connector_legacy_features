require 'spec_helper'

module RailsConnector

  describe MandatoryLabelHelper do
    let(:output) do
      render :inline => %(
        <%= form_for :activity, :url => '/' do |f| %>
          <%= mandatory_label_for(f, :title, 'My Label') %>
        <% end %>
      )
    end

    it 'renders a label for mandatory fields' do
      output.should have_tag("form label.mandatory", /My Label/)
      output.should have_tag("form label.mandatory span.mandatory_star", /\*/)
    end
  end

end