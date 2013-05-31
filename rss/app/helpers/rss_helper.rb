module RailsConnector

  module RssHelper

    def rss_header_tags
      html = "".html_safe
      html += auto_discovery_link_tag(:rss, rss_url, :title => 'RSS Feed')
      html
    end

  end

end
