module RailsConnector

  class LiquidConfiguration

    class << self
      # Automatically generate editmarkers when rendering liquid templates in editor mode.
      # @api public
      attr_accessor :auto_liquid_editmarkers

    end

    # defaults
    self.auto_liquid_editmarkers = true
  end

end
