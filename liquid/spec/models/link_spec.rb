require "spec_helper"

module RailsConnector

  describe Link, "(to_liquid)" do

    it "should return a LinkDrop" do
      link = objs(:links).text_links.first
      link.to_liquid.should be_a(LiquidSupport::LinkDrop)
    end
  end

end
