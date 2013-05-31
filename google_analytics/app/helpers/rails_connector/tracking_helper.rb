module RailsConnector

  # This module contains helpers for Google Analytics and Infopark Tracking.
  module TrackingHelper

    # This helper renders the Google Analytics snippet using the domain code
    # for the current domain as configured via <tt>Configuration::GoogleAnalytics.domain_code</tt>.
    # The helper is automatically run when using the +rails_connector_after_content_tags+,
    # if the feature <tt>:google_analytics</tt> is enabled.
    def google_analytics
      if domain_code = Configuration::GoogleAnalytics.domain_code(request.host)
        raw %Q{
          <script type="text/javascript" src='#{ga_prefix}google-analytics.com/ga.js'></script>
          <script type="text/javascript">
            try {
              var pageTracker = _gat._getTracker("#{domain_code}");
              pageTracker._setAllowAnchor(true);
              pageTracker._addIgnoredOrganic("#{request.host}");
              pageTracker._trackPageview();
            } catch(err) {}
          </script>
        }
      end
    end

    private

    def ga_prefix
      request.ssl? ? 'https://ssl.' : 'http://www.'
    end
  end
end
