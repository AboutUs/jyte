class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :claim

  acts_as_tree # threaded comments
  acts_as_solr :fields => [:body]

  has_many :claimings, :as => :claimable, :dependent => :destroy

  validates_presence_of :body, :user_id, :claim_id

  # used when preparing comments for a claim
  attr_accessor :child_ids

  def inspired_claims
    x = []
    claimings.each {|c| x << c.claim if c.claim.state == 1}
    return x
  end

  def validate_on_create
    Comment.find_all_by_claim_id_and_user_id(claim_id, user_id).each {|c|
      errors.add(:body, "Duplicate!") if c.body == body
    }
  end

  def validate
    unless self.parent_id.nil? or self.claim_id == self.parent.claim_id
      errors.add(:parent_id, "Comment and parent must be on same claim.")
    end
  end

  def after_create
    cl = self.claim

    Happening.create(:happenable => self) if cl.state == 1

    # notify the owner of the parent of this comment
    # XXX: user preferences
    if self.parent_id and self.parent.user_id != self.user_id
      self.parent.user.dispatch(self, :reason => 'comment')
    elsif self.claim.user_id != self.user_id
      cl.user.dispatch(self, :reason => 'comment')
    end
    cl.watchers.each {|u|
      u.dispatch(self, :reason => 'comment') unless self.user_id == u.id
    }
    cl.mentioned_users.each {|u|
      u.dispatch(self, :reason => 'comment') unless self.user_id == u.id
    }

    cl.comments_count += 1
    cl.commented_at = DateTime.now
    cl.save

    # don't index comments on group claims
    if cl.state == 1
      self.solr_save
    end
    
  end

  # current vote at time of comment
  def user_vote
    ClaimVote.find(:first, :conditions => "user_id = #{self.user_id} AND claim_id = #{self.claim_id}", :order => "created_at DESC")
    #AND created_at < '#{self.created_at_before_type_cast}'"
  end

end
