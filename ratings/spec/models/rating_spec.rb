require "spec_helper"

module RailsConnector
  describe Rating, "Validations" do

    before do
      Rating.delete_all
      @attributes = {:obj_id => 23, :score => 1}
      @rating = Rating.new @attributes
    end

    it "should pass with all required attributes" do
      @rating.should be_valid
    end

    it "should fail with ratings below 1 or above 5" do
      @rating.attributes = @attributes.merge(:score => 6)
      @rating.should_not be_valid

      @rating.attributes = @attributes.merge(:score => 0)
      @rating.should_not be_valid
    end

    it "should fail with scores that are not numbers" do
      @rating.attributes = @attributes.merge(:score => 'A+')
      @rating.should_not be_valid
    end

    it "should fail if another rating for the same object with the SAME score exists" do
      @rating.save.should be_true
      Rating.new(@attributes).should_not be_valid
    end

    it "there can be another rating for the same object with a DIFFERENT score" do
      @rating.save.should be_true
      Rating.new(@attributes.merge(:score => 3)).should be_valid
    end

  end
end