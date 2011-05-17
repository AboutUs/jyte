class Vote < ActiveRecord::Base
  belongs_to :votable, :counter_cache => true 
  belongs_to :user
  validates_associated :votable, :user
  validates_presence_of :votable, :user

  def Vote.find_all_by_user_id_and_claim_ids(user_id, claim_ids)
    return [] if user_id.nil? or claim_ids.empty? 
    conditions = claim_ids.collect {|cid| "(votables.votable_id = #{cid} AND votables.votable_type = 'Claim')"}.join(' OR ')
    conditions = "votes.user_id = #{user_id} AND votes.current = 1 AND (#{conditions})"
    votes = Vote.find(:all,
                      :joins => "LEFT OUTER JOIN votables ON votables.id = votes.votable_id",
                      :conditions => conditions)
    votes_by_claim_id = {}
    votes.each {|v| votes_by_claim_id[v.votable_id] = v}
    return votes_by_claim_id
  end

  def validate_on_create
    old_vote = Vote.find_by_votable_id_and_user_id(self.votable_id, self.user_id, :conditions => 'current = true')
    old_vote.expire if old_vote
  end
  
  def after_create
    v = votable 
    if self.vote
      v.up_count += 1
    else
      v.down_count += 1
    end
    v.save
  end

  # since votes are destroyed along with the users they belong to
  def before_destroy
    v = votable 
    if self.vote
      v.up_count -= 1
    else
      v.down_count -= 1
    end
    v.save
  end

  def expire
    self.current = false
    v = votable
    if self.vote
      v.up_count -= 1
    else
      v.down_count -= 1
    end
    v.save
    save
  end

  def target
    return votable.votable
  end
  alias claim target
  alias comment target

end
