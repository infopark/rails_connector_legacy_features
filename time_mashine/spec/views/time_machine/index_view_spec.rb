require "spec_helper"

describe "/rails_connector/time_machine/index" do
  before do
    @preview_time = 10.days.from_now
    assign(:preview_time, @preview_time)
    assign(:language, "fr")
    RailsConnector::Configuration.stub(:enabled?).and_return(true)
    RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(true)
    reload_routes_for_this_test
    render
  end

  it "should generate style and javascript includes" do
    head = view.view_flow.content[:head]
    head.should have_tag("link[rel=stylesheet][href='/assets/time_machine.css']")
    head.should have_tag("script[src='/assets/time_machine.js']")
  end

  it "should display the calendar" do
    rendered.should have_tag('div#calendar')
    rendered.should =~ /Calendar.setup/
    rendered.should =~ /flat: "calendar"/
    rendered.should =~ /date: new Date\(#{@preview_time.year}, #{@preview_time.month - 1}, #{@preview_time.day}\)/
  end
end
