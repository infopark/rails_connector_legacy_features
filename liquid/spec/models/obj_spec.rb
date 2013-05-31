# encoding: utf-8
require "spec_helper"

describe Obj do

  describe "(to_liquid)" do
    it "should return an ObjDrop" do
      Obj.root.to_liquid.should be_a(LiquidSupport::ObjDrop)
    end
  end

end
