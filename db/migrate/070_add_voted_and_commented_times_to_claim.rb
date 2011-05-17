class AddVotedAndCommentedTimesToClaim < ActiveRecord::Migration
  def self.up
    add_column :claims, :voted_at, :datetime
    add_column :claims, :commented_at, :datetime
    Claim.find(:all).each{|c|
      v = ClaimVote.find_by_claim_id(c.id, :order => 'created_at DESC')
      c.voted_at = v.created_at if v
      com = Comment.find_by_claim_id(c.id, :order => 'created_at DESC')
      c.commented_at = com.created_at if com
      c.save
    }
  end

  def self.down
    add_column :claims, :voted_at
    add_column :claims, :commented_at
  end
end
