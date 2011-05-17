class Votable < ActiveRecord::Base
  belongs_to :votable, :polymorphic => true
  has_many :votes, :conditions => 'current = true'
  has_many :up_votes, :class_name => 'Vote', :conditions => 'current = true AND vote = true'
  has_many :down_votes, :class_name => 'Vote', :conditions => 'current = true AND vote = false'
  has_many :voters, :through => :votes, :source => :user
  has_many :up_voters, :through => :up_votes, :source => :user
  has_many :down_voters, :through => :down_votes, :source => :user
  has_many :all_votes, :class_name => 'Vote'

  # snippet to fix missing votables
  # Claim.find_all.find_all{|c|c.votable.nil?}.each{|c|c.votable = Votable.create(:votable => c)}

#  validates_associated :votable
#  validates_presence_of :votable
  def validate
    # XXX hack: the counts get screwy sometimes
    recalculate if up_count.nil? or down_count.nil?
    if up_count + down_count != votes.length
      recalculate false
      p "Vote counts for votable #{id} required recalculation. (FIXME!)"
    end
  end

  def votes_by_group(options = {})
    group = Community.find_by_id(options[:group_id]) unless group = options[:group]
    user_conditions = group.all_users.collect {|u| "user_id = #{u.id}"}.join " OR "
    conditions = "votable_id = #{self.id} AND current = true"
    yes_count = Vote.count(:conditions => "(#{user_conditions}) AND #{conditions} AND vote = true")
    no_count = Vote.count(:conditions => "(#{user_conditions}) AND #{conditions} AND vote = false")
    return [yes_count, no_count]
  end

  def recalculate(saveme = true)
    self.up_count = Vote.count(:conditions => ['votable_id = ? AND vote = true AND current = true', self.id])
    self.down_count = Vote.count(:conditions => ['votable_id = ? AND vote = false AND current = true', self.id])
    self.save if saveme
  end

  # this will likely be pretty expensive
  # it's probably possible to do this inside postgres much faster
  # XXX bring this up with Jonathan
  # change the sorting so that the groups that appear are those where the 
  #  opinions are most different from the average (and limit the number)
  def voter_groups
    # get a flat list of groups for each user
    gl = voters.inject([]) {|memo,u|memo + u.groups}
    gh = {}
    # count the appearances of each group into a hash
    gl.each{|g| gh[g.id] ? gh[g.id] += 1 : gh[g.id] = 1}
    # sort by number of appearances, collect the group ids, and return the groups
    gh.to_a.sort{|a,b| a[1] <=> b[1]}.collect {|a| a[0]}.collect{|gid|Group.find(gid)}
  end

  def up_voters
    votes.reject {|v| not v.vote}.collect{|v|v.user}
  end

  def down_voters
    votes.reject {|v| v.vote}.collect{|v|v.user}
  end
end
