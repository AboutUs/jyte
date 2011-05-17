require 'spec_helper'

describe "/claim/show" do
  before(:each) do
    claim = Factory.create(:claim)
    assigns[:claim] = claim
    assigns[:yea_vote_users] = []
    assigns[:nay_vote_users] = []
    assigns[:similar] = []
    assigns[:comments] = []
    render 'claim/show'
  end

  it "should display a claim" do
#    response.should have_tag('p', %r[Find me in app/views/auth/show])
  end
end
