# encoding: utf-8
require "spec_helper"

module RailsConnector

describe CmsApiSearchRequest do
  before do
    @obj1 = objs(:child1)
    @obj2 = objs(:dokument)
  end

  let(:request) { CmsApiSearchRequest.new(search_value) }
  let(:search_value) { 'query word' }
  let(:real_search_result) do
    {
      "total" => 2,
      "results" => [{"id" =>  "#{@obj1.id}"}, {"id" =>  "#{@obj2.id}"}],
    }
  end

  describe "when fetching hits" do
    before do
      # This is for ObjSearchEnumerator.size
      CmsRestApi.should_receive(:get) do |resource_path, payload|
        resource_path.should eq("revisions/#{Workspace.current.revision_id}/objs/search")
        payload[:offset].should eq(nil)
        payload[:size].should eq(0)

        {"total" => 2}
      end
    end

    it "should return the results" do
      CmsRestApi.should_receive(:get).and_return(real_search_result)

      result = request.fetch_hits
      result.should be_a(SES::SearchResult)
      result.total_hits.should == 2
      result.size.should == 2
      result[0].should be_a(SES::Hit)
      result[0].id.should == @obj1.id
      result[0].score.should == 1.0
      result[0].obj.should == @obj1
      result[1].should be_a(SES::Hit)
      result[1].id.should == @obj2.id
      result[1].score.should == 1.0
      result[1].obj.should == @obj2
    end

    context 'with a search_value that starts and ends with spaces' do
      let(:search_value) { ' foo ' }

      it 'should only search for the stripped value' do
        CmsRestApi.should_receive(:get) do |resource_path, payload|
          prefix_search_sub_query = payload[:query].select{ |q| q[:operator] == :prefix_search }

          prefix_search_sub_query.size.should eq(1)
          prefix_search_sub_query.first[:value].should eq('foo')

          real_search_result
        end

        request.fetch_hits
      end
    end

    it "should use the correct query" do
      now = Time.now
      Time.stub!(:now).and_return(now)

      CmsRestApi.should_receive(:get) do |resource_path, payload|
        resource_path.should eq("revisions/#{Workspace.current.revision_id}/objs/search")

        payload[:size].should eq(10)
        payload[:offset].should eq(0)
        payload[:query].should eq([
          { :field => :_valid_from, :operator => :less_than, :value => now.to_iso},
          { :field => :_valid_until, :operator => :less_than, :value => now.to_iso, :negate => true },
          { :field => :_obj_class, :operator => :equal, :value => 'Image', :negate => true },
          { :field => :*, :operator => :prefix_search, :value => 'query'},
          { :field => :*, :operator => :prefix_search, :value => 'word'},
        ])

        real_search_result
      end

      request.fetch_hits
    end

    it "should use the offset and limit if given" do
      request = CmsApiSearchRequest.new("query", :offset => 13, :limit => 42)
      CmsRestApi.should_receive(:get) do |resource_path, payload|
        resource_path.should eq("revisions/#{Workspace.current.revision_id}/objs/search")
        payload[:offset].should eq(13)
        payload[:size].should eq(42)

        real_search_result
      end

      request.fetch_hits
    end
  end
end

end
