# encoding: utf-8
require "spec_helper"

module RailsConnector

describe ElasticsearchRequest do
  let(:request) { ElasticsearchRequest.new("query") }
  let(:real_es_result) {'{"took":30,"timed_out":false,"_shards":{"total":5,"successful":5,"failed":0},"hits":{"total":2,"max_score":2.6,"hits":[{"_index":"default","_type":"current","_id":"690768f1421744a74eb95589f1c0bf93","_score":2.6,"fields":{"obj_id":"690768f1421744a74eb95589f1c0b5bd"}},{"_index":"default","_type":"current","_id":"690768f1421744a74eb95589f1c3c87c","_score":1.3,"fields":{"obj_id":"690768f1421744a74eb95589f1c3c81b"}}]}}'}

  describe "when fetching hits" do
    let(:obj1) { mock('obj1') }
    let(:obj2) { mock('obj2') }

    before do
      Configuration.stub(:search_options).and_return({:url => 'the es url'})
      Obj.stub(:find).with('690768f1421744a74eb95589f1c0b5bd').and_return obj1
      Obj.stub(:find).with('690768f1421744a74eb95589f1c3c81b').and_return obj2
    end

    it "should perform a get request" do
      RestClient::Request.should_receive(:execute).with(hash_including(:method => :get)).
          and_return(real_es_result)
      request.fetch_hits
    end

    it "should return the result with normalized score" do
      RestClient::Request.should_receive(:execute).and_return(real_es_result)
      result = request.fetch_hits
      result.should be_a(SES::SearchResult)
      result.total_hits.should == 2
      result.size.should == 2
      result[0].should be_a(SES::Hit)
      result[0].id.should == '690768f1421744a74eb95589f1c0b5bd'
      result[0].score.should == 1.0
      result[0].obj.should == obj1
      result[1].should be_a(SES::Hit)
      result[1].id.should == '690768f1421744a74eb95589f1c3c81b'
      result[1].score.should == 0.5
      result[1].obj.should == obj2
    end

    it "should use the computed request body but extend the fields with “obj_id”" do
      request.should_receive(:request_body).and_return({:query => :as_computed})
      RestClient::Request.should_receive(:execute).with(hash_including(
        :payload => {
          :query => :as_computed,
          :fields => [:obj_id]
        }.to_json
      )).and_return(real_es_result)
      request.fetch_hits

      request.should_receive(:request_body).and_return({:query => :as_computed, :fields => %w(a b)})
      RestClient::Request.should_receive(:execute).with(hash_including(
        :payload => {
          :query => :as_computed,
          :fields => ['a', 'b', :obj_id]
        }.to_json
      )).and_return(real_es_result)
      request.fetch_hits
    end

    it "should use the computed request body but set the offset and limit if given" do
      request = ElasticsearchRequest.new("query", :offset => 13, :limit => 42)
      request.should_receive(:request_body).and_return({:query => :as_computed})
      RestClient::Request.should_receive(:execute) do |args|
        args[:payload].should_not be_empty
        JSON.parse(args[:payload]).should == {
          'from' => 13,
          'size' => 42,
          'query' => 'as_computed',
          'fields' => ['obj_id']
        }
        real_es_result
      end
      request.fetch_hits
    end

    it "should use the configured url if no url was given" do
      RestClient::Request.should_receive(:execute).with(
          hash_including(:url => 'the es url/_search')).and_return(real_es_result)
      request.fetch_hits
    end

    it "should use the given url if any" do
      RestClient::Request.should_receive(:execute).with(
        hash_including(:url => 'non-default url/_search')
      ).and_return(real_es_result)
      ElasticsearchRequest.new('query', :url => 'non-default url').fetch_hits
    end
  end

  describe "when building request body" do
    before do
      Configuration.stub(:search_options).and_return({})
    end

    before do
      request.stub(:query).and_return "the query"
      request.stub(:filter).and_return "the filter"
    end

    it "should use the query and the filter to build up the request body" do
      request.request_body.should == {
        :query => "the query",
        :filter => "the filter"
      }
    end
  end

  describe "when building the query" do
    before do
      Configuration.stub(:search_options).and_return({})
    end

    it "should build a “query_strings” query" do
      request.query.should == {:query_string => {:query => 'query'}}
    end

    it "should remove special characters from the query string" do
      ElasticsearchRequest.new("[yes:] it$s r'n\"r(!)+ ").query[:query_string][:query].
          should == 'yes it s r n r'
    end

    it "should remove operator words from the query string" do
      ElasticsearchRequest.new('me and you or not them').query[:query_string][:query].
          should == 'me you them'
    end

    it "should not remove substrings from non operator words from the query string" do
      ElasticsearchRequest.new('playland and infopork or not notify').query[:query_string][:query].
          should == 'playland infopork notify'
    end
  end

  describe "when building the filter" do
    before do
      Time.stub(:now).and_return Time.utc(2010, "jan", 1, 12, 0, 0)
      Configuration.stub(:search_options).and_return({})
    end

    it "should filter out images" do
      request.filter[:and].should include({:not => {:term => {:obj_type => :image}}})
    end

    it "should filter out suppressed objects by default" do
      request.filter[:and].should include({:not => {:term => {:suppress_export => true}}})
    end

    it "should filter valid_from by the current time" do
      request.filter[:and].should include({:not => {:range => {:valid_from => {
          :from => '20100101120001', :to => '*'}}}})
    end

    it "should filter valid_until by the current time" do
      request.filter[:and].should include({:not => {:range => {:valid_until => {
          :from => '*', :to => '20100101120000'}}}})
    end
  end
end

end
