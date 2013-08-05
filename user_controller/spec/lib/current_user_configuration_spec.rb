require "spec_helper"

describe CurrentUserConfiguration do

  describe "#store_user_attrs_in_session" do
    it "should return configured fields" do
      CurrentUserConfiguration.store_user_attrs_in_session = [:my_attr_1, :my_attr_2]
      CurrentUserConfiguration.store_user_attrs_in_session.should eq([:my_attr_1, :my_attr_2])
    end

    it "should return default fields if nothing configured" do
      CurrentUserConfiguration.store_user_attrs_in_session = nil
      CurrentUserConfiguration.store_user_attrs_in_session.should eq(
          [:login, :first_name, :last_name, :email, :id])
    end
  end

end
