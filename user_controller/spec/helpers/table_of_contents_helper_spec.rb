require 'spec_helper'

module RailsConnector
  describe TableOfContentsHelper do
    let(:child1) { mock_model(Obj) }
    let(:child2) { mock_model(Obj) }
    let(:child3) { mock_model(Obj) }
    let(:obj) { mock_model(Obj, :sorted_toclist => [child1, child2, child3]) }
    let(:current_user) { mock }

    before do
      helper.stub(:current_user).and_return(current_user)
      child1.should_receive(:permitted_for_user?).with(current_user).and_return(true)
      child2.should_receive(:permitted_for_user?).with(current_user).and_return(true)
      child3.should_receive(:permitted_for_user?).with(current_user).and_return(false)
    end

    it "should return sorted toclist of permitted objects" do
      helper.table_of_contents(obj).should == [child1, child2]
    end
  end
end
