module RailsConnector
  class Configuration

    # This module is an extension to the rails connector configuration.
    #
    # Configuration example:
    #
    #     RailsConnector::Configuration::GoogleAnalytics.domains(
    #       'www.example.de' => 'UA-example-1',
    #       'www.example.com' => 'UA-example-2'
    #     )
    module GoogleAnalytics
      @@domains = {}

      def self.domains=(domains_and_codes)
        @@domains = @@domains.merge(domains_and_codes)
      end

      def self.domains(domains_and_codes)
        self.domains = domains_and_codes
      end

      def self.domain_code(domain)
        @@domains[domain]
      end
    end

  end
end
