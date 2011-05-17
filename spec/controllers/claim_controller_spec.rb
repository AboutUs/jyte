require 'spec_helper'

describe ClaimController do

  before(:each) do
    user = mock_model(User)
    user.stub!(:suspended?).and_return(false)
    user.stub!(:deleted?).and_return(false)
    user.stub!(:blocked_user_ids).and_return([])
    controller.stub!(:logged_in?).and_return(user.id)
    controller.stub!(:logged_in_user).and_return(user)
    controller.stub!(:liu).and_return(user) #alias doesnt seem to work with a stub
  end

  it "should list all claims" do
    controller.should_receive(:find_claims).and_return([[],{:count => 0}])
    get :find
  end

  it "should display an individual claim from someone else" do
    slug="tests-are-good"
    claim_user = mock_model(User)
    claim = mock_model(Claim)
    claim_user.should_receive(:vote_on).with(claim)
    claim_user.should_receive(:dn).and_return("full name")
    claim.should_receive(:user_id).twice.and_return(claim_user.id)
    claim.should_receive(:commented_at).and_return(Time.now)
    claim.should_receive(:state).exactly(3).times.and_return(1)
    claim.should_receive(:title).twice.and_return("Tests are good")
    claim.should_receive(:user).twice.and_return(claim_user)
    claim.should_receive(:yeas).and_return(1)
    claim.should_receive(:nays).and_return(0)
    claim.should_receive(:comments_count).and_return(0)
    claim.should_receive(:tag_list).and_return([])
    claim.should_receive(:valid?).and_return(true)
    claim.should_receive(:digest).and_return("")
    Claim.should_receive(:find_by_urlslug).with(slug, :conditions => 'state > 0').and_return(claim)
    Contact.should_receive(:find_by_user_id_and_contact_id)
    controller.should_receive(:votes_for_claim).and_return([nil, [], []])
    get :show, :urlslug => slug
    response.should render_template("claim/show")
  end
end
