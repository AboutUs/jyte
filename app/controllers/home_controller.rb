class HomeController < ApplicationController
  
  before_filter :auto_login
  before_filter :check_logged_in
  before_filter :home_new_counts

  secure_actions :only => [:clear,:clear_activity,:pibbme]


  def pibbme
    liu.toggle_pibbme
    flash[:notice] = 'Pibb settings saved.'
    redirect_to :action => 'settings'
  end
  
  def index
    @group_invites = Invitation.find(:all, :conditions => ['recipient_id = ? AND group_id IS NOT NULL', liuid])

    @user_events = Dispatch.find_by_sql(["SELECT * FROM dispatches WHERE user_id = ? AND dispatchable_type = 'User' ORDER BY created_at",liuid])

    @claim_invites = Dispatch.find_by_sql(["SELECT * FROM dispatches WHERE user_id = ? AND reason = 'invite' AND dispatchable_type = 'Claim'", liuid])

    
    num_recent = 10
    num_recent -= 2 unless @claim_invites.empty?
    num_recent -= 2 unless @user_events.empty?
    num_recent -= 2 unless @group_invites.empty?
    

    @your_recent_claims = Claim.find_by_sql(["SELECT * FROM claims WHERE user_id = ? AND state IN (1,4) ORDER BY created_at DESC LIMIT #{num_recent}",liuid])
    activity # get the values from the now-merged controller action
  end


  # remove dispatches from "Home" page for a logged in user
  def clear
    if params[:t] == 'all'
      
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.dispatchable_type = 'Claim')")

    elsif params[:t] == 'page'
      
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.dispatchable_type = 'Claim') ORDER BY dispatches.created_at LIMIT 15")
      
    elsif params[:t] == 'users'
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.dispatchable_type = 'User')")

    elsif (t = params[:t].to_i) != 0
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.id = #{t})")
    else
      flash[:notice] = 'Ouch.'
    end
    
    redirect_to :action => 'index'
  end

  def settings
    @section = 'settings'
  end

  def interests
    @section = 'interests'
    
    tag_ids = liu.tags.collect {|t| t.id.to_i}
    blocked_user_ids = liu.blocked_user_ids
    if blocked_user_ids.size > 0
      block_sql = " AND claims.user_id NOT IN (#{blocked_user_ids.join(',')})"
    else
      block_sql = ""
    end
    
      @claims = Claim.paginate_by_sql("SELECT DISTINCT claims.* FROM claims JOIN taggings ON claims.id = taggings.taggable_id AND taggings.taggable_type = 'Claim' AND taggings.tag_id IN (#{tag_ids.join(',')}) AND claims.state = 1 AND claims.user_id != #{liuid} AND claims.id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{liuid} AND trash = true) #{block_sql} ORDER BY claims.created_at DESC ", :page => params[:page], :per_page => 10)
      @claim_count = Claim.count_by_sql("SELECT DISTINCT COUNT(*) FROM claims JOIN taggings ON claims.id = taggings.taggable_id AND taggings.taggable_type = 'Claim' AND taggings.tag_id IN (#{tag_ids.join(',')}) AND claims.state = 1 AND claims.user_id != #{liuid} AND claims.id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{liuid} AND trash = true) #{block_sql}")

  end

  def group_claims
    @section = 'group_claims'
    limit = 10

    @groups = liu.groups
    @group_ids = @groups.collect {|g| g.id.to_i}

    if @groups.size > 0
      @claims = Claim.paginate_by_sql(["SELECT * FROM claims WHERE id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{liuid} AND trash = true) AND group_id IN (#{@group_ids.join(',')}) AND state = 4 ORDER BY created_at DESC"], :page => params[:page], :per_page => limit)
      @claim_count = Claim.count_by_sql(["SELECT COUNT(*) FROM claims WHERE id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{liuid} AND trash = true) AND group_id IN (#{@group_ids.join(',')}) AND state = 4"])
    else
      @claims = []
      @claim_count = 0
    end      

    claim_group_ids = @claims.collect {|c| c.group_id.to_i}.uniq
    @showing_groups = @groups.find_all {|g| claim_group_ids.member?(g.id)}

    # try and suggest some groups if they have none
    if @claims.size == 0
      @suggested_groups = []
      if liu.tags.size > 0
        # try and find some groups that match
        tag_ids = liu.tags.collect {|t|t.id}
        if tag_ids.size > 0
          @suggested_groups = Group.find_by_sql("SELECT DISTINCT groups.* FROM groups JOIN taggings ON taggings.taggable_id = groups.id AND taggings.tag_id IN (#{tag_ids.join(',')}) AND taggings.taggable_type = 'Group' AND groups.invite_only = false ORDER BY groups.created_at ASC LIMIT 15")
        end

      else
        # no interests, so let's suggest the most popular public groups
        @suggested_groups = Group.find_by_sql("SELECT DISTINCT groups.* FROM groups JOIN group_memberships ON groups.id = group_memberships.group_id AND groups.invite_only = false GROUP BY groups.id ORDER BY COUNT(group_memberships.group_id) DESC LIMIT 25")
      end

    end
  end

  def contact_claims
    @section = 'contact_claims'
    limit = 10

    @contacts = Contact.find(:all,
                             :conditions => ['user_id = ?', liuid],
                             :include => [:contact])

    @contact_ids = @contacts.collect {|c| c.contact_id.to_i}
    
    if @contact_ids.size > 0 # prevent SQL error
      @claims = Claim.paginate_by_sql("SELECT claims.* FROM claims WHERE claims.id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{liuid} AND trash = true) AND claims.user_id IN (#{@contact_ids.join(',')}) AND claims.state = 1 ORDER BY claims.created_at DESC", :page => params[:page], :per_page => limit)
    else
      @claims = []
    end

    claim_user_ids = @claims.collect {|c|c.user_id.to_i}.uniq
    @showing_contacts = @contacts.find_all {|c| claim_user_ids.member?(c.contact_id)}
  end

  # this action has changed to "activity"
  def comments
    redirect_to :action => 'activity'
  end

  def activity
    @section = 'activity'
    limit = 10

    @dispatches = Dispatch.paginate_by_sql("SELECT * FROM dispatches WHERE user_id = #{liuid} AND reason IN ('mentioned','inspired','inspired by watched','comment') ORDER BY created_at DESC", :page => params[:page], :per_page => limit)

    # Destroy dispatch if dispatchable is gone, or if related claim
    # has been red flagged
    @dispatches.reject! {|d|
      if !d
        @dispatch_count -= 1
        true

        # lazy cleanup for dispatches which cannot be viewed.  this is here
        # because some old dispatches exist that cause the activity tab to
        # break
      elsif d.dispatchable.nil? or (d.dispatchable.class == Claim and ![1,4].member?(d.dispatchable.state)) or (d.dispatchable.class == Comment and ![1,4].member?(d.dispatchable.claim.state))
        @dispatch_count -= 1
        d.destroy
        true

      else
        false
      end
    }
  end

  def clear_activity
    limit = 10
    page = params.fetch(:page, 1).to_i
    offset = (page * limit) - limit
    
    @dispatches = Dispatch.find_by_sql("SELECT * FROM dispatches WHERE user_id = #{liuid} AND reason IN ('mentioned','inspired','inspired by watched','comment') ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}").each {|d| d.destroy}
    redirect_to :action => 'index'
  end
  
  def drafts
    @section = 'drafts'
    @draft_claims = Claim.find_all_by_user_id_and_state(liuid, 0)
  end 

  def clear_drafts
    @draft_claims = Claim.find_all_by_user_id_and_state(liuid, 0)
    @draft_claims.each{|c|c.destroy}
    redirect_to :action => 'drafts'
  end

  private

  # this is a before filter on this controller for  
  def home_new_counts
    # check for new 
    if @action_name != 'activity'
      @activity_count = Dispatch.count_by_sql("SELECT COUNT(*) FROM dispatches WHERE user_id = #{liuid} AND reason IN ('mentioned','inspired','inspired by watched','comment')")
    else
      @activity_count = 0
    end
    true
  end

end
