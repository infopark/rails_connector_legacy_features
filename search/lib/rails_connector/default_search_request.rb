module RailsConnector
  # This class provides a default implementation for accessing the search server.
  # It is used by {DefaultSearchController}.
  # For Fiona please use VeritySearchRequest or LuceneSearchRequest:
  class DefaultSearchRequest < VeritySearchRequest
  end

  # # For Infopark CMS please use CmsApiSearchRequest:
  # class DefaultSearchRequest < CmsApiSearchRequest
  # end
end