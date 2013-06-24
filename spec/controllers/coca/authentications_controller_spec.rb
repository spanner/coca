require "spec_helper"

describe Coca::AuthenticationsController do
  before :each do
    @user = create(:user)
  end

  describe "Authenticating a user" do
    describe "with a valid email/password pair" do
      before :each do
        get :authenticate, :version => 1, :email => @user.email, :password => 'testy'
      end
      
      it 'should return a success code' do
        response.should be_successful
      end

      it 'should be json' do
        response.content_type.should == 'application/json'
      end

      it 'should be the right sort of resource' do
        response.should be_singular_resource
      end

      it "should return the user package" do
        response.should have_exposed @user
      end
      
    end
    
    describe "with an invalid email/password pair" do
      before :each do
        get :authenticate, :version => 1, :email => @user.email, :password => 'not_testy'
      end
      
      describe "and no upstream authentication" do
        before do
          # stub upstream auth call and return 401
        end
        it "should return an invalid code"
      end
      
      describe "confirmed by upstream authentication" do
        before do
          # stub upstream auth call and return 401
        end
        it 'should return a success code'
        it 'should be the right sort of resource'
        it 'should create a local user'
      end

    end

    describe "with a valid authentication token" do
      before :each do
        get :authenticate, :version => 1, :authentication_token => 'amigo!'
      end
      
      it 'should return a success code' do
        response.should be_successful
      end

      it 'should be json' do
        response.content_type.should == 'application/json'
      end

      it 'should be the right sort of resource' do
        response.should be_singular_resource
      end

      it "should return the user package" do
        response.should have_exposed @user
      end
      
    end
    
    describe "with an invalid authentication token" do
      before :each do
        get :authenticate, :version => 1, :authentication_token => 'Yes sir, I can boogie'
      end
      
      describe "and no upstream authentication" do
        it "should return an invalid code"
      end
      
    end

  end

end
