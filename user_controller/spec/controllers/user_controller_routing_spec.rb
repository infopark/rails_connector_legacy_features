require "spec_helper"

describe UserController, "routing" do

  it "should generate params { :controller => 'user', action => 'login' } from GET /login" do
    {:get => "/login"}.should route_to(:controller => "user", :action => "login")
  end

  it "should generate params { :controller => 'user', action => 'logout' } from GET /logout" do
    {:get => "/logout"}.should route_to(:controller => "user", :action => "logout")
  end

  it "should generate params { :controller => 'user', action => 'new' } from GET /user/new" do
    {:get => "/user/new"}.should route_to(:controller => "user", :action => "new")
  end

  it "should map login_path to /login" do
    login_path.should == "/login"
  end

  it "should map logout_path to /logout" do
    logout_path.should == "/logout"
  end

  it "should map user_path(:action => 'new') to /user/new" do
    user_path(:action => 'new').should == "/user/new"
  end

end
