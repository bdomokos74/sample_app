require 'spec_helper'

describe User do
  before(:each) do
    @attr = {:name                  => "Example User",
             :email                 => "user@example.com",
             :password              =>"foobar",
             :password_confirmation =>"foobar"
    }

  end

  it "should create a new instance given valid attributes" do
    User.create!(@attr)
  end

  it "should not accept blank user name" do
    no_name_user = User.new(@attr.merge({:name=>""}))
    no_name_user.should_not be_valid
  end

  it "should require an email address" do
    no_email_user = User.new(@attr.merge({:email=>""}))
    no_email_user.should_not be_valid
  end

  it "should reject names which are too long" do
    long_name      = "a"*51
    long_name_user = User.new(@attr.merge(:name=>long_name))
    long_name_user.should_not be_valid
  end

  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      valid_email_user.should be_valid
    end
  end

  it "should reject invalid email addresses" do
    addresses = %w[user@foo.,com THE_USER_foo.bar.org first.last@foo.]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      invalid_email_user.should_not be_valid
    end
  end

  it "should reject duplicate email addresses" do
    User.create!(@attr)
    duplicate_user = User.new(@attr)
    duplicate_user.should_not be_valid
  end

  it "should reject email addresses identical up to case" do
    uppercased_email = @attr[:email].upcase
    User.create!(@attr.merge(:email => uppercased_email))
    duplicate_user = User.new(@attr)
    duplicate_user.should_not be_valid
  end

  describe "password validations" do
    it "should require a password" do
      user = User.new(@attr.merge(:password =>"", :password_confirmation =>""))
      user.should_not be_valid
    end

    it "should require a matching password confirmation" do
      user = User.new(@attr.merge(:password_confirmation =>"invalid"))
      user.should_not be_valid
    end

    it "should reject short passwords" do
      short_pass = "a"*5
      user       = User.new(@attr.merge(:password =>short_pass, :password_confirmation =>short_pass))
      user.should_not be_valid
    end

    it "should reject long passwords" do
      long_pass = "a"*41
      user      = User.new(@attr.merge(:password =>long_pass, :password_confirmation =>long_pass))
      user.should_not be_valid
    end

    it "should create a new instance given valid params" do
      User.create!(@attr)
    end
  end

  describe "password encryption" do
    before(:each) do
      @user = User.create!(@attr)
    end

    it "should have an encrypted_password attribute" do
      @user.should respond_to(:encrypted_password)
    end

    it "should set the encrypted password" do
      @user.encrypted_password.should_not be_blank
    end

    describe "has_password? method" do
      it "should be true if the passwords match" do
        @user.has_password?(@attr[:password]).should be_true
      end

      it "should be false if the passwords do not match" do
        @user.has_password?("invalid").should be_false
      end
    end

    describe "authenticate method" do
      it "should return nil on email/pw mismatch" do
        wrong_pw_user = User.authenticate(@attr[:email], "wrongpass")
        wrong_pw_user.should be_nil
      end

      it "should return nil on email with no user" do
        wrong_pw_user = User.authenticate("foo@bar.doesnt.exist", @attr[:password])
        wrong_pw_user.should be_nil
      end

      it "should return the user if user/pw match" do
        matching_user = User.authenticate(@attr[:email], @attr[:password])
        matching_user.should == @user
      end
    end
  end

  describe "admin attribute" do
    before(:each) do
      @user = User.create!(@attr)
    end

    it "should respond to admin" do
      @user.should respond_to(:admin)
    end

    it "should not be an admin by default" do
      @user.should_not be_admin
    end

    it "should be convertible to admin" do
      @user.toggle!(:admin)
      @user.should be_admin
    end
  end

  describe "micropost associations" do
    before(:each) do
      @user = User.create(@attr)
      @mp1  = Factory(:micropost, :user => @user, :created_at => 1.day.ago)
      @mp2  = Factory(:micropost, :user => @user, :created_at => 1.hour.ago)
    end

    it "should have a microposts attribute" do
      @user.should respond_to(:microposts)
    end

    it "should have the microposts in the right order" do
      @user.microposts.should == [@mp2, @mp1]
    end

    it "should destroy associated microposts" do
      @user.destroy
      Micropost.find_by_id(@mp1.id).should be_nil
      Micropost.find_by_id(@mp2.id).should be_nil
    end

    describe "status feed" do
      it "should have a feed" do
        @user.should respond_to(:feed)
      end

      it "should include the user's microposts" do
        @user.feed.should include(@mp1)
        @user.feed.should include(@mp2)
      end

      it "should not include other user's microposts" do
        mp3 = Factory(:micropost,
                      :user => Factory(:user, :email => Factory.next(:email)))
        @user.feed.should_not include(mp3)
      end

      it "should include the microposts of followed users" do
        followed = Factory(:user, :email => Factory.next(:email))
        mp3 = Factory(:micropost, :user => followed)
        @user.follow!(followed)
        @user.feed.should include(mp3)
      end
    end
  end

  describe "relationships" do
    before(:each) do
      @user     = User.create!(@attr)
      @followed = Factory(:user)
    end

    it "should have a relationships method" do
      @user.should respond_to(:relationships)
    end

    it "should have a following method" do
      @user.should respond_to(:following)
    end

    describe "follow!" do
      it "should respond to follow!" do
        @user.should respond_to(:follow!)
      end

      it "should add a relationship" do
        @user.follow!(@followed)
        @user.following.should include(@followed)
      end
    end

    describe "following?" do
      it "should respond to following?" do
        @user.should respond_to(:following?)
      end

      it "should not follow anybody by default" do
        @user.following?(@followed).should be_false
      end

      it "should return true for a followed user" do
        @user.relationships.create!(:followed_id => @followed.id)
        @user.following?(@followed).should be_true
      end
    end

    describe "unfollow!" do
      it "should respond to unfollow!" do
        @user.should respond_to(:unfollow!)
      end

      it "should not follow a user after unfollow!" do
        @user.follow!(@followed)
        @user.unfollow!(@followed)
        @user.should_not be_following(@followed)
      end
    end

    it "should have a reverse_relationships method" do
      @user.should respond_to(:reverse_relationships)
    end

    it "should have a followers method" do
      @user.should respond_to(:followers)
    end

    it "should include a follower in the followers array" do
      @user.follow!(@followed)
      @followed.followers.should include(@user)
    end
  end
end

