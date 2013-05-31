require 'rspec/rails'

RailsConnector::Configuration::GoogleAnalytics.domains(
  'test.host' => 'UA-test',
  'www.infopark.de' => 'UA-528505-1',
  'www.infopark.com' => 'UA-528505-2'
)
