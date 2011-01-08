require 'spec_helper'

describe Relationship do
  before(:each) do
    @follower = Factory(:user)
    @followed = Factory(:user, :email => Factory.next(:email))
    @rel = @follower.relationships.build(:followed_id => @followed.id)
  end

  it "should create a new instance given valid attributes" do
    @rel.save!
  end

  it "should have a follower attribute" do
    @rel.should respond_to(:follower)
  end

  it "should respond with the right follower" do
    @rel.follower.should == @follower
  end

  it "should have a followed attribute" do
    @rel.should respond_to(:followed)
  end

  it "should respond with the right followed" do
    @rel.followed.should == @followed
  end

  describe "validations" do
    it "should have a follower" do
      @rel.follower = nil
      @rel.should_not be_valid
    end

    it "should have a followed" do
      @rel.followed = nil
      @rel.should_not be_valid
    end

  end
end
