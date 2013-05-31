module RailsConnector

  module GoogleAnalyticsHelper

    def google_analytics_after_content_tags
      html = "".html_safe
      html += google_analytics
      html
    end

  end

end
