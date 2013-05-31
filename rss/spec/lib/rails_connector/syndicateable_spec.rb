require "spec_helper"

module RailsConnector
  describe Syndicateable do
    before :all do
      class Model
        include Syndicateable

        def body
          'example'
        end
      end

      @model = Model.new
    end

    it "should have #rss_description instance method" do
      @model.respond_to?(:rss_description).should be_true
    end

    describe "#rss_description" do
      it "should return by default the body" do
        @model.rss_description.should == 'example'
      end
    end
  end
end
