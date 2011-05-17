class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => [:group_id]
  
  def before_destroy
    ClaimVote.find_by_sql(["SELECT claim_votes.* FROM claim_votes 
                               JOIN claims ON claims.group_id = ? 
                                          AND claim_votes.claim_id = claims.id 
                                          AND claim_votes.user_id = ?",
                           self.group_id, self.user_id]).each{ |v| v.destroy }
  end

  def after_destroy
    if group.group_memberships.empty?
      group.destroy
    end
  end
end
