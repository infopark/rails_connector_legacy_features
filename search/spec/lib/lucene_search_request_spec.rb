# encoding: utf-8
require "spec_helper"

module RailsConnector

  describe LuceneSearchRequest, 'initialization' do
    it "should remove special characters from the query string" do
      LuceneSearchRequest.new("[yes:] it$s r'n\"r(!)+ ", {}).instance_variable_get(:@query_string).should == 'yes it s r n r'
    end
  end

  describe LuceneSearchRequest do
    it "should remove operator words from the query string" do
      LuceneSearchRequest.new('me and you or not them').solr_query_for_query_string.
          should_not match 'and|or|not'
    end

    it "should lowercase the query words" do
      LuceneSearchRequest.new('Search FIND').solr_query_for_query_string.
          should match 'search.*find'
    end

    it "should build a Solr query searching for each query word" do
      LuceneSearchRequest.new('foo bar stuff').solr_query_for_query_string.
          should == "foo AND bar AND stuff"
    end

    it "should use exclusion filters to give results even if a field is not indexed" do
      conditions = LuceneSearchRequest.new('x').filter_query_conditions
      conditions[:suppress_export].should match /^NOT /
      conditions[:object_type].should match /^NOT /
      conditions[:valid_from].should match /^NOT /
      conditions[:valid_until].should match /^NOT /
    end
  end

  describe LuceneSearchRequest, "encountering Solr errors" do
    before do
      @mock_rsolr_client = mock('mock_rsolr')
      RSolr.stub(:connect).and_return @mock_rsolr_client
    end

    it "should return an exception when Solr is not available" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
      }.and_raise Errno::ECONNREFUSED
      lambda { LuceneSearchRequest.new('*').fetch_hits }.should raise_error Errno::ECONNREFUSED

      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
      }.and_raise SocketError
      lambda { LuceneSearchRequest.new('*').fetch_hits }.should raise_error SocketError
    end
  end

  describe LuceneSearchRequest, "fetching hits" do
    before do
      @mock_rsolr_client = mock('mock_rsolr')
      RSolr.stub(:connect).and_return @mock_rsolr_client
      @mock_response = {'response' => {'numFound' => 0, 'maxScore' => 1.0, 'docs' => {}}}
      @mock_rsolr_client.stub(:get).and_return(@mock_response)

      ::Obj.stub(:find).and_return mock('obj')

      Configuration.stub(:search_options).and_return({
        :filter_query => {
          :object_type => nil,
          :valid_from => nil,
          :valid_until => nil,
          :suppress_export => nil
        }
      })

      Time.stub(:now).and_return Time.utc(2010, "jan", 1, 12, 0, 0)
    end

    it "should get results through rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
      }
      LuceneSearchRequest.new('bla').fetch_hits
    end

    it "should pass the query to rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:q].should == 'testquery'
      }
      LuceneSearchRequest.new('testquery').fetch_hits
    end

    it "should request id and score fields from rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fl].should == 'id,score'
      }
      LuceneSearchRequest.new('score and id').fetch_hits
    end

    it "should use a given Solr url" do
      RSolr.should_receive(:connect).with(hash_including(:url => 'http://mysolr/'))
      LuceneSearchRequest.new('filter', {:solr_url => "http://mysolr/"}).fetch_hits
    end

    it "should pass a given filter query to rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['myField:yes']
      }
      fq = Configuration.search_options[:filter_query].merge({:test => 'myField:yes'})
      LuceneSearchRequest.new('filter', {:filter_query => fq}).fetch_hits
    end

    it "should pass a configured filter query to rsolr" do
      Configuration.search_options[:filter_query].merge!({:test => 'language:de'})
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['language:de']
      }
      LuceneSearchRequest.new('filter').fetch_hits
    end

    it "should filter out images by default" do
      Configuration.search_options[:filter_query].delete(:object_type)
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['NOT object_type:image']
      }
      LuceneSearchRequest.new('filter').fetch_hits
    end

    it "should filter out suppressed objects by default" do
      Configuration.search_options[:filter_query].delete(:suppress_export)
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['NOT suppress_export:1']
      }
      LuceneSearchRequest.new('filter').fetch_hits
    end

    it "should filter valid_from by the current time" do
      Configuration.search_options[:filter_query].delete(:valid_from)
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['NOT valid_from:[20100101120001 TO *]']
      }
      LuceneSearchRequest.new('filter').fetch_hits
    end

    it "should filter valid_until by the current time" do
      Configuration.search_options[:filter_query].delete(:valid_until)
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fq].should == ['NOT valid_until:[* TO 20100101120000]']
      }
      LuceneSearchRequest.new('filter').fetch_hits
    end

    it "should pass a given limit to rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:rows].should == 123
      }
      LuceneSearchRequest.new('*', {:limit => 123}).fetch_hits
    end

    it "should pass a given offset to rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:start].should == 987
      }
      LuceneSearchRequest.new('*', {:offset => 987}).fetch_hits
    end

    it "should return the total number of matching documents from Solr" do
      @mock_response['response']['numFound'] = 1234
      LuceneSearchRequest.new('*').fetch_hits.total_hits.should == 1234
    end

    it "should return the documents from Solr as hits" do
      @mock_response['response']['docs'] =
          [{'id' => 11, 'score' => 1.0}, {'id' => 22, 'score' => 0.0}]
      hits = LuceneSearchRequest.new('*').fetch_hits
      hits.size.should == 2
      hits[0].id.should == 11
      hits[0].score.should == 1.0
      hits[1].id.should == 22
      hits[1].score.should == 0.0
    end

    it "should return a score in the 0.0 to 1.0 range even with higher Solr score" do
      @mock_response['response']['maxScore'] = 5.0
      @mock_response['response']['docs'] =
          [{'id' => 0, 'score' => 5.0}, {'id' => 0, 'score' => 1.0}]
      hits = LuceneSearchRequest.new('*').fetch_hits
      hits[0].score.should == 1.0
      hits[1].score.should == 0.2
    end

    it "should remove deleted objects from hits" do
      @mock_response['response']['docs'] =
          [{'id' => 0, 'score' => 1.0}, {'id' => 1, 'score' => 1.0}, {'id' => 2, 'score' => 1.0}]
      ::Obj.stub(:find).and_return do |arg|
        if arg == 1
          raise RailsConnector::ResourceNotFound
        else
          mock('obj')
        end
      end
      hits = LuceneSearchRequest.new('*').fetch_hits
      hits.size.should == 2
      hits[0].id.should == 0
      hits[1].id.should == 2
    end

    it "should pass a given solr query parameter to rsolr" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:timeAllowed].should == 500
      }
      LuceneSearchRequest.new('*', {:solr_parameters => {:timeAllowed => 500}}).fetch_hits
    end

    it "should override a default solr query parameter with a given one" do
      @mock_rsolr_client.should_receive(:get) { |action, query_params|
        action.should == "select"
        query_params[:params][:fl].should == 'id,score,more'
      }
      LuceneSearchRequest.new('*', {:solr_parameters => {:fl => 'id,score,more'}}).fetch_hits
    end

    it "should lazy load if options specified" do
      LuceneSearchRequest.new('*', :lazy_load => true).fetch_hits
      ::Obj.should_not_receive(:find)
    end
  end
end
