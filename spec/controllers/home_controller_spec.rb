require 'spec_helper'

describe HomeController do

  before(:each) do
    user = mock_model(User)
    user.stub!(:suspended?).and_return(false)
    user.stub!(:deleted?).and_return(false)
    user.stub!(:blocked_user_ids).and_return([])
    controller.stub!(:logged_in?).and_return(user.id)
    controller.stub!(:logged_in_user).and_return(user)
    controller.stub!(:liu).and_return(user) #alias doesnt seem to work with a stub
    controller.stub!(:liuid).and_return(user.id) #alias doesnt seem to work with a stub
  end

  it "should display the index page" do
    get :index
    response.should render_template("home/index")
  end
end
