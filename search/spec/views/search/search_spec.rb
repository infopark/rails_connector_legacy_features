require "spec_helper"

describe "/search/search" do
  before do
    flash[:errors] = 'some error'
  end

  it "should render localized message on error" do
    render
    rendered.should =~ /Unfortunately your search request could not be completed/
  end
end
