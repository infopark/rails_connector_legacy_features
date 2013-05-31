require 'liquid'

# A collection of modules and classes needed to enable Liquid templates with Rails Connector
# @api public
module RailsConnector::LiquidSupport

  # Helpers can be made available in Liquid templates by enabling them in the
  # app initialization like this:
  #
  #    RailsConnector::LiquidSupport.enable_helpers(
  #       :helper_a,
  #       :helper_b
  #     )
  # @api public
  def self.enable_helpers(*helpers)
    helpers.each do |helper|
      GeneralHelperTag << helper
    end
  end

  # set to +true+ if an error in a liquid template should lead to an 500 server error
  # @api public
  mattr_accessor :raise_template_errors

end