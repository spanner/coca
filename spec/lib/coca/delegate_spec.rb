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
      @delegate.ttl.should == 1800
    end

    it "should have the default path" do
      @delegate.path.should == '/coca/user'
    end

    it "should concatenate the correct url" do
      @delegate.url.to_s.should == "https://test.spanner.org/coca/user"
    end
    
    describe "with port setting" do
      before do
        @delegate.port = 8080
      end
      
      it "should build the correct url" do
        @delegate.url.to_s.should == "https://test.spanner.org:8080/coca/user"
      end
    end
  end


  describe "checking delegation" do
    before :each do
      @delegate = build(:delegate)
      @resolver = double('resolver')
      @ip = '1.1.1.1'
      Resolv.should_receive(:new).and_return(@resolver)
      @resolver.should_receive(:getaddress).and_return(@ip)
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

  describe "delegating" do
    before :each do
      @delegate = build(:delegate)
      @user = create(:user)
      @confirmation_package = @user.serializable_hash
    end
      
    describe "successfully" do
      before :each do
        stub_request(:get, @delegate.url.to_s).to_return(:status => 200, :body => @confirmation_package)
      end
      
      it "should return the confirmation package" do
        @delegate.authenticate(@credentials).should == @confirmation_package
      end
    end
    
    describe "unsuccessfully" do 
      before :each do
        stub_request(:get, @delegate.url.to_s).to_return(:status => [401, "Unauthorized"])
      end
      
      it "should return nil" do
        @delegate.authenticate(@credentials).should be_nil
      end
    end
    
  end
  
end