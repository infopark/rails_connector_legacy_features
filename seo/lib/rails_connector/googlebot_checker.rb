module RailsConnector

  module GooglebotChecker
    require 'socket'

    protected

    def referer_is_google?
      return true if request.headers['Referer'] =~ /google/
    end

    def is_genuine_googlebot?(ip_address)
      if ip_address =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        host = reverse_dns_lookup_for_ip(ip_address)
        return false unless host =~ /googlebot.com$/
        res = forward_dns_matcher(host, ip_address)
        return res
      else
        return false
      end
    end

    private

    def reverse_dns_lookup_for_ip(ip_address)
      begin
        addr = Socket.gethostbyname(ip_address)
        Socket.gethostbyaddr(addr[3],Socket::AF_INET)[0]
      rescue
        []
      end
    end

    def forward_dns_matcher(host, ip_address)
      begin
        lookup = Socket.getaddrinfo(host, 0,
                  Socket::AF_INET, Socket::SOCK_STREAM, nil,
                  Socket::AI_CANONNAME)
        return true if lookup.collect {|info| info[3]}.uniq.include?(ip_address)
      rescue
        false
      end
      false
    end
  end
end
