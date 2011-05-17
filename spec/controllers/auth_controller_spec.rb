require 'spec_helper'

describe AuthController do

  # long tests mean long methods that need refactoring
  it "should process the RPX response and login an existing user" do
    params = {"token"=>"1890b61ae089bcfcf4543b6419a3935258359f0d"}
    openid="http://donpdonp.myopenid.com"
    rpx_response = {"profile"=>{"name"=>{"formatted"=>"Don Park"},"photo"=>"http=>\/\/www.myopenid.com\/image?id=18601","displayName"=>"Don Park","preferredUsername"=>"donpdonp","url"=>"http=>\/\/donpdonp.myopenid.com\/","utcOffset"=>"-08:00","gender"=>"male","providerName"=>"MyOpenID","identifier"=>openid,"email"=>"don.park@gmail.com"},"stat"=>"ok"}
    controller.should_receive(:http_request).and_return(rpx_response)

    user = mock_model(User)
    user.should_receive(:last_login_at=)
    user.should_receive(:last_login_ip=)
    user.should_receive(:save)
    identifier = mock_model(Identifier)
    identifier.should_receive(:user).and_return(user)
    Identifier.should_receive(:find_or_create_by_value).with(openid).and_return(identifier)
    get :rpx_response, params
    session[:user_id].should == user.id
  end

  # long tests mean long methods that need refactoring
  it "should process the RPX response, create a new user, and login that user" do
    openid="http://donpdonp.myopenid.com"
    login_dance(openid)
  end

  it "should process the RPX response, create a new user, and login that user even with a crazy google url" do
    openid='https://www.google.com/accounts/o8/id?id=AItOawmFBtpAuPpMph6D-S11FQbtFwOEbNFCt3I'
    login_dance(openid)
  end

  def login_dance(openid_url)
    params = {"token"=>"1890b61ae089bcfcf4543b6419a3935258359f0d"}
    rpx_response = {"profile"=>{"name"=>{"formatted"=>"Don Park"},"photo"=>"http=>\/\/www.myopenid.com\/image?id=18601","displayName"=>"Don Park","preferredUsername"=>"donpdonp","url"=>"http=>\/\/donpdonp.myopenid.com\/","utcOffset"=>"-08:00","gender"=>"male","providerName"=>"MyOpenID","identifier"=>openid_url,"email"=>"don.park@gmail.com"},"stat"=>"ok"}
    controller.should_receive(:http_request).and_return(rpx_response)

    user = mock_model(User)
    user.should_receive(:set_state).with(:early_adopter)
    user.should_receive(:last_login_at=)
    user.should_receive(:created_ip=)
    user.should_receive(:last_login_ip=)
    user.should_receive(:nickname=)
    user.should_receive(:settings=)
    user.should_receive(:valid?).and_return(true)
    user.should_receive(:save!)
    user.should_receive(:email=)
    user.should_receive(:save)
    user.should_receive(:claims_about).and_return([])
    User.should_receive(:new).and_return(user)
    identifier = mock_model(Identifier)
    identifier.should_receive(:user)
    identifier.should_receive(:primary=).with(true)
    identifier.should_receive(:user_id=).with(user.id)
    identifier.should_receive(:save!)
    Identifier.should_receive(:find_or_create_by_value).with(openid_url).twice.and_return(identifier)
    get :rpx_response, params
    session[:user_id].should == user.id
  end

end
