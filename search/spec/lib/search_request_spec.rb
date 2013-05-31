require "spec_helper"

module RailsConnector

  describe SearchRequest do
    # For Fiona:
    it "should default to a Verity based search" do
      SearchRequest.ancestors.should include(VeritySearchRequest)
    end

    # # For Infopark CMS:
    # it "should default to a Cms Api based search" do
    #   SearchRequest.ancestors.should include(CmsApiSearchRequest)
    # end
  end

end
