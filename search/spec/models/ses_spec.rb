require "spec_helper"

module RailsConnector

  SES.enable

  describe Obj, "find_with_ses" do
    it "should generate a search request" do
      mock_request = mock("request")
      SearchRequest.should_receive(:new).with("foo", {:option => 'value'}).and_return(mock_request)
      mock_request.should_receive(:fetch_hits)
      Obj.find_with_ses("foo", {:option => 'value'})
    end
  end

  describe SES::Hit, "obj()" do
    it "should cache the object" do
      Obj.should_receive(:find).once.with(1234).and_return(mock_model(Obj))
      @hit = SES::Hit.new(1234, 0.9)
      @hit.obj
      @hit.obj
    end

    it "should not load the object when initialized" do
      Obj.should_not_receive(:find)
      @hit = SES::Hit.new(1234, 0.9, {})
    end

    it 'should return nil when there is no object' do
      Obj.should_receive(:find).with('690768f1421744a74eb95589f1c0b5bd').
          and_raise RailsConnector::ResourceNotFound

      hit = SES::Hit.new('690768f1421744a74eb95589f1c0b5bd', 0.8, {})
      hit.obj.should be_nil
    end

    it "should return the initialized object, when given, without loading it again" do
      Obj.should_not_receive(:find)
      fake_obj = mock_model(Obj)
      hit = SES::Hit.new('690768f1421744a74eb95589f1c0b5bd', 0.8, {}, fake_obj)
      hit.obj.should eq(fake_obj)
    end
  end

  describe SES::Hit, "doc parameters" do
    it "provide the raw hash from the search engine" do
      @doc = { 'name' => "test" }
      @hit = SES::Hit.new(1234, 0.9, @doc)
      @hit.doc.should == @doc
    end
  end
end
