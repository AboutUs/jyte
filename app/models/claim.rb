class Claim < ActiveRecord::Base
  belongs_to :user
  
  has_many :votes, :class_name => 'ClaimVote', :dependent => :destroy
  has_many :all_votes, :class_name => 'ClaimVoteHistory', :dependent => :destroy

  has_many :yea_votes, :class_name => 'ClaimVote', :conditions => 'vote = true'
  has_many :nay_votes, :class_name => 'ClaimVote', :conditions => 'vote = false'

  has_many :comments, :dependent => :destroy, :order => 'id'
  has_many :root_comments, :class_name => 'Comment', :conditions => 'parent_id IS NULL'

  belongs_to :group

  has_many :mentioned_identifiers, :dependent => :destroy, :order => 'mentioned_identifiers.order'
  has_many :identifiers, :through => :mentioned_identifiers

  # resources
  has_many :resourceables, :as => :resourceable, :dependent => :destroy
  has_many :resources, :through => :resourceables

  has_one :featured_claim, :dependent => :destroy

  has_many :imagings, :as => :imagable, :dependent => :destroy
  has_many :images, :through => :imagings
    
  has_many :claimings, :dependent => :destroy

  has_many :watchings, :class_name => 'Flagging', :conditions => 'watch = true'
  has_many :watchers, :through => :watchings, :source => :user

  has_many(:viewings,
           :class_name => 'Look',
           :conditions => ["object_type = 'User'"],
           :foreign_key => 'object_id',
           :dependent => :destroy)
  has_many :viewers, :through => :viewings, :source => :user

  validates_associated :user
  validates_presence_of :original
  validates_uniqueness_of :urlslug

  acts_as_taggable
  acts_as_solr :fields => [:original]

  attr_accessor :contact_msgs

  # claim.votes_by_group(5) or claim.votes_by_group :group => group
  def votes_by_group(options = {})
    group = Group.find_by_id(options[:group_id]) unless group = options[:group]
    # XXX trap nil group?
    user_conditions = "user_id IN (" << group.all_users.map {|u| "#{u.id}"}.join(",") << ")"
    conditions = "claim_id = #{self.id}"
    yes_count = ClaimVote.count(:conditions => "(#{user_conditions}) AND #{conditions} AND vote = true")
    no_count = ClaimVote.count(:conditions => "(#{user_conditions}) AND #{conditions} AND vote = false")
    return [yes_count, no_count]
  end

  def voter_groups
    # get a flat list of groups for each user
    gl = voters.inject([]) {|memo,u|memo + u.groups}
    gh = {}
    # count the appearances of each group into a hash
    gl.each{|g| gh[g.id] ? gh[g.id] += 1 : gh[g.id] = 1}
    # sort by number of appearances, collect the group ids, and return the groups
    gh.to_a.sort{|a,b| a[1] <=> b[1]}.collect {|a| a[0]}.collect{|gid|Group.find(gid)}
  end

  def voters_by_contacts_of_mentioned(options={})
    # find mentioned users
    unless mentioned_user_ids = options[:mentioned_user_ids]
      mentioned_user_ids = identifiers.select {|i| i.user_id}.map {|i| i.user_id}    
    end

    contact_voters = []
      
    if (ex_user_ids = options[:exclude_ids]) and ex_user_ids.size > 0
      exclude_frag = "AND claim_votes.user_id NOT IN (#{ex_user_ids.join(',')})"
    else
      exclude_frag = ''
    end
  
    if mentioned_user_ids.size > 0
      # if claim is about someone, first try to find votes by people
      # she has added as a contact
      contact_voters += User.find_by_sql([
          "SELECT users.id, users.nickname 
               FROM users
               JOIN contacts 
                          ON contacts.user_id IN (#{mentioned_user_ids.join(',')})
                          AND users.id = contacts.contact_id
               JOIN claim_votes
                          ON claim_votes.user_id = contacts.contact_id
                          AND claim_votes.user_id = users.id
                          AND claim_votes.claim_id = #{self.id}
                          AND claim_votes.vote = ?
                          #{exclude_frag}
              GROUP BY users.id LIMIT ?",
          options[:vote], options[:limit]])


      #contact_votes += ClaimVote.find_by_sql([
      #    "SELECT claim_votes.* FROM claim_votes, contacts 
      #     WHERE contacts.user_id IN (#{mentioned_user_ids.join(',')})
      #     AND claim_votes.user_id = contacts.contact_id 
      #     AND claim_votes.claim_id = #{self.id} 
      #     AND claim_votes.vote = ? 
      #     #{exclude_frag}
      #     LIMIT ?",
      #    options[:vote], options[:limit]])
    end
    
    return contact_voters
  end

  def root_inspiring_claim
    claim_ids = [self.id]
    claim = self
    
    # find root claim
    begin
      claimings = claim.claimings
      claim_ids += claimings.map{|c|
        cid = nil
        if c.claimable_type == 'Comment'
          cid = c.claimable.claim_id
        elsif c.claimable_type == 'Claim'
          cid = c.claimable_id
        end
        if claim_ids.member? cid
          return nil
        end
        cid
      }
      claim = Claim.find(claim_ids[-1])
    end while( claimings.size > 0 )
    return claim
  end

  def inspired_by(x)
    claimings.create :claimable => x
  end
  
  def inspired_by_comments
    x = []
    claimings.each {|l| x << l.claimable if l.claimable_type == 'Comment'}
    return x if x.length 
  end

  def inspired_by_claims
    x = []
    claimings.each {|l| x << l.claimable if l.claimable_type == 'Claim' and l.claimable and l.claimable.state = 1}
    return x
  end

  def inspired_claims
    Claim.find_by_sql(['SELECT claims.* FROM claims JOIN claimings ON claims.id = claimings.claim_id AND claimings.claimable_id = ? AND claimings.claimable_type = ? AND claims.state = 1',self.id, 'Claim'])
  end

  def inspired_claims_from_comments
    Claim.find_by_sql(['SELECT claims.* FROM claims JOIN comments ON comments.claim_id = ? JOIN claimings ON claims.id = claimings.claim_id AND claimings.claimable_id = comments.id AND claimings.claimable_type = "Comment" AND claims.state = 1 ',self.id])
  end

  def votes_with_users_and_scores(options = {})
    ActiveRecord::Base.transaction {
      st = Cred.score_table_name
      tag_ids_frag = '(' + tags.map{|t|t.id}.join(',') + ')'
      sql = "SELECT claim_votes.*, 
                    users.id user_id, users.nickname user_nickname, 
                    SUM(CASE scores.value IS NULL 0 ELSE scores.value) score
               FROM claim_votes
               JOIN users ON votes.user_id = users.id
                         AND votes.claim_id = #{self.id}
               LEFT JOIN #{st} scores ON scores.user_id = users.id
                                AND scores.tag_id IN #{tag_ids_frag}
               GROUP BY users.id
               ORDER BY score DESC, id"
      if options[:limit]
        lim = options[:limit].to_i
        if options[:offset]
          off = options[:offset].to_i
          sql << " LIMIT #{off}, #{lim}"
        else
          sql << " LIMIT #{lim}"
        end
      end
      votes = []
      users_by_id = {}
      user_ids = []
      Claim.connection.select_all(sql).each {|r|
        votes << ClaimVote.new(:vote => r['vote'], :user_id => r['user_id'], :claim_id => self.id)
        user_ids << r['user_id']
        user = User.new(:nickname => r['user_nickname'])
        user.id = r['user_id']
        users_by_id[r['user_id']] = user
        scores_by_user_id[r['user_id']] = r['score']
      }
    }
    return yea_voters, nay_voters, scores_by_user_id
  end

  def voters(options = {})
    if (lim = options[:limit].to_i) > 0
      limit_frag = "LIMIT #{lim}"
    else
      limit_frag = ""
    end
    unless options[:vote].nil?
      if options[:vote]
        vote_frag = "AND claim_votes.vote = true"
      else
        vote_frag = "AND claim_votes.vote = false"
      end
    end
    if exclude_user_id = options[:exclude]
      exclude_frag = "WHERE users.id <> #{exclude_user_id.to_i}"
    elsif (exclude_user_ids = options[:exclude_ids]) and exclude_user_ids.size > 0
      exclude_frag = "WHERE users.id NOT IN (#{exclude_user_ids.join(',')})"
    else
      exclude_frag = ""
    end
      
    # Active record can be a pain sometimes
    tag_ids = options[:tag_ids]
    if tag_ids.nil?  
      tag_ids = Claim.connection.select_values("SELECT tag_id FROM taggings WHERE taggable_type = 'Claim' AND taggable_id = #{self.id}")
    end
    
    if tag_ids.empty?
      sql = "SELECT users.id, users.nickname 
             FROM users
             JOIN claim_votes ON claim_votes.user_id = users.id
                             AND claim_votes.claim_id = #{self.id}
                             #{vote_frag}
             #{exclude_frag}
             GROUP BY users.id
             ORDER BY claim_votes.id DESC #{limit_frag}"
      voters = User.find_by_sql(sql)
    else
      tag_ids_frag = '(' + tag_ids.join(',') + ')'
      st = Cred.score_table_name
      sql = "SELECT users.id, users.nickname, 
                  SUM(scores.value) score
             FROM users
             JOIN claim_votes ON claim_votes.user_id = users.id
                             AND claim_votes.claim_id = #{self.id}
                             #{vote_frag}
             JOIN #{st} scores ON scores.user_id = users.id
                                   AND scores.tag_id IN #{tag_ids_frag}
             #{exclude_frag}
             GROUP BY users.id
             ORDER BY score DESC #{limit_frag}"
      voters = User.find_by_sql(sql)
      if lim > 0 and voters.size < lim
        lim -= voters.size
        limit_frag = "LIMIT #{lim}"
        if voters.size > 0
          voters_frag = "AND users.id NOT IN (#{voters.map{|u|u.id}.join(',')})"
        else
          voters_frag = ""
        end

        sql = "SELECT users.id, users.nickname 
             FROM users
             JOIN claim_votes ON claim_votes.user_id = users.id
                             AND claim_votes.claim_id = #{self.id}
                             #{voters_frag}
                             #{vote_frag}
             #{exclude_frag}
             GROUP BY users.id
             ORDER BY claim_votes.id DESC #{limit_frag}"
        voters += User.find_by_sql(sql)
      end
    end
    return voters
  end

  def yea_voters(options = {})
    voters(options.update({:vote => true}))
  end

  def nay_voters(options = {})
    voters(options.update({:vote => false}))
  end

  def validate_on_create
    parse
  end

  def validate_on_update
    old = Claim.find(self.id)
    unless original == old.original
      if state > 0
        errors.add(:text, "You may not change the text after publishing a claim.")
      else
        parse
      end
    end
  end

  def after_save
    if @idents
      MentionedIdentifier.find(:all, :conditions => ['claim_id = ?',self.id]).each {|mi| mi.destroy}
      @idents.each_with_index { |identifier,index| 
        # add mention of this identifier for this claim
        MentionedIdentifier.create(:claim_id => self.id,
                                   :identifier_id => identifier.id,
                                   :order => index)
      }
    end
    FeaturedClaim.check_claim_hook(self)
  end

  def parse
    idents = []
    parsed = ''
    slug = ''
    self.original = self.original.sub(/^ +/,"").sub(/ +$/,"")
    tokens = self.original.split(/[ ]+/)
    tokens.each {|t|
      t = t.sub(/^(['"])/, '')
      prepunc = $~[1] if $~
      t = t.sub(/([,;])$/, '')
      postpunc = $~[1] if $~
      t = t.gsub('%','&#37;').gsub('<','&lt;')
      if id_s = Identifier.detect(t) # is t an identifier string?
        idents << id_s
        parsed << "#{prepunc}%s#{postpunc} "
        slug << Identifier.shorten(id_s) << "-"
      else
        if t.size > 40
          errors.add(:text, "No word in a claim may be longer than 40 characters - it screws up the formatting.")
        end
        parsed << "#{prepunc}#{t}#{postpunc} "
        slug << t << "-"
      end
    }
    self.parsed = parsed.strip

    STOP_WORDS.each {|sw|
      if parsed.downcase.index(sw)
        errors.add(:text, "Please rephrase without the strong language.")
      end
    }

    oslug = slug = slug.downcase.gsub(/[^-.\w]/,'').chomp("-").chomp(".")
    i = 2;
    while Claim.find_by_urlslug(slug)
      slug = "#{oslug}-#{i}"
      i += 1
    end
    self.urlslug = slug
    self.digest = self.calculate_digest
    
    if idents.size > 5
      # XXX allow making claims about groups
      errors.add(:text, "Please limit yourself to 5 OpenIDs per claim.")
    end

    @idents = idents.collect {|i|
      identifier = Identifier.find_by_value(i)
      unless identifier
        # create identifiers that don't yet exist
        identifier = Identifier.create(:value => i)
      end
      identifier
    }
    # the same code from normalized_identifiers
    # but we can't use it because this claim hasn't got an id yet
    # and the mentioned_identifers entries haven't yet been created
    norm_idents = @idents.collect {|i|
      if i.user
        i.user.identifier
      else
        i
      end
    }

    Claim.find_all_by_digest(self.digest, :conditions => 'state > 0').each {|c|
      if c.normalized_identifiers == norm_idents
        errors.add(:same, "#{c.urlslug}")
      end
    }

  end

  def publish
    if self.group_id
      self.state = 4 # group published
    else
      self.state = 1 # public published
    end
    self.created_at = DateTime.now

    # Make sure there aren't any rogue votes due to retraction
    ClaimVote.connection.execute("DELETE FROM claim_votes WHERE claim_votes.claim_id = #{self.id}")

    # hacking around race condition: claim shown before vote created.
    self.yeas = 1 
    self.nays = 0 
    self.save!

    ClaimVote.create(:claim_id => self.id, :user_id => self.user_id, :vote => true)
    
    # notify mentioned users
    mentioned_users.each {|u|
      u.dispatch(self, :reason => 'mentioned') unless u == self.user
    }
    # user who made the comment that inspired this claim gets notified,
    # and watchers of that claim
    inspired_by_comments.each {|c| u = c.user
      u.dispatch(self, :reason => 'inspired') unless u == self.user
      c.claim.watchers.each {|u| 
        u.dispatch(self, :reason => 'inspired by watched') unless u == self.user 
      }
      c.user.dispatch(self, :reason => 'inspired') unless c.user_id == self.user_id
    }
    # user who made the claim that inspired this claim gets notified,
    # and watchers of that claim as well
    inspired_by_claims.each {|c| u = c.user
      u.dispatch(self, :reason => 'inspired') unless u == self.user
      c.watchers.each {|u| 
        u.dispatch(self, :reason => 'inspired by watched') unless u == self.user 
      }
    }

    # This is one happening claim.
    unless self.group_id
      Happening.create(:happenable => self)
      self.solr_save
    end

  end

  def flag(color)
    if color == :green
      self.state = 1
    elsif color == :yellow
      self.state = 2
    elsif color == :red
      self.state = 3
    else
      raise "unknown flag type"
    end
    save!
  end

  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper
  def title
    # XXX at most 6 queries.  Ideally we'd get this to 2 or 1
    parsed % identifiers.map{|i| u = i.user if i.user_id
      if u
        u.dn
      else
        strip_tags(i.shorten)
      end
    }
  end

  def text
    parsed % (identifiers.map{|i| strip_tags(i.shorten)})
  end

  def normalized_identifiers
    self.identifiers.collect {|i|
      if i.user
        i.user.identifier
      else
        i
      end
    }
  end

  def mentioned_peoples_identifiers
    self.identifiers.inject([]) {|ids,i|
      if i.user
        ids += i.user.identifiers
      else
        ids += [i]
      end
    }
  end

  def mentioned_users
    User.find_by_sql("SELECT users.* FROM users JOIN identifiers ON user_id = users.id JOIN mentioned_identifiers ON identifier_id = identifiers.id AND claim_id = #{self.id}")
  end

  def mentions?(openid)
    self.mentioned_peoples_identifiers.collect {|i| i.value}.member?(openid)
  end

  def mentions_user?(user)
    self.mentioned_users.member?(user)
  end
  alias is_about mentions_user?

  def calculate_digest
    require 'digest/sha1'
    text = self.parsed.downcase.gsub('  +',' ').gsub(/[^\w\n]/,' ').strip
    return Digest::SHA1.hexdigest(text)
  end

  def location_resources
    resources.inject([]) {|p,r| r.class == LocationResource ? p << r : p}
  end

  def url_resources
    resources.inject([]) {|p,r| r.class == UrlResource ? p << r : p}
  end

  def image_resources
    resources.inject([]) {|p,r| r.class == ImageResource ? p << r : p}
  end
  def widget_resources
    resources.inject([]) {|p,r| r.class == WidgetResource ? p << r : p}
  end
  def time_resources
    resources.inject([]) {|p,r| r.class == TimeResource ? p << r : p}
  end

  def prepare_comments
    comment_hash = {}
    root_comment_ids = []
    comment_children = {}
    self.comments.each {|c|
      comment_hash[c.id] = c
      if c.parent_id
        if comment_children[c.parent_id]
          comment_children[c.parent_id] << c.id
        else
          comment_children[c.parent_id] = [c.id]
        end
      else
        root_comment_ids << c.id
      end
      c.child_ids = []
    }
    comment_children.each {|i,l|
      comment_hash[i].child_ids = l
    }
    return comment_hash, root_comment_ids
  end

  def flag_by(user)
    if user.class == User
      user_id = user.id
    else
      user_id = user
    end
    Flagging.find_by_user_id_and_claim_id(user_id, self.id)
  end

  def watched_by(user)
    if user.class == User
      user_id = user.id
    else
      user_id = user
    end
    f = Flagging.find_by_user_id_and_claim_id(user_id, self.id)
    return false unless f
    return f.watch
  end

  def trashed_by(user)
    if user.class == User
      user_id = user.id
    else
      user_id = user
    end
    f = Flagging.find_by_user_id_and_claim_id(user_id, self.id)
    return false unless f
    return f.trash
  end

  # use :since => DateTime
  # or :comment_conditions => where_fragment_string
  # to restrict comments considered
  # use :conditions or :claim_conditions with a where fragment to restrict
  # claims returned
  def self.find_discussed(options = {})

    if options[:limit]
      limit_frag = "LIMIT #{options[:limit]}"
    else
      limit_frag = ""
    end

    since = options[:since] 
    if since
      qds = ActiveRecord::Base.connection.quoted_date(since)
      comment_conditions = "created_at > '#{qds}'"
    else
      comment_conditions = options[:comment_conditions]
    end

    if comment_conditions and not comment_conditions.empty?
      comment_conditions_frag = "WHERE #{comment_conditions}"
    else
      comment_conditions_frag = ""
    end

    claim_conditions = options[:conditions] or options[:claim_conditions]
    if claim_conditions.nil? or claim_conditions.empty?
      claim_conditions_frag = ""
    else
      claim_conditions_frag = "AND #{claim_conditions}"
    end

    # XXX: Post-postgres migration, limit should go inside subquery
    Claim.find_by_sql("SELECT claims.*, counts.comment_count FROM claims JOIN (SELECT claim_id, COUNT(*) as comment_count FROM comments #{comment_conditions_frag} GROUP BY claim_id) counts ON claims.id = counts.claim_id WHERE claims.state = 1 #{claim_conditions_frag} #{limit_frag}")
  end

  def self.find_contested(options = {})
    if options[:limit]
      limit_frag = "LIMIT #{options[:limit]}"
    else
      limit_frag = ""
    end

    # XXX: Post-postgres migration, limit should go inside subquery
    Claim.find_by_sql("SELECT *, CASE WHEN yeas > nays THEN nays ELSE yeas END AS contests FROM claims WHERE yeas > 0 AND nays > 0 AND state = 1 ORDER BY contests DESC #{limit_frag}")
  end

  def self.find_solid(options = {})
    if options[:limit]
      limit_frag = "LIMIT #{options[:limit]}"
    else
      limit_frag = ""
    end

    Claim.find_by_sql("SELECT claims.*, CASE WHEN claims.yeas > claims.nays THEN claims.yeas - 4 * claims.nays ELSE claims.nays - 4 * claims.yeas END AS solidity FROM claims WHERE claims.state = 1 ORDER BY solidity DESC #{limit_frag}")
  end

  def image
    images[0]
  end

  def image_sizes
    ['claim']
  end

  def has_supporting_material?
    (self.body and self.body.length > 0) or self.tags.length > 0 or image
  end

 

end

