require "spec_helper"

describe CurrentUserConfiguration do

  describe "#store_user_attrs_in_session" do
    it "should return configured fields" do
      Configuration.store_user_attrs_in_session = [:my_attr_1, :my_attr_2]
      Configuration.store_user_attrs_in_session.should eq([:my_attr_1, :my_attr_2])
    end

    it "should return default fields if nothing configured" do
      Configuration.store_user_attrs_in_session = nil
      Configuration.store_user_attrs_in_session.should eq(
          [:login, :first_name, :last_name, :email, :id])
    end
  end

end
