require "spec_helper"

describe "Coca authenticating" do
  before :each do
    @resolver = double('resolver')
    @ip = '1.1.1.1'
    @resolver.stub(:getaddress).and_return(@ip)
    Resolv.stub(:new).and_return(@resolver)
    stub_request(:post, "https://master.spanner.org/coca/check.json").to_return(:status => [401, "Unauthorized"])
  end

  describe "a local user by email and password" do
    before :each do
      @user = create(:local_user)
      post coca_check_url(:scope => 'user', :user => {:email => @user.email, :password => "testy"}), nil, 'HTTP_REFERER' => 'servant.spanner.org'
    end
    
    it 'should have the correct status code' do
      response.should be_successful
    end
  
    it 'should be json' do
      response.content_type.should == 'application/json'
    end
      
    it 'should have the right user' do
      response.body.should be_json_eql @user.to_json(:purpose => :coca)
    end
  end


  describe "a local user by auth token" do
    before :each do
      @user = create(:local_user)
      url = coca_check_url(:scope => 'user', :user => {:auth_token => @user.authentication_token})
      post url, 'HTTP_REFERER' => 'servant.spanner.org'
    end
    
    it 'should have the correct status code' do
      response.should be_successful
    end
  
    it 'should be json' do
      response.content_type.should == 'application/json'
    end
  
    it 'should have the right user' do
      response.body.should == @user.to_json(:purpose => :coca)
    end
  end
  
  
  describe "a remote user by email and password" do
    before :each do
      @remote_user = build(:remote_user)
      @confirmation_package = @remote_user.to_json(:purpose => :coca)
      stub_request(:post, "https://master.spanner.org/coca/check.json").to_return(:status => 200, :body => @confirmation_package)
      post coca_check_url(:scope => 'user', :user => {:email => @remote_user.email, :password => "testy"}), 'HTTP_REFERER' => 'servant.spanner.org'
    end
    
    it 'should have the correct status code' do
      response.should be_successful
    end
  
    it 'should be json' do
      response.content_type.should == 'application/json'
    end
      
    it 'should have the right user' do
      response.body.should be_json_eql(@confirmation_package)
    end
    
    it 'should have created a local user' do
      User.where(:name => @remote_user.name).first.should_not be_nil
    end
  end
  
  
  describe "an unknown user" do
    before :each do
      @non_user = build(:remote_user)
      post coca_check_url(:scope => 'user', :user => {:email => @non_user.email, :password => "testy"}), 'HTTP_REFERER' => 'servant.spanner.org'
    end
    
    it 'should have the correct status code' do
      response.code.should == "401"
    end
  end

end
