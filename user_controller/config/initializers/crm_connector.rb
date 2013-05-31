# require 'infopark_crm_connector'
#
# Infopark::Crm.configure do |config|
#   config.url = "http://<crm-domain>:<port>"
#   config.login = 'webservice'
#   config.api_key = '<password>'
#   # config.live_server_groups_callback = lambda {|contact|
#   #   case contact.account.name
#   #   when "My Company"
#   #     %w(internal)
#   #   else
#   #     []
#   #   end
#   # }
# end
#
# RailsConnector::Crm.enable
