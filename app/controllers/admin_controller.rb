class AdminController < ApplicationController
  
  before_filter :check_admin_status
  secure_actions :except => [:index]
  
  def index
    @unique_users = User.count
    @verified_identifers = Identifier.count(:conditions => ['user_id IS NOT NULL'])
    @todays_users = User.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 0 DAY) <= created_at'])
    @yesterdays_users = User.count(:conditions  => ['created_at >= CURRENT_DATE() - INTERVAL 1 DAY AND created_at <= CURRENT_DATE()'])
    @seven_day_users = User.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 7 DAY) <= created_at'])
    @thirty_day_users = User.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 29 DAY) <= created_at'])
    @total_groups = Group.count
    
    @num_users_ingroups = GroupMembership.count_by_sql(["select count(distinct user_id) from group_memberships"])
    @num_groups_joined = GroupMembership.count_by_sql(["select count(gm.id) from groups g, group_memberships gm where g.user_id = gm.user_id"])
        
    @total_claims = Claim.count
    @total_group_claims = Claim.count :conditions => ['state = 4']
    @total_votes = ClaimVote.count
    @total_comments = Comment.count
    @todays_claims = Claim.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 0 DAY) <= created_at'])
    @todays_votes = ClaimVote.count(:conditions => ['DATE_SUB(CURRENT_DATE(),INTERVAL 0 DAY) <= created_at']) 
    @todays_comments = Comment.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 0 DAY) <= created_at'])
    
    @total_creds = Cred.count
    @todays_creds = Cred.count(:conditions  => ['DATE_SUB(CURRENT_DATE(),INTERVAL 0 DAY) <= created_at'])

  end

  def user
    @user = user = User.find_by_openid(params[:openid])   
    unless @user
      @user = user = User.find_by_id(params[:user_id])   
    end

    unless @user
      flash[:notice] = 'Unknown user'
      redirect_to :action => 'index'
      return
    end

    @total_claims = Claim.count(:conditions => ['user_id = ?',user.id])
    @total_comments = Comment.count(:conditions => ['user_id = ?',user.id])
  end

  def suspend_submit
    user = User.find(params[:user_id])
    user.set_state(:suspended)
    user.save!
 
    # red flag all their claims
    if params[:red_flag_claims].to_s == '1'
      user.claims.each {|c|
        c.state = 3 # red flag
        c.save!
      }
      
      # delete all their comments
      Comment.destroy_all(['user_id = ?', user.id])
      
      # delete all their votes
      ClaimVote.destroy_all(['user_id = ?', user.id])
      
      # delete all their cred to and from
      Cred.destroy_all(['source_id = ? OR sink_id = ?', user.id, user.id])
    end
    
    flash[:notice] = 'User suspended.'
    redirect_to :action => 'index'
  end
  
  def log_in_as
    session[:user_id] = params[:user_id].to_i
    redirect_to :controller => 'home'
  end

  private
  
  def check_admin_status
    if is_admin?
      return true
    end

    redirect_to front_url
    return false
  end

end
