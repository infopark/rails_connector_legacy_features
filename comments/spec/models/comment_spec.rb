require "spec_helper"

describe Comment, "Validations" do
  before do
    @attributes = {
     :name => "John Smith",
     :subject => "A subject",
     :email => "john@smith.xyz",
     :body => "Some content"
   }

    @comment = Comment.new @attributes
  end

  it "should pass with all required attributes" do
    @comment.should be_valid
  end

  it "should fail when missing a required attribute" do
    @attributes.each_key do |key|
      @comment.attributes = @attributes.merge(key => '')
      @comment.should_not be_valid
    end
  end

  it "should fail with invalid email addresses" do
    ['foo', 'foo@', 'foo@bar'].each do |email|
      @comment.email = email
      @comment.should_not be_valid
    end
  end
end
