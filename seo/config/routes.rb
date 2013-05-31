Rails.application.routes.draw do
  match 'sitemap.xml', :to => 'seo_sitemap#show', :format => 'xml'
end
