require "spec_helper"

describe User do
  before :each do
    @user = FactoryGirl.create(:user)
  end

  describe "created locally" do
    it "should give itself a uid" do
      @user.uid.should_not be_blank
    end

    it "should give itself an authentication_token" do
      @user.authentication_token.should_not be_blank
    end
  end

end
