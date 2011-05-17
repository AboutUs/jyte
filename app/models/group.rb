class Group < ActiveRecord::Base
  belongs_to :user

  has_many :group_memberships, :dependent => :destroy
  has_many :users, :through => :group_memberships
  alias :members :users

  has_many :invitations, :dependent => :destroy

  # moderators
  has_many :group_membership_moderators, :class_name => 'GroupMembership', :conditions => 'moderator = TRUE', :foreign_key => 'group_id'
  has_many :moderators, :through => :group_membership_moderators, :source => :user 

  # image
  has_many :imagings, :as => :imagable, :dependent => :destroy
  has_many :images, :through => :imagings
  
  acts_as_taggable
  acts_as_solr :fields => [:name, :description]
  
  validates_presence_of :user_id
  validates_associated :user
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^[\w]{1}[\w \-]*$/
  validates_length_of :name, :within => 1..50, :too_short => "Name must be at least %d character.", :too_long => "Name cannot be longer than %d characters."

  validates_uniqueness_of :urlslug

  def Group.urlslug(name)
    name.downcase.gsub(/[^-\w]/, '_')
  end

  def Group.most_members(options={})
    limit = options.fetch(:limit, 10)
  end

  def before_create
    self.name = self.name.strip
    self.urlslug = Group.urlslug(self.name)
  end

  def invite_only?
    self.invite_only
  end

  def public?
    !invite_only?
  end

  def can_invite?(u)
    return true if can_edit?(u)
    if !invite_only?
      return true if self.member?(u)
    end
    return false
  end

  def can_invite_as_moderator?(u)
    can_invite?(u) and can_edit?(u)
  end

  def can_edit?(u)
    if u.class == User
      return true if u == user # creator
      return moderators.member?(u) # moderator
    end
    
    raise ArgumentError, 'can_edit? needs a User'
  end
  
  def moderator?(u)
    return can_edit?(u)
  end

  def member?(u)
    return users.member?(u)
  end

  def image
    images[0]
  end
  
  def image_sizes
    ['big', 'thumb']
  end

  def user_ids
    Group.connection.select_values("SELECT user_id FROM group_memberships WHERE group_id = #{self.id}").map{|uid|uid.to_i}
  end

  def after_save
    self.solr_save
  end

end
