# {UserHelper} is a wrapper around {RailsConnector::DefaultUserHelper}.
# It can be replaced in your application in order to add or
# modify helpers.
module UserHelper
  include RailsConnector::DefaultUserHelper
end