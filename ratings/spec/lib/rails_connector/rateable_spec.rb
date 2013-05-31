require "spec_helper"

module RailsConnector
  describe Rateable, "when included into Obj", :required_feature => "ratings" do

    def create_rating(ratings = {})
      ratable = Obj.root
      Rating.delete_all
      ratings.each_pair do |score, count|
        Rating.create(:obj_id => ratable.id, :score => score, :count => count)
      end
      ratable
    end

    describe "when checking if an object is rateable" do
      before do
        @obj = Obj.new
      end

      it "should allow rating" do
        @obj.allow_rating?.should be_true
      end

      it "should allow anonymous rating" do
        @obj.allow_anonymous_rating?.should be_true
      end
    end

    describe "when casting the initial rating for a particular score, the rating counter" do
      before do
        @obj = create_rating(3 => 7)
        @obj.rate(2)
      end

      it "should be set to 1 for the that score" do
        @obj.count_for_score(2).should == 1
      end

      it "should not change for other scores" do
        @obj.count_for_score(3).should == 7
      end
    end

    describe "when casting a consecutive rating for a particular score, the rating counter" do
      before do
        @obj = create_rating(3 => 1, 2=> 9)
        @obj.rate(3)
      end

      it "should increase by 1 for that score" do
        @obj.count_for_score(3).should == 2
      end

      it "should not change for other scores" do
        @obj.count_for_score(2).should == 9
      end

    end

    describe "a document rated with several scores" do
      before do
        @obj = create_rating(1 => 10, 4 => 20)
      end

      it "should have a rating" do
         @obj.should be_rated
      end

      it "should have an average rating" do
        @obj.average_rating.should == 3.0
      end

      it "should have an average rating in percent" do
        @obj.average_rating_in_percent.should == 60
      end

      it "can be resetted" do
        @obj.reset_rating
        @obj.should_not be_rated
      end
    end

    describe "a document which has never been rated" do
      before do
        @obj = create_rating
        @obj.stub(:ratings).and_return([])
      end

      it {@obj.should_not be_rated}

      it "should not have an average rating" do
        lambda { @obj.average_rating }.should raise_error(TypeError)
      end

      it "should have an average rating of 0 percent" do
        @obj.average_rating_in_percent.should == 0
      end
    end
  end
end
