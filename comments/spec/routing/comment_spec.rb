require 'spec_helper'

describe "routing for comments", :required_feature => "comments" do

  it "should have a named route 'comment'" do
    lambda {comment_path}.should_not raise_error
  end

  it "should accept and provide a (comment) :id" do
    comment_path(:action => "delete", :id => "12").should == "/comments/delete/12"
    {
      :delete => "/comments/delete/12"
    }.should route_to({
      :controller => "comments",
      :action => "delete",
      :id => "12",
    })
  end

  it "should treat the (comment) :id as optional" do
    comment_path(:action => "index").should == "/comments/index"
  end

  it "should support comment delete" do
    comment_path(:action => "delete", :id => "12").should == "/comments/delete/12"
    {
      :delete => "/comments/delete/12"
    }.should route_to({
      :controller => "comments",
      :action => "delete",
      :id => "12",
    })
  end
end
