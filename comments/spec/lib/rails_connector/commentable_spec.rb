require "spec_helper"

module RailsConnector
  describe Commentable, "when included in a model", :required_feature => "comments" do

    def enable_comments(obj)
      class << obj; include Commentable; end
    end

    let(:obj) {
      Obj.root.tap do |o|
        o or raise "Required obj root is missing"
        enable_comments(o)
      end
    }

    let(:other) {
      path = "/dokument"
      Obj.find_by_path(path).tap do |o|
        o or raise "Required obj '#{path}' is missing"
        enable_comments(o)
      end
    }

    before do
      Comment.find(:all).map(&:destroy)
    end

    it "should provide #allow_comments? returning true" do
      obj.allow_comments?.should be_true
    end

    it "should provide #allow_anonymous_comments? returning true" do
      obj.allow_anonymous_comments?.should be_true
    end

    it "should have (no) comments" do
      obj.comments.should == []
    end

    describe "when comments have been added" do
      def create_comment(o, subject)
        required_properties = {:name => "name", :body => "name", :email => "e@ma.il"}
        o.comments.create!({:subject => "comment of #{subject}"}.merge(required_properties))
      end

      before do
        2.times do |i|
          create_comment(other, "other obj ##{i + 1}")
        end
        3.times do |i|
          create_comment(obj, "obj ##{i + 1}")
        end
      end

      it "should return the comments associated with the model in order of creation" do
        obj.comments.tap do |associated_comments|
          associated_comments.size.should == 3
          associated_comments.should be_all {|c| ::Comment === c}
          associated_comments.map(&:subject).should == [
            "comment of obj #1",
            "comment of obj #2",
            "comment of obj #3",
          ]
        end
      end
    end
  end
end
