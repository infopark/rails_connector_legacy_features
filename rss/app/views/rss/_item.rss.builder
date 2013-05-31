xml.item do
  xml.title display_value(item.title)
  xml.description display_value(item.rss_description)
  xml.pubDate item.valid_from.rfc2822 if item.valid_from
  url = cms_url(item)
  if RailsConnector::Configuration.enabled?(:google_analytics)
    url << '#utm_medium=rss&utm_source=rss&utm_campaign=' << cms_path(item)
  end
  xml.link url
  xml.guid url
end
