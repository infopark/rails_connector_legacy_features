module RailsConnector
  #
  # This class provides a default controller implementation for rendering an RSS feed.
  # It should be customized by subclassing.
  #
  # The RSS feature assumes that you have a root object specified whose direct children will be used as feed entries.
  #
  # Specify the RSS root in
  # <code><em>RAILS_ROOT</em>/config/initializers/rails_connector.rb</code>:
  #   RailsConnector::Configuration::Rss.root = lambda { NamedLink.get_object('news') }
  class DefaultRssController < DefaultCmsController
    #
    # This action renders the built-in RSS feed.
    #
    # To customize feed's layout, override either this method, or the apropriate view.
    #
    # @return [void]
    def index
      respond_to do |format|
        format.rss
      end
    end

    protected

    def load_object
      @obj = Configuration::Rss.root
    end
  end
end
