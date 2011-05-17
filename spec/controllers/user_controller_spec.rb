require 'spec_helper'

describe UserController do

  before(:each) do
  end

  it "should find users by a cred tag" do
    get :tag, {:by => "cred", :tag=>"savior of the cred"}
  end

end
