module RailsConnector
  # This module is included if the <tt>:rss</tt> addon is
  # enabled:
  #     RailsConnector::Configuration.enable(:rss)
  module Syndicateable
    # Overwrite this method in your {Obj} in order to display another field in your feed.
    def rss_description
      body
    end
  end
end
