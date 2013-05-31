require "spec_helper"

module RailsConnector

  describe VeritySearchRequest do

    before do
      Configuration.search_options = {
        :host => "global_host",
        :port => 3000
      }
      @mock_accessor = mock("accessor", :search => nil);
    end

    describe 'initialization' do
      it "should sanitize the query string" do
        VeritySearchRequest.new('<foo@ (bar}', {}).instance_variable_get(:@query_string).should == 'foo bar'
      end
    end

    it "should return a vql query" do
      VeritySearchRequest.new('foo bar').vql_query_for('foo bar').should == "<#AND> (foo, bar)"
    end

    it "should access ses" do
      now = Time.now
      Time.stub!(:now).and_return(now)

      @sr = VeritySearchRequest.new('abc def', {})
      RailsConnector::SES::VerityAccessor.should_receive(:new).with(
        "<#AND> (abc, def)",
        hash_including(:base_query => @sr.base_query)
      ).and_return(accessor = mock("accessor"))
      accessor.should_receive(:search)
      @sr.fetch_hits
    end

    it "should use the global search options when no options are provided" do
      RailsConnector::SES::VerityAccessor.should_receive(:new).with(
        anything,
        hash_including(:host => "global_host", :port => 3000)
      ).and_return(
        @mock_accessor
      )
      VeritySearchRequest.new('foo').fetch_hits
    end

    it "should use the combine global search options with custom search options" do
      RailsConnector::SES::VerityAccessor.should_receive(:new).with(
        anything,
        hash_including(:host => "custom_host", :port => 3000)
      ).and_return(
        @mock_accessor
      )
      VeritySearchRequest.new('foo', {:host => "custom_host"}).fetch_hits
    end
  end

end
