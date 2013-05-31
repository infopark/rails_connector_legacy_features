module RailsConnector

  # This helper provides methods for Search Engine Optimization.
  module SeoHelper

    # Generate search engine optimized meta tags for the html head.
    #
    # Example:
    #
    #   seo_header_tags(
    #     :company_name => 'Infopark AG',
    #     :default_keywords => 'default, key, words',
    #     :default_description => 'one description for all views using this layout'
    #   )
    #
    #   # =>
    #
    #   <title>Dialog im Web. | Infopark AG</title>
    #   <meta name="description" content="SEO description of the current page" />
    #   <meta content="default, key, words" name="keywords" />
    #   <meta content="Rails Connector for Infopark CMS Fiona by Infopark AG (www.infopark.de); Version 6.7.1" name="generator" />
    #   <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    #   <link href="http://test.host/2001/basisordner" rel="canonical" />
    def seo_header_tags(options = {})
      html = content_tag('title', [@obj && @obj.display_title, options[:company_name]].compact.join(' | '))
      html += tag('meta', :name => 'description', :content => @obj && @obj.seo_description || options[:default_description])
      html += tag('meta', :name => 'keywords', :content => seo_keywords(options))
      html += tag('meta', 'http-equiv' => "Content-Type", :content => "text/html; charset=utf-8")
      html += tag('link', :rel => 'canonical', :href => canonical_url) if @obj
      html
    end

  private

    def seo_keywords(options)
      (@obj && @obj.seo_keywords.to_s.strip).blank? ? options[:default_keywords] : @obj.seo_keywords.strip
    end

    def canonical_url
      cms_path_or_url_for_objs(@obj, :url, :protocol => request.ssl? ? 'https' : 'http')
    end
  end

end
