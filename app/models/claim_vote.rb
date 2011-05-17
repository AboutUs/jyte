class ClaimVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :claim, :counter_cache => true
  validates_associated :user, :claim
  validates_presence_of :user, :claim
  validates_uniqueness_of :user_id, :scope => [:claim_id]
 
  attr_accessor :contact_msg
 
  def self.find_all_by_user_id_and_claim_ids(user_id, claim_ids)
    return [] if user_id.nil? or claim_ids.empty?
    find(:all, :conditions => "user_id = #{user_id} AND claim_id IN (#{claim_ids.join(',')})")
  end

  def self.find_all_votes_hash(user_id, claim_ids)
    results = find_all_by_user_id_and_claim_ids(user_id, claim_ids)
    h = {}
    results.each {|v| h[v.claim_id] = v}
    return h
  end

  def validate_on_create
   # old_vote = ClaimVote.find_by_claim_id_and_user_id(self.claim_id, self.user_id, :conditions => 'current = true')
   # if old_vote
   #   old_vote.expire
   #   self.claim.reload
   # end
  end
 
  def after_save
    # update the claim vote counts
    vote_time = Claim.connection.quoted_date(DateTime.now)
    (1..3).each{|i|
      begin
        ActiveRecord::Base.transaction {
          Claim.connection.update("UPDATE claims SET yeas = (SELECT COUNT(*) FROM claim_votes WHERE claim_id = #{self.claim_id} AND vote = true), nays = (SELECT COUNT(*) FROM claim_votes WHERE claim_id = #{self.claim_id} AND vote = false), voted_at = '#{vote_time}' WHERE id = #{self.claim_id}")

          ClaimVoteHistory.create(:user_id => self.user_id, :claim_id => self.claim_id, :vote => self.vote)
        }
        break;
      rescue ActiveRecord::StatementInvalid
        if i == 3
          raise
        end
      end
    }
  end

  def after_destroy
    if vote
      Claim.connection.update("UPDATE claims SET yeas = yeas - 1 WHERE id = #{self.claim_id}")
    else
      Claim.connection.update("UPDATE claims SET nays = nays - 1 WHERE id = #{self.claim_id}")
    end
  end


end

