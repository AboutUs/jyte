class ClaimVoteHistory < ActiveRecord::Base
  belongs_to :claim
  belongs_to :user

  def after_create
    if self.user_id != self.claim.user_id
      Happening.create(:happenable => self) unless self.claim.group_id
    end
  end
end
