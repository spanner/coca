require "spec_helper"
include Warden::Test::Helpers  

describe Coca::AuthenticationsController do
  before :each do
    Coca.stub(:valid_servant?).and_return(true)
  end

  # NB. we're not testing authentication here: only the controller responses in different auth scenarios.
  # The only place auth is actually tested is in the request specs.
  
  describe "Responding to auth checks" do

    describe "with an authenticated user" do
      before :each do
        @user = create(:local_user)
        authenticate(@user)
        get :show, :scope => "user", :format => :json
      end
      
      it 'should return a success code' do
        response.should be_successful
      end

      it 'should be json' do
        response.content_type.should == 'application/json'
      end

      it 'should be the right resource' do
        response.body.should == @user.to_json(:purpose => :coca)
      end
    end
    
    describe "without an authenticated user" do
      before :each do
        authenticate(nil)
        get :show, :scope => "user", :format => :json 
      end
      
      it "should return an invalid code" do
        response.should_not be_successful
        response.response_code.should == 401
      end

    end
  end

end
