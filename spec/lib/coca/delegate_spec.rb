require 'spec_helper'

describe Coca::Delegate do

  describe "configuration" do
    before :each do
      @delegate = FactoryGirl.build(:delegate)
    end

    it "should have the default protocol" do
      @delegate.protocol.should == 'https'
    end

    it "should default to no port" do
      @delegate.port.should == nil
    end

    it "should have the default ttl" do
      @delegate.ttl.should == 600
    end

    it "should have the default path" do
      @delegate.path.should == '/coca/check.json'
    end

    it "should concatenate the correct url" do
      @delegate.url.to_s.should == "https://test.spanner.org/coca/check.json"
    end
    
    describe "with port setting" do
      before do
        @delegate.port = 8080
      end
      
      it "should build the correct url" do
        @delegate.url.to_s.should == "https://test.spanner.org:8080/coca/check.json"
      end
    end
  end


  describe "checking delegation" do
    before :each do
      Coca.check_referers = true
      @delegate = build(:delegate)
      @resolver = double('resolver')
      @ip = '1.1.1.1'
      Resolv.stub(:new).and_return(@resolver)
      @resolver.stub(:getaddress).and_return(@ip)
    end
    
    it "should work out its ip address" do
      @delegate.ip_address.should == @ip
    end
    
    it "should respond positively to a matching ip address" do
      @delegate.valid_referer?('1.1.1.1').should be_true
    end
    
    it "should respond negatively to a non-matching ip address" do
      @delegate.valid_referer?('1.2.3.4').should be_false
    end
  end

  describe "not checking delegation" do
    before :each do
      Coca.check_referers = false
      @delegate = build(:delegate)
      @resolver = double('resolver')
      @ip = '1.1.1.1'
      Resolv.stub(:new).and_return(@resolver)
      @resolver.stub(:getaddress).and_return(@ip)
    end
    
    it "should respond positively to a matching ip address" do
      @delegate.valid_referer?('1.1.1.1').should be_true
    end
    
    it "should respond positively to a non-matching ip address" do
      @delegate.valid_referer?('1.2.3.4').should be_true
    end
  end

  describe "delegating" do
    before :each do
      @delegate = build(:delegate)
      @user = create(:remote_user)
      @confirmation_package = @user.to_json(:purpose => :coca)
    end
      
    describe "successfully" do
      before :each do
        stub_request(:post, @delegate.url.to_s).to_return(:status => 200, :body => @confirmation_package)
      end
      
      it "should return the confirmation package" do
        @delegate.authenticate(:user, @credentials).should be_json_eql(@confirmation_package)
      end
    end
    
    describe "unsuccessfully" do 
      before :each do
        stub_request(:post, @delegate.url.to_s).to_return(:status => [401, "Unauthorized"])
      end
      
      it "should return nil" do
        @delegate.authenticate(:user, @credentials).should be_nil
      end
    end
    
  end
  
end