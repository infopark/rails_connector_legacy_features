module RailsConnector::LiquidSupport

  # Dieser Drop kapselt einen Link.
  class LinkDrop < Liquid::Drop
    def initialize(link)
      @link = link
    end

    def __drop_content
      @link
    end

    [:url, :external?, :internal?, :title, :display_title].each do |m|
      define_method(m) { @link.__send__(m).to_liquid }
    end

    def destination
      @link.destination_object.to_liquid
    end
  end

end