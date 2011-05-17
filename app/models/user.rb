class User < ActiveRecord::Base
  serialize :settings, Hash
  has_many :claims, :conditions => 'state = 1'
  has_many :all_claims, :class_name => 'Claim', :dependent => :destroy
  has_many :votes, :class_name => 'ClaimVote', :dependent => :destroy
  has_many :vote_histories, :class_name => 'ClaimVoteHistory', :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_many :group_memberships, :dependent => :destroy
  has_many :groups, :through => :group_memberships
  has_many(:created_groups,
           :class_name => 'Group',
           :foreign_key => 'user_id',
           :dependent => :destroy)

  # contact associations
  has_many :contacts_as_contact, :foreign_key => 'contact_id', :class_name => 'Contact', :dependent => :destroy
  has_many :contacts_as_contacter, :foreign_key => 'user_id', :class_name => 'Contact', :dependent => :destroy
  has_many :contacts, :through => :contacts_as_contacter
  has_many :contacters, :through => :contacts_as_contact

  # identifier associations
  has_many :identifiers, :dependent => :nullify
  has_one :identifier, :conditions => 'identifiers.primary = true'

  has_many :dispatches, :dependent => :destroy
  has_one :first_dispatch, :class_name => "Dispatch", :order => 'created_at'

  has_many(:dispatched, :class_name => 'Dispatch',
           :conditions => ["dispatchable_type = 'User'"],
           :foreign_key => 'dispatchable_id',
           :dependent => :destroy)

  # looks
  has_many :looks, :dependent => :destroy
  has_many(:viewings,
           :class_name => 'Look',
           :conditions => ["object_type = 'User'"],
           :foreign_key => 'object_id',
           :dependent => :destroy)
  has_many :viewers, :through => :viewings, :source => :user

  # whuffie! See Cory Doctorow, "Down and Out in the Magic Kingdom"
  has_many :creds, :foreign_key => 'sink_id', :dependent => :destroy
  has_many :given_creds, :class_name => 'Cred', :foreign_key => 'source_id', :dependent => :destroy

  # invitations to groups
  has_many(:sent_invites,
           :class_name => 'Invitation',
           :foreign_key => 'sender_id',
           :dependent => :destroy)

  has_many(:invites,
           :class_name => 'Invitation',
           :foreign_key => 'recipient_id',
           :dependent => :destroy)
  
  has_many(:group_invites,
           :class_name => 'Invitation',
           :conditions => 'group_id IS NOT NULL',
           :foreign_key => 'recipient_id')
  
  has_many :old_usernames

  # interests take the form of tags
  acts_as_taggable
  acts_as_solr :fields => [:email, :description, :nickname]

  has_many :imagings, :as => :imagable, :dependent => :destroy
  has_many :images, :through => :imagings

  has_many :blockings, :class_name => 'UserBlocking', :foreign_key => 'user_id', :dependent => :destroy
  has_many :blocked_users, :through => :blockings
  has_many :blockings_as_blocked, :class_name => 'UserBlocking', :foreign_key => 'blocked_user_id', :dependent => :destroy
  has_many :blockers, :through => :blockings_as_blocked, :source => :user

  validates_uniqueness_of :nickname, :allow_nil => true
  validates_length_of :nickname, :within => 1..30, :too_short => 'Display is too short', :too_long => 'Display name is too long. ', :allow_nil => true
  validates_numericality_of :state

  def validate
    if self.nickname and self.nickname.match(/^\w{1}[\w \-!@=']*$/).nil?
      if self.nickname.index('.')
        errors.add(:nickname, 'Sorry, periods are not allowed in your display name. Leave field blank if you want to use your OpenID URL. ')
      else
        errors.add(:nickname, 'Contains invalid characters. ')
      end
    end
  end


  def User.find_by_openid(openid)
    return nil unless openid
    openid = Identifier.detect(openid)
    return nil unless openid
    i = Identifier.find_by_value(openid)
    return nil unless i
    return i.user
  end

  # XXX could be using a JOIN or a subquery.
  # find_all_lite: just return the id and nickname.   TODO: do this more!
  def User.find_all_lite_by_openid(openids)
    idents = Identifier.find_all_by_value(openids.map{|i|Identifier.detect(i)}.reject{|i|i.nil?})
    user_ids = idents.reject{|i| i.user_id.nil? }.map{|i|i.user_id}
    return [] if user_ids.empty?
    find_all_lite(user_ids)
  end

  def User.find_all_lite(user_ids)
    find_by_sql("SELECT id, nickname FROM users WHERE id IN (#{user_ids.join(',')})")
  end

  def User.find_by_openid_or_email(openid_or_email)
    return nil unless openid_or_email
    u = User.find_by_email(openid_or_email)
    unless u
      u = User.find_by_openid(openid_or_email)
    end
    return u
  end

  def User.find_nickname_like(q)
    like_pattern ='%'+q.gsub(' ','%')+'%'
    return User.find_by_sql(["SELECT * FROM users WHERE (nickname LIKE ?)", like_pattern])
  end

  def image
    images[0]
  end
  
  def image_sizes
    ['orig', 'big', 'thumb']
  end

  def blocked_user_ids
    User.connection.select_values("SELECT blocked_user_id FROM user_blockings WHERE user_id = #{self.id}").map{|i|i.to_i}
  end

  def cred_score(options = {})
    Cred.score(options.update(:user => self))
  end

  def cred_scores(options = {})
    Cred.scores(options.update(:user => self))
  end

  def cred_tags
    Tag.find_by_sql(["SELECT tags.* FROM tags JOIN taggings ON taggings.tag_id = tags.id JOIN creds ON taggings.taggable_type = 'Cred' AND taggings.taggable_id = creds.id AND creds.sink_id = ? GROUP BY tags.id", self.id])
  end

  def out_cred_tags
    Tag.find_by_sql(["SELECT tags.* FROM tags JOIN taggings ON taggings.tag_id = tags.id JOIN creds ON taggings.taggable_type = 'Cred' AND taggings.taggable_id = creds.id AND creds.source_id = ? GROUP BY tags.id", self.id])
  end

  def in_cred_with_extras
    sql = "SELECT creds.*, tags.id, tag_id, tags.name tag_name, users.nickname user_name 
             FROM creds JOIN taggings 
                         ON taggings.taggable_type = 'Cred' 
                          AND taggings.taggable_id = creds.id 
                          AND creds.sink_id = #{self.id} 
                        JOIN tags 
                         ON taggings.tag_id = tags.id 
                        JOIN users 
                         ON users.id = creds.source_id
                         AND users.state <> #{USER_STATES.index(:suspended)}"
   get_users_and_tags(sql, 'source_id')
  end

  def out_cred_with_extras
    sql = "SELECT creds.*, tags.id, tag_id, tags.name tag_name, users.nickname user_name 
             FROM creds JOIN taggings 
                         ON taggings.taggable_type = 'Cred' 
                          AND taggings.taggable_id = creds.id 
                          AND creds.source_id = #{self.id} 
                        JOIN tags 
                         ON taggings.tag_id = tags.id 
                        JOIN users 
                         ON users.id = creds.sink_id"
     get_users_and_tags(sql, 'sink_id')
   end

  # this is the "display" method.  It will show the nickname of the user
  # if set, or the shortened primary identifier.
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper
  def display_name
    return @nick_or_short if @nick_or_short
    if self.nickname
      return @nick_or_short = strip_tags(self.nickname)
    else
      return @nick_or_short = strip_tags(self.s)
    end
  end
  alias :dn :display_name
  

  # cache the primary identifier value
  def openid
    return @openid if @openid
    return @openid = identifier.value
  end
  
  def self.find_without_identifier
    find_by_sql("SELECT users.* FROM users LEFT JOIN identifiers ON identifiers.user_id = users.id WHERE identifiers.id IS NULL")
  end

  # shortcut for identifier.shorten
  def s
    return @short if @short
    # to let us do display of users eagerly loaded (in/out_cred_with_extras)
    ident = (identifier or Identifier.find_by_user_id(self.id, :conditions => 'identifiers.primary = true'))
    return @short = ident.shorten
  end

  # safe s
  def ss
    strip_tags(self.s)
  end

  # XXX fix the hack
  def vote_on(claim)
    if claim.class == Claim
      ClaimVote.find(:first, :conditions => ['user_id = ? AND claim_id = ?', self.id, claim.id])
    else
      ClaimVote.find(:first, :conditions => ['user_id = ? AND claim_id = ?', self.id, claim])
    end
  end
  alias voted? vote_on

  # XXX do a :claim/:claim_id lookup
  def votes_on(claim)
    ClaimVote.find_all_by_user_id_and_claim_id(self.id, claim.id,
                                               :order => 'created_at DESC')
  end

  def commented?(claim)
    Comment.find_by_claim_id_and_user_id(claim.id, self.id)
  end

  def votes_on_claims(claim_ids)
    ClaimVote.find_all_by_user_id_and_claim_ids(self.id, claim_ids)
  end

  def votes_on_my_claims(options = {})
    if options[:include_own]
      ClaimVote.find_by_sql(["SELECT claim_votes.* FROM claim_votes JOIN claims on claim_votes.claim_id = claims.id AND claims.user_id = ?", self.id])
    else
      ClaimVote.find_by_sql(["SELECT claim_votes.* FROM claim_votes JOIN claims on claim_votes.claim_id = claims.id AND claims.user_id = ? AND claim_votes.user_id != ?", self.id, self.id])
    end
  end

  def votes_on_others_claims(options = {})
    if limit = options[:limit]
      limit = 'LIMIT '+limit.to_s
    else
      limit = ''
    end
    
    ClaimVote.find_by_sql(["SELECT claim_votes.* FROM claim_votes JOIN claims on claim_votes.claim_id = claims.id AND claims.state = 1 AND claims.user_id != ? AND claim_votes.user_id = ? ORDER BY claim_votes.id DESC #{limit}", self.id, self.id])
  end

  def claims_voted(options = {})
    if limit = options[:limit]
      lim = options[:limit].to_i
      if options[:offset]
        off = options[:offset].to_i
        limit = "LIMIT #{off}, #{lim}"
      else
        limit = "LIMIT #{lim}"
      end
    else
      limit = ''
    end    
    if group_id = options[:group_id]
      group_frag = "claims.state = 4 AND group_id = #{group_id.to_i}"
    else
      group_frag = "claims.state = 1"
    end
    Claim.find_by_sql("SELECT claims.*, claim_votes.vote AS user_vote
                         FROM claims 
                         JOIN claim_votes ON claim_votes.claim_id = claims.id
                                   AND claim_votes.user_id = #{self.id}
                         WHERE claims.user_id != #{self.id}
                           AND #{group_frag}
                         ORDER BY claim_votes.id DESC
                         #{limit}")
  end

  def claims_about(options = {})
    ids = identifiers
    if options[:limit]
      if options[:offset]
        limit_fragment = "LIMIT #{options[:offset]}, #{options[:limit]}"
      else
        limit_fragment = "LIMIT #{options[:limit]}"
      end
    else
      limit_fragment = ""
    end

    order = options.fetch(:order, 'claims.created_at DESC')

    conditions = "identifier_id IN (#{ids.map{|i| i.id}.join(',')})"
    sql = "SELECT claims.* FROM claims
             JOIN mentioned_identifiers ON mentioned_identifiers.claim_id = claims.id
                  AND mentioned_identifiers.identifier_id IN (#{ids.map{|i| i.id}.join(',')})
                  AND claims.state = 1
              ORDER BY #{order} #{limit_fragment}"
    #sql = "SELECT * from claims WHERE state = 1 AND id IN (SELECT claim_id from mentioned_identifiers WHERE (#{conditions})) ORDER BY #{order} #{limit_fragment}"
    return Claim.find_by_sql(sql)
  end

  def claims_commented(options = {})
    if lim = options[:limit]
      lim_frag = "LIMIT #{lim}"
    else
      lim_frag = ""
    end
    Claim.find_by_sql(["SELECT DISTINCT claims.* FROM claims JOIN comments ON comments.user_id = ? AND comments.claim_id = claims.id AND claims.state = 1 ORDER BY claims.created_at DESC #{lim_frag}", self.id])
  end

  def recent_claims(options = {})
    if lim = options[:limit]
      lim_frag = "LIMIT #{lim}"
    else
      lim_frag = ""
    end    
    Claim.find_by_sql(["SELECT * FROM claims WHERE user_id = ? AND state = 1 ORDER BY created_at DESC #{lim_frag}",self.id])
  end

  def contact?(other)
    return false
    self.contacts.member?(other)
  end
  
  def contact?(other)
    Contact.find_by_user_id_and_contact_id(self.id, other.id) ? true : false
  end

  def contact_of?(other)
    Contact.find_by_user_id_and_contact_id(other.id, self.if) ? true : false
  end

  def dispatch(dispatchable, options = {})

    # don't dispatch if dispatchable is by an ignored user
    if [Claim, Comment].member?(dispatchable.class) 
      return if blocked_user_ids.member?(dispatchable.user_id)
    end

    unless Dispatch.find_by_dispatchable_type_and_dispatchable_id_and_user_id(dispatchable.class.to_s, dispatchable.id, self.id)
      dispatches.create :dispatchable => dispatchable, :reason => options[:reason], :sender => options[:from]
    end
  end

  # Remember to change the help text on claim/show if you alter this.
  def can_flag(claim)
    return true if get_state == :janrain or get_state == :jyte_team
    #return true if claim.is_about(self)
    return false
    #return (claim.is_about(self) or Cred.score_class.find_by_user_id(self.id))
  end

  # Come up with something for user to do next.
  # Dispatches first
  # Unseen claim
  # TODO: XXX
  # Commented-on claims with new comments
  # Voted-on claims with highly rated new comments
  # Claims by people in your groups
  # users with similar interests
  def next_dispatch
    if d = first_dispatch
      return d.dispatchable
    end
    unseen = Claim.find_by_sql(["SELECT claims.* FROM claims LEFT JOIN looks ON claims.state = 1 AND looks.object_type = 'Claim' AND looks.object_id = claims.id AND looks.user_id = ? WHERE looks.user_id IS NULL LIMIT 20", self.id])
    return unseen[rand(unseen.size)]
  end
  
  USER_STATES = [:jyte_team,:janrain,:early_adopter,:suspended,:deleted]
  BAD_USER_STATES = [:suspended]
  def set_state(s)
    raise ArgumentError, "unknown user state #{s}" unless USER_STATES.member?(s)
    self.state = USER_STATES.index(s)
  end

  def get_state
    return USER_STATES[self.state]
  end

  def deleted?
    self.get_state == :deleted
  end

  def suspended?
    self.get_state == :suspended
  end
  alias bad? suspended? # we may want to change this later

  def User.bad_states
    BAD_USER_STATES.collect {|s| USER_STATES.index(s)}
  end

  def User.exclude_sql
    "users.state NOT IN (#{User.bad_states.join(',')})"
  end

  def User.find_bad_ids
    connection.select_values("SELECT users.id FROM users WHERE users.state = #{USER_STATES.index(:suspended)}")
  end

  def pibbme?
    !! self.settings['pibbme']
  end

  def toggle_pibbme
    self.settings['pibbme'] = !self.settings['pibbme']
    save!
  end

  private

  # user_list, tag_list, tags_by_user_id, users_by_tag_id
  def get_users_and_tags(sql, user_id_column_name)
    records = User.connection.select_all(sql)
    tags_by_user_id = {}
    users_by_tag_id = {}
    users = {}
    tags = {}
    records.each{|r|
      user = users[r['source_id']]
      if user.nil?
        user = User.new(:nickname => r['user_name'])
        user.id = r[user_id_column_name]
        users[r[user_id_column_name]] = user
      end

      tag = tags[r['tag_id']]
      if tag.nil?
        tag = Tag.new(:name => r['tag_name'])
        tag.id = r['tag_id']
        tags[r['tag_id']] = tag
      end

      if tags_by_user_id[user.id].nil?
        tags_by_user_id[user.id] = []
      end
      tags_by_user_id[user.id] << tag

      if users_by_tag_id[tag.id].nil?
        users_by_tag_id[tag.id] = []
      end
      users_by_tag_id[tag.id] << user
    }
    return users.values, tags.values, tags_by_user_id, users_by_tag_id
  end


end
