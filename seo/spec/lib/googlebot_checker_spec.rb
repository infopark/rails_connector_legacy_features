require "spec_helper"

module RailsConnector

    dns_lookup_genuine = [
      ['AF_INET', 0, 'crawl-66-249-66-1.googlebot.com', '66.249.66.1', 2, 1, 6],
      ['AF_INET', 0, 'crawl-66-249-66-1.googlebot.com', '66.249.66.1', 2, 1, 6]
    ]

    dns_lookup_false = [
      ['AF_INET', 0, 'crawl-66-249-66-1.googlefake.com', '66.249.66.1', 2, 2, 17],
      ['AF_INET', 0, 'crawl-66-249-66-1.googlefake.com', '66.249.66.2', 2, 1, 6]
    ]

  describe 'When checking if genuine googlebot' do
    include GooglebotChecker
    google_host = 'crawl-123-123-123-123-1.googlebot.com'
    it 'should return true if given ip-address belongs to googlebot.com' do
      should_receive(:reverse_dns_lookup_for_ip).with('123.123.123.123').and_return(google_host)
      should_receive(:forward_dns_matcher).with(google_host, '123.123.123.123').and_return true
      is_genuine_googlebot?('123.123.123.123').should be_true

    end

    it 'should return false if given ip_address does not belong to a genuine googlebot.com' do
      should_receive(:reverse_dns_lookup_for_ip).with('123.123.123.123').and_return(google_host)
      should_receive(:forward_dns_matcher).with(google_host, '123.123.123.123').and_return false
      is_genuine_googlebot?('123.123.123.123').should be_false

    end

    it 'should return false if no ip-address was given' do
      is_genuine_googlebot?('').should be_false
    end
  end

  describe 'reverse_lookup' do
    include GooglebotChecker
    it 'should return a hostname' do
      pending 'Depends on what you have written in /etc/hosts ...'
      ip_address = '127.0.0.1'
      reverse_dns_lookup_for_ip(ip_address).should == 'localhost'
    end

    it 'should not raise an error if getaddrinfo fails' do
      Socket.should_receive(:gethostbyname).with('666.666.666.666').and_raise(SocketError)
      lambda { reverse_dns_lookup_for_ip('666.666.666.666') }.should_not raise_error
    end
  end

  describe 'forward_dns_matcher' do
    include GooglebotChecker
    it "should return true if one of the hostnames belongs to 'ip_address'" do
      Socket.should_receive(:getaddrinfo).with('some_host.de', 0, Socket::AF_INET,
       anything(),anything(),anything()).and_return(dns_lookup_genuine)

      forward_dns_matcher('some_host.de', '66.249.66.1').should be_true
    end

    it "should return false if none of the hostnames belong to 'ip_address'" do
      Socket.should_receive(:getaddrinfo).with('other_host.com', 0, Socket::AF_INET,
       anything(),anything(),anything()).and_return(dns_lookup_false)

      forward_dns_matcher('other_host.com', '66.249.66.111').should be_false
    end

    it 'should not raise if getaddrinfo terminates with an exception' do
      Socket.should_receive(:getaddrinfo).with('some_host.de', 0, Socket::AF_INET,
       anything(),anything(),anything()).and_raise(SocketError)
      lambda {forward_dns_matcher('some_host.de', '666.666.666.666')}.should_not raise_error
    end
  end

  describe 'referer_is_google?' do
    include GooglebotChecker
    it 'should return true if the http_referer of the request is google' do
      @mock_request = mock('Request', :headers => {'Referer' => 'www.google.de'} )

      should_receive(:request).and_return(@mock_request)
      referer_is_google?.should be_true
    end

    it 'should return true if the http_referer of the request is google' do
      @mock_request = mock('Request', :headers => {'Referer' => 'yahoo.de'} )

      should_receive(:request).and_return(@mock_request)
      referer_is_google?.should be_nil
    end
  end
end
