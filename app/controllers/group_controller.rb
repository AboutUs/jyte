class GroupController < ApplicationController

  before_filter :auto_login
  before_filter :check_logged_in, :except => [:index,:show,:api_roster,:api_is_member,:claims,:find]
  secure_actions :only => [:new_submit,:edit_submit,:delete_icon,:add_yourself,
                           :remove_yourself,:del_member,:del_group,
                           :invite_decision]
  
  def index
    conds = nil
    group_frag = ''
    @hot_groups = []
    @contacts_groups = []
    @interests_groups = []
    @your_groups = []

    if liu
      @your_groups = liu.groups
      unless @your_groups.empty?
        group_ids = @your_groups.collect {|g|g.id.to_i}
        group_frag = " AND groups.id not IN (#{group_ids.join(',')})"
      end

      if liu.tags.size > 0
        # try and find some groups that match
        tag_ids = liu.tags.collect {|t|t.id}
        if tag_ids.size > 0
          @interests_groups,
          @interests_count = groups_by_interest(:limit => 6,
                                                    :invite_only=>false)

        end
      end

      if liu.contacts.size > 0
        # get groups ordered by the number of you contacts in the group
        @contacts_groups,
        @contacts_count = groups_by_contacts(:limit => 6,
                                             :invite_only => false)
      end
      

    end
    
    if @interests_groups.empty? or @contacts_groups.empty?
      
      limit = logged_in? ? 12 : 18
      @hot_groups,_c = groups_by_popularity(:limit => limit)
      
    end

    @latest_groups,
    @latest_count = groups_by_recency(:limit => 6)

  end

  def find
    by = params[:by]
    
    page = params.fetch(:page,1).to_i
    limit = 24
    offset = (page * limit) - limit
    
    case by
    when 'contacts'
      if logged_in?
        @groups, @g_count = groups_by_contacts(:limit => limit,
                                               :offset => offset)
        @g_title = 'Your contacts groups'
        @g_subtitle = "Groups that you aren't a member of, ordered by how many of your contacts are members."
      else
        redirect_to :controller => 'group'
        return
      end
        
    when 'interests'
      if logged_in?
        @groups, @g_count = groups_by_interest(:limit => limit,
                                               :offset => offset)

        @g_title = 'Groups that match your interests'
        @g_subtitle = "Groups that you aren't a member of, ordered by the number of shared interests."
      else
        redirect_to :controller => 'group'
        return
      end

    when 'hot'
      @groups, @g_count = groups_by_popularity(:limit => limit,
                                               :offset => offset)
      @g_title = 'Popular groups'
      @g_subtitle = 'All groups ordered by number of members'

    when 'latest'

      @groups, @g_count = groups_by_recency(:limit => limit,
                                            :offset => offset)
      @g_title = 'All groups'
      @g_subtitle = 'All groups with the latest ones first.'

    when 'search'
      q = params[:q]

      begin
        @groups = Group.find_by_solr(q, :rows => limit, :start => offset)
        @g_count = Group.count_by_solr(q)
      rescue
        @groups = []
        @g_count = 0
      end
      @g_title = "Search results"
    else
      redirect_to :controller => 'group'
      return
    end

    @group_pages = WillPaginate::Collection.create(page, limit) do |pager|
      pager.replace(@groups)
    end
  end
  
  def new
  end
  
  def name_status
    @g = Group.find_by_name(params[:name])
    unless @g
      @valid = Group.new(:name => params[:name],
                         :user_id => liuid).valid?
    else
      @valid = true
    end
    render :partial => 'name_status'
  end
  
  def new_submit
    g = Group.new(:user_id => liuid)
    g.update_attributes(params[:group])
    
    if g.errors[:name]
      flash[:notice] = 'Your group must have a unique name'
      redirect_to :action => 'new'
      return
    else
      if params[:group_interests]
        g.tag_with(params[:group_interests])
      end
    end
    
    g.save
    GroupMembership.create(:user_id => liuid,
                           :group_id => g.id,
                           :moderator => true)

    redirect_to :action => 'edit', :id => g.id, :new => 1
  end

  def edit
    @group = Group.find(params[:id])
    unless @group.can_edit?(liu)
      flash[:notice] = 'You cannot edit that group.'
      redirect_to gurl(show)
      return
    end
  end

  def edit_submit
    @group = Group.find(params[:id])

    unless @group.can_edit?(liu)
      redirect_to gurl(@group)
      return
    end

    @group.update_attributes(params[:group])
    @group.tag_with(params[:tags])
    @group.save

    # process image
    image_blob = read_blob(params[:image])
    
    if image_blob
      # destroy old image is necessary
      if old_image = @group.image
        @group.imagings.destroy_all
        old_image.destroy_image(@group)
      end

      begin
        im = Image.from_blob(image_blob, @group)
        im.on(@group)
      rescue
        flash[:notice] = "Sorry, we couldn't read that image.  Try another."
        redirect_to :action => 'edit', :id => @group.id
        return
      end
    end

    flash[:notice] = 'Group updated'
    redirect_to gurl(@group)
  end
  
  def delete_icon
    @group = Group.find(params[:id])
    
    unless @group.can_edit?(liu)
      flash[:notice] = 'nope'
      redirect_to gurl(@group)
      return
    end

    i = @group.image
    if i
      @group.imagings.destroy_all
      i.destroy_image(@group)
    end

    redirect_to :action => 'edit', :id => @group.id
  end

  def claims
    @group = Group.find_by_id(params[:id])
    unless @group
      flash[:notice] = 'Unknown group'
      redirect_to :controller => ''
      return
    end

    uids = @group.user_ids

    @claims = Claim.paginate_by_user_id(uids, :conditions => 'state = 1', :order => 'created_at DESC', :limit => 10, :page => params[:page])
  end

  def show
    if params[:urlslug]
      @group = Group.find_by_urlslug(params[:urlslug])
    else
      @group = Group.find_by_id(params[:id])
    end
    
    unless @group
      flash[:notice] = 'Unknown group'
      redirect_to :controller => ''
      return
    end
    
    if liu
      @invite = Invitation.find_by_group_id_and_recipient_id(@group.id, liuid)
    else
      @invite = nil
    end

    if logged_in?
      # Clear user's dispatches to this group
      Dispatch.find_all_by_dispatchable_type_and_dispatchable_id_and_user_id('Group', params[:id], logged_in_user_id).each {|d| d.destroy }
    end
    
    if @group.member?(liu)
      @claims = Claim.find(:all, :conditions => ["state = 4 AND group_id = ?", @group.id], :limit => 10, :order => 'created_at DESC')
      @group_claim_count = Claim.count(:conditions => ['state = 4 AND group_id = ?', @group.id])
    else
      @claims = []
    end
      
    claim_ids = @claims.collect {|c| c.id}
    batch_load_claim_data(claim_ids) #faster! ;)
    @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
  end

  def invite
    u = liu
    @group = Group.find_by_id(params[:group_id])
    mod = params[:mod]
    if !@group or !@group.can_invite?(u) or (mod and !@group.can_invite_as_moderator?(u))
      @invite_msg = 'You cannot do that'
      render :partial => 'invite_form'
      return
    end

    openid_or_email = params[:openid_or_email]

    if openid_or_email.nil? or openid_or_email.empty?
      @invite_msg = 'Please enter an OpenID or Email'
    else
      inv = Invitation.create(:sender_id => u.id,
                              :group_id => @group.id,
                              :group_moderator => mod)

      user = User.find_by_openid_or_email(openid_or_email)
      if user
        if @group.member?(user)
          inv.destroy
          @invite_msg = ERB::Util.h(openid_or_email)  + ' is already a member'
        else
          inv.recipient = user
          inv.save
          @invite_msg = 'Invite sent to ' + ERB::Util.h(openid_or_email)
        end
      else
        invite_sent, @invite_msg = send_invite(inv, openid_or_email) 
      end      
    end

    render :partial => 'invite_form'
  end

  def invite_decision
    inv = Invitation.find_by_id(params[:invite_id])
    group = Group.find_by_id(inv.group_id)
    if inv.nil? or group.nil? or inv.recipient_id != logged_in_user_id
      flash[:notice] = 'You cannot join that group.'
      redirect_to :controller => 'home'
      return
    end

    if params[:decision] == 'accept'
      GroupMembership.create(:group_id => group.id,
                             :user_id => liuid,
                             :moderator => inv.group_moderator)
      inv.destroy
      flash[:notice] = 'Invitation accepted'
      
    elsif params[:decision] == 'decline'
      inv.destroy
      flash[:notice] = 'Invitation declined'

    else
      raise ArgumentError, "'#{params[:decision]}' is not a valid decision"
    end

    redirect_to gurl(group)
  end

  def add_yourself
    g = Group.find(params[:group_id])
    if g.user_id == liuid or !g.invite_only?
      Group.transaction {
        GroupMembership.create(:group_id => g.id, :user_id => liuid)
        Invitation.delete_all(['group_id = ? AND recipient_id = ?', g.id, liuid])
      }
    end
    redirect_to gurl(g)
  end

  def remove_yourself
    g = Group.find(params[:group_id])
    GroupMembership.find_by_group_id_and_user_id(g.id, liuid).destroy
    if Group.find_by_id(params[:group_id])
      redirect_to gurl(g)
    else
      flash[:notice] = "Group deleted due to lack of membership."
      redirect_to :action => 'index'
    end
  end

  def del_member
    group = Group.find(params[:group_id])
    user = User.find_by_openid(params[:openid])

    if user and (group.can_edit?(liu) or user == liu)
      if gm = GroupMembership.find_by_group_id_and_user_id(group.id, user.id)
        gm.destroy
        flash[:notice] = 'User removed.'
      else
        flash[:notice] = 'That user is not a member of this group.'
      end
    else
      flash[:notice] = 'You may not remove that member from this group.'
    end
    
    redirect_to :action => 'edit', :id => group.id
  end

  def del_group
    g = Group.find_by_id(params[:group_id])

    # only owner may delete
    if g and g.user == liu

      # XXX: should probably dispatch members letting alerting them
      # that the group has been deleted.
      g.destroy
      flash[:notice] = 'Group deleted'
    else
      flash[:notice] = 'You cannot do that'
    end

    redirect_to :controller => 'home'
  end

  def roster
    render_text Group.find(params[:id]).all_identifiers.collect {|i| i.value}.join("\n")
  end
  
  # maybe use 200, 400 responses here?
  def api_is_member
    group = Group.find_by_urlslug(params[:slug])
    user = User.find_by_openid(params[:openid])
    
    if group
      if group.member?(user)
        render :text => 'true', :status => 200
      else
        render :text => 'false', :status => 400
      end
    else
      render :text => 'error: unknown group', :status => 400
    end
  end

  def api_roster
    group = Group.find_by_urlslug(params[:slug])
    if group
      ids = []
      group.users.each {|u|
        u.identifiers.each {|i|
          ids << i.value 
        }
      }
      render :text => ids.join("\n"), :status => 200
    else
      render :text => 'error: unknown group', :status => 400
    end
  end

  private


  def group_frag
    return '' unless logged_in?
    return @group_frag if @group_frag
    group_ids = liu.groups.collect {|g|g.id.to_i}
    if group_ids.size == 0
      @group_frag = ''
    else
      @group_frag = " AND groups.id not IN (#{group_ids.join(',')})"
    end
    return @group_frag
  end

  def groups_by_popularity(ops={})
    limit = ops.fetch(:limit,6)
    offset = ops.fetch(:offset,0)
    invite_only = ops.fetch(:invite_only, false) ? 'true' : 'false'

    the_groups = Group.find_by_sql("SELECT groups.* FROM groups JOIN group_memberships ON groups.id = group_memberships.group_id AND groups.invite_only = #{invite_only} #{group_frag} GROUP BY groups.id ORDER BY COUNT(group_memberships.group_id) DESC LIMIT #{limit} OFFSET #{offset}")
    the_count = Group.count_by_sql("SELECT COUNT(DISTINCT groups.id) FROM groups JOIN group_memberships ON groups.id = group_memberships.group_id AND groups.invite_only = #{invite_only} #{group_frag}")

    return the_groups, the_count
  end
  
  def groups_by_contacts(ops={})
    limit = ops.fetch(:limit,6)
    offset = ops.fetch(:offset,0)
    invite_only = ops.fetch(:invite_only, false) ? 'true' : 'false'

    contact_ids = liu.contacts.collect {|c|c.id}
    if contact_ids.size > 0

      the_groups = Group.find_by_sql("SELECT groups.*, COUNT(group_memberships.user_id) AS contacts_count FROM groups JOIN group_memberships ON groups.id = group_memberships.group_id AND group_memberships.user_id IN (#{contact_ids.join(',')}) AND groups.invite_only = #{invite_only} #{group_frag} GROUP BY group_memberships.group_id ORDER BY COUNT(group_memberships.user_id) DESC LIMIT #{limit} OFFSET #{offset}")

      the_count = Group.count_by_sql("SELECT COUNT(DISTINCT groups.id) FROM groups JOIN group_memberships ON groups.id = group_memberships.group_id AND groups.invite_only = #{invite_only} AND group_memberships.user_id IN (#{contact_ids.join(',')}) #{group_frag}")
      
      return [the_groups, the_count]
      
    else

      return [[], 0]
    end


  end

  def groups_by_interest(ops={})
    limit = ops.fetch(:limit,6)
    offset = ops.fetch(:offset,0)
    invite_only = ops.fetch(:invite_only, false) ? 'true' : 'false'

    tag_ids = liu.tags.collect {|t|t.id}
    if tag_ids.size > 0

      the_groups = Group.find_by_sql("SELECT groups.*, COUNT(taggings.taggable_id) AS interests_count FROM groups JOIN taggings ON taggings.taggable_id = groups.id AND taggings.tag_id IN (#{tag_ids.join(',')}) AND taggings.taggable_type = 'Group' AND groups.invite_only = #{invite_only} #{group_frag} GROUP BY groups.id ORDER BY COUNT(taggings.taggable_id) DESC LIMIT #{limit} OFFSET #{offset}")
      
      the_count = Group.count_by_sql("SELECT COUNT(DISTINCT groups.id) FROM groups JOIN taggings ON taggings.taggable_id = groups.id AND taggings.tag_id IN (#{tag_ids.join(',')}) AND taggings.taggable_type = 'Group' AND groups.invite_only = #{invite_only} #{group_frag}")

      return [the_groups, the_count]
      
    else
      

      return [[], 0]
    end

  end

  def groups_by_recency(ops={})
    limit = ops.fetch(:limit,6)
    offset = ops.fetch(:offset,0)
    invite_only = ops.fetch(:invite_only, false) ? 'true' : 'false'
    
    the_groups = Group.find_by_sql("SELECT * FROM groups WHERE groups.invite_only = #{invite_only} #{group_frag} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")

    the_count = Group.count_by_sql("SELECT COUNT(*) FROM groups WHERE groups.invite_only = #{invite_only} #{group_frag}")

    return [the_groups, the_count]
  end

end
