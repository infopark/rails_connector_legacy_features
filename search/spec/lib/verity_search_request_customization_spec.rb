require "spec_helper"

module RailsConnector

  describe 'Customized VeritySearchRequest' do
    before do
      Configuration.search_options = {}
    end

    it "should join the conditions to form a base query" do
      sr = VeritySearchRequest.new('foo', {})
      sr.stub(:base_query_conditions).and_return(mock('conditions', :values => ['Anton', 'Caesar']))
      sr.base_query.should == "<#AND> (Anton, Caesar)"
    end

    it "should forward the base query to the SES interface" do
      sr = VeritySearchRequest.new('foo', {})
      sr.stub(:base_query).and_return('some base query')
      RailsConnector::SES::VerityAccessor.should_receive(:new).with(
        anything, hash_including(:base_query => 'some base query')
      ).and_return(mock().as_null_object)
      sr.fetch_hits
    end

  end

end
