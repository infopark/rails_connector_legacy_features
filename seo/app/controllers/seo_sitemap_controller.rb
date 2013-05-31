# Renders a search engine optimized sitemap.xml
# Enable via <tt>RailsConnector::Configuration.enable(:seo_sitemap)</tt>
class SeoSitemapController < ApplicationController
  layout nil

  # Finds all objects which are to be shown in the SEO sitemap. Responds to xml only.
  def show
    @objects = Obj.find_all_for_sitemap
    respond_to { |format| format.xml }
  end

end
