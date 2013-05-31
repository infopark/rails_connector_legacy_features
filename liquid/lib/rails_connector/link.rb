module RailsConnector
  # This class provides an interfaces for handling CMS Links.
  # To format a link for rendering in an html page, use the +cms_path+ or +cms_url+ methods.
  # @api public
  class Link

    def to_liquid
      LiquidSupport::LinkDrop.new(self)
    end

  end
end
