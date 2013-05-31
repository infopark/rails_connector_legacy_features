require "spec_helper"

module RailsConnector

  SES.enable

  describe Obj, "find_with_ses('foo')" do
    it "should let the SES accessor perform the actual search" do
      SES::VerityAccessor.should_receive(:new).with(/foo/, an_instance_of(Hash)).and_return(
          accessor = mock("accessor"))
      accessor.should_receive(:search)
      Obj.find_with_ses("foo")
    end
  end


  describe SES::VerityAccessor, "build_request_payload()" do
    before do
      SES::VerityAccessor.send :public, :build_request_payload
      @accessor = SES::VerityAccessor.new("foo")
      @payload = Nokogiri::XML(@accessor.build_request_payload)
    end

    it "should build a payload suitable for SES" do
      @payload.should have_tag("ses-search query", "foo")
    end

    it "should request the result record fields objId and score" do
      @payload.should have_tag("resultRecord resultField", "objId")
      @payload.should have_tag("resultRecord resultField", "score")
    end

    it "should request to start at offset 0" do
      @payload.should have_tag("offset start", "1")
    end

    it "should request at most 10 hits" do
      @payload.should have_tag("offset length", "10")
    end

    it "should request minimum relevance of 50%" do
      @payload.should have_tag("minRelevance", "50")
    end

    it "should request all documents to be searched through" do
      @payload.should have_tag("maxDocs", "unlimited")
    end

    it "should request to use the simple parser" do
      @payload.should have_tag("query[parser=simple]")
    end

    it "should request the order score descending, name ascending" do
      @payload.should have_tag("sortOrder sortField[direction=desc]:nth-child(1)", "score")
      @payload.should have_tag("sortOrder sortField[direction=asc]:nth-child(2)", "name")
    end

    it "should request to search in the collection cm-contents" do
      @payload.should have_tag("searchBase collection", "cm-contents")
    end

    it "should have no base query" do
      @payload.should_not have_tag("searchBase query")
    end
  end


  describe SES::VerityAccessor, "when more than one collection is given" do
    before do
      SES::VerityAccessor.send :public, :build_request_payload
      @accessor = SES::VerityAccessor.new("foo", :collections => ["collection1","collection2"])
      @payload = Nokogiri::XML(@accessor.build_request_payload)
    end

    it "should request to search in the given collections" do
      @payload.should have_tag("searchBase collection", "collection1")
      @payload.should have_tag("searchBase collection", "collection2")
    end


  end

  describe SES::VerityAccessor, "build_request_payload(all available options)" do
    before do
      SES::VerityAccessor.send :public, :build_request_payload
      @accessor = SES::VerityAccessor.new("foo",
                                    :offset => 5,
                                    :limit => 13,
                                    :min_relevance => 70,
                                    :max_docs => 200,
                                    :parser => 'another',
                                    :sort_order => [["abc", "asc"], ["def", "desc"]],
                                    :collection => 'mydocs',
                                    :base_query => 'some base query')
      @payload = Nokogiri::XML(@accessor.build_request_payload)
    end

    it "should request to start at offset 5" do
      @payload.should have_tag("offset start", "6")
    end

    it "should request at most 13 hits" do
      @payload.should have_tag("offset length", "13")
    end

    it "should request minimum relevance of 70%" do
      @payload.should have_tag("minRelevance", "70")
    end

    it "should request 200 documents to be searched through" do
      @payload.should have_tag("maxDocs", "200")
    end

    it "should request to use another parser" do
      @payload.should have_tag("query[parser=another]")
    end

    it "should request the order according to the configuration" do
      @payload.should have_tag("sortOrder sortField[direction=asc]:nth-child(1)", "abc")
      @payload.should have_tag("sortOrder sortField[direction=desc]:nth-child(2)", "def")
    end

    it "should request to search in the collection mydocs" do
      @payload.should have_tag("searchBase collection", "mydocs")
    end

    it "should have a base query" do
      @payload.should have_tag("searchBase query[parser=another]", "some base query")
    end
  end


  describe SES::VerityAccessor, "send_to_ses(payload)" do
    before do
      SES::VerityAccessor.send :public, :send_to_ses
      @accessor = SES::VerityAccessor.new("foo")

      @http_connection = mock("http")
      @response = mock("response")
      @response.stub(:body).and_return("xml response")
    end

    it "should send the query as HTTP request to the SES" do
      Net::HTTP.should_receive(:new).with("localhost", 3011).and_return(@http_connection)
      @http_connection.should_receive(:start).and_return(@response)
      @accessor.send_to_ses("payload").should == "xml response"
    end
  end


  describe SES::VerityAccessor, "send_to_ses(payload), where some other host and port are given" do
    before do
      SES::VerityAccessor.send :public, :send_to_ses
      @accessor = SES::VerityAccessor.new("foo", :host => "anywhere.example.com", :port => 1234)

      @http_connection = mock("http")
      @http_connection.stub(:start).and_return(@response = mock("response"))
      @response.stub(:body).and_return("xml response")
    end

    it "should send the query to the given host and port" do
      Net::HTTP.should_receive(:new).with("anywhere.example.com", 1234).and_return(@http_connection)
      @accessor.send_to_ses("payload").should == "xml response"
    end
  end


  describe SES::VerityAccessor, "the result of parse_response_payload(payload)" do
    before do
      SES::VerityAccessor.send :public, :parse_response_payload
      @accessor = SES::VerityAccessor.new("foo")
      @xml_response = <<-EOXML
          <?xml version="1.0" encoding="UTF-8"?>
          <ses-payload payload-id="204442734428396001220061130092424669" timestamp="#{Time.now.to_iso}" ses.version="6">
            <ses-header>
              <ses-sender sender-id="SES-Infopark-DEV-0" name="SES"/>
              <ses-receiver name="pm" receiver-id="28320"/>
            </ses-header>
            <ses-response response-id="0" request-id="d-1f6a64dec16aa328-00000021-j-1" success="true">
              <ses-code numeric="200" phrase="OK">
                <searchResults hits="3" searched="3716">
                  <record index="1" offsetIndex="1">
                    <objId>2001</objId>
                    <score>0.8169</score>
                  </record>
                  <record index="2" offsetIndex="2">
                    <objId>2002</objId>
                    <score>0.7742</score>
                  </record>
                </searchResults>
              </ses-code>
            </ses-response>
          </ses-payload>
      EOXML
      Obj.should_receive(:find).with(2001).and_return(mock_model(Obj, :id => 2001))
      Obj.should_receive(:find).with(2002).and_return(mock_model(Obj, :id => 2002))
      @result = @accessor.parse_response_payload(@xml_response)
    end

    it "should be a SearchResult" do
      @result.should be_a_kind_of(SES::SearchResult)
    end

    it "should represent the hits" do
      @result.should have(2).items

      @result[0].id.should == 2001
      @result[0].score.should == 0.8169

      @result[1].id.should == 2002
      @result[1].score.should == 0.7742
    end

    it "should contain the total number of hits" do
      @result.total_hits.should == 3
    end
  end

  describe SES::VerityAccessor, "parse_response_payload(payload), with an out-of-date OBJ id" do

    before do
      SES::VerityAccessor.send :public, :parse_response_payload
      @accessor = SES::VerityAccessor.new("foo")
      @xml_response = <<-EOXML
          <?xml version="1.0" encoding="UTF-8"?>
          <ses-payload payload-id="204442734428396001220061130092424669" timestamp="#{Time.now.to_iso}" ses.version="6">
            <ses-header>
              <ses-sender sender-id="SES-Infopark-DEV-0" name="SES"/>
              <ses-receiver name="pm" receiver-id="28320"/>
            </ses-header>
            <ses-response response-id="0" request-id="d-1f6a64dec16aa328-00000021-j-1" success="true">
              <ses-code numeric="200" phrase="OK">
                <searchResults hits="2" searched="3716">
                <record index="1" offsetIndex="1">
                  <objId>2001</objId>
                  <score>0.8169</score>
                </record>
                <record index="2" offsetIndex="2">
                  <objId>20001</objId>
                  <score>0.7742</score>
                </record>
                </searchResults>
              </ses-code>
            </ses-response>
          </ses-payload>
      EOXML
    end

    it "should only have the item with the valid id" do
      result = @accessor.parse_response_payload(@xml_response)
      result.should have(1).item
      result.total_hits.should == 2
    end

    it "should log the missing OBJ" do
      Rails.logger.should_receive(:warn).with(/will not be shown/)
      @accessor.parse_response_payload(@xml_response)
    end
  end

  describe SES::VerityAccessor, "parse_response_payload(payload), with SES error encoded in the response" do
    before do
      SES::VerityAccessor.send :public, :parse_response_payload
      @accessor = SES::VerityAccessor.new("foo")
      @xml_response = <<-EOXML
          <?xml version="1.0" encoding="UTF-8"?>
          <ses-payload payload-id="5878634124021093920061220104002344" timestamp="20061220104002" ses.version="6">
            <ses-header>
              <ses-sender sender-id="SES-Infopark-DEV-0" name="SES"/>
              <ses-receiver name="pm" receiver-id="42"/>
            </ses-header>
            <ses-response response-id="0" request-id="d-1f6a64dec16aa328-00000021-j-1" success="false">
              <ses-code numeric="100230" phrase="[100230] Die Verity-Suchmaschine hat den Fehlercode -40 bei der Bearbeitung der Aktion 'VdkSearchNew' gemeldet.">
                <errorStack>
                  <error>
                    <numeric>100230</numeric>
                    <phrase>[100230] Die Verity-Suchmaschine hat den Fehlercode -40 bei der Bearbeitung der Aktion 'VdkSearchNew' gemeldet.</phrase>
                  </error>
                  <error>
                    <numeric>100171</numeric>
                    <phrase>[100171] Die Verity-Suchmaschine hat einen Fehler gemeldet: (-40) Error   E1-0114 (Query Builder): Error parsing query: &lt;AND&gt; ((
              infopark,
          )
          </phrase>
                  </error>
                  <error>
                    <numeric>100171</numeric>
                    <phrase>[100171] Die Verity-Suchmaschine hat einen Fehler gemeldet: (-40) Error   E1-0111 (Query Builder): Syntax error in query string near character 31</phrase>
                  </error>
                </errorStack>
              </ses-code>
            </ses-response>
          </ses-payload>
      EOXML
    end

    it "should raise a SearchError" do
      lambda { @accessor.parse_response_payload(@xml_response) }.should raise_error(SES::SearchError)
    end
  end

end
