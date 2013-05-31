require "spec_helper"

module RailsConnector
  class Configuration

    describe GoogleAnalytics do
      describe "configuring domains and codes" do
        it "should return nil for unconfigured domains" do
          GoogleAnalytics.domain_code('www.example.com').should be_nil
        end

        it "should take a hash (per assignment)" do
          GoogleAnalytics.domains = { 'a' => 'b'}
          GoogleAnalytics.domain_code('a').should == 'b'
        end

        it "should take a hash (as argument)" do
          GoogleAnalytics.domains('x' => 'y')
          GoogleAnalytics.domain_code('x').should == 'y'
        end

        it "should merge configs" do
          GoogleAnalytics.domains = {'a1' => 'b1'}
          GoogleAnalytics.domains = {'a2' => 'b2'}
          GoogleAnalytics.domain_code('a1').should == 'b1'
          GoogleAnalytics.domain_code('a2').should == 'b2'
        end
      end
    end

  end
end
