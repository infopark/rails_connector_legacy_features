require "spec_helper"

module RailsConnector
  describe ConfirmationMailer do
    describe "#request_password_confirmation" do
      let(:mail) do
        ConfirmationMailer.reset_password("john@smith.com",
            "http://securedlink.com?code=ABC")
      end

      it "should send the confirmation url" do
        mail.to.should eq(%w(john@smith.com))
        mail.subject.should eq("Your request for changing your password")
        mail.body.should match(/http:\/\/securedlink.com\?code=ABC/)
      end
    end

    describe "#register_confirmation" do
      let(:mail) do
        ConfirmationMailer.register_confirmation("john@smith.com",
            "http://securedlink.com?code=ABC")
      end

      it "should send the confirmation url" do
        mail.to.should eq(%w(john@smith.com))
        mail.subject.should eq("Please confirm your registration")
        mail.body.should match(/http:\/\/securedlink.com\?code=ABC/)
      end
    end
  end
end
