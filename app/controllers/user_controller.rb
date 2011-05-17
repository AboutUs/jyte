class UserController < ApplicationController

  before_filter :auto_login
  before_filter :check_logged_in, 
                :except => [:profile,:api_user_info, :tag, :profile_about_claims,
                            :profile_about_claims, :profile_by_claims, :profile_votes,
                            :profile_comments, :profile_out_cred, :profile_in_cred, :profile_contacts,
                            :quick_find]
  secure_actions :only => [:account_submit,:give_cred_submit,:delete_icon,
                           :del_identifier,:set_primary,:settings,
                           :delete_account_submit,:delete_account_final,
                           :delete_account_confirm, :ignore]
                           
  def home
    redirect_to :controller => 'home'
  end

  # remove dispatches from "Home" page for a logged in user
  def clear
    if params[:t] == 'all'
      
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.dispatchable_type = 'Claim')")

    elsif params[:t] == 'page'
      
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.dispatchable_type = 'Claim') ORDER BY dispatches.created_at LIMIT 15")

    elsif (t = params[:t].to_i) != 0
      Dispatch.connection.execute("DELETE FROM dispatches WHERE (dispatches.user_id = #{liuid} AND dispatches.id = #{t})")
    else
      flash[:notice] = 'Ouch.'
    end
    
    redirect_to :action => 'home'
  end

  def profile_about_claims
    render :text => p_about_claims(params[:user_id])
  end

  def profile_by_claims
    render :text => p_by_claims(params[:user_id])
  end

  def profile_comments
    render :text => p_comments(params[:user_id])
  end

  def profile_votes
    render :text => p_votes(params[:user_id])
  end

  def profile_in_cred
    render :text => p_in_cred(params[:user_id])
  end

  def profile_out_cred
    render :text => p_out_cred(params[:user_id])
  end

  def profile_contacts
    render :text => p_contacts(params[:user_id])
  end

  def profile
    if params[:uid]
      @user = User.find(params[:uid])
      @openid = 'o'
    else
      @openid = Identifier.detect(params[:openid])
    
      ident = Identifier.find_by_value(@openid)
      if ident.nil? or ident.user.nil?
        flash[:notice] = "That user doesn't have a profile yet."
        redirect_to find_claims_url(:about => params[:openid])
        return
      end
    
      @user = ident.user
    end   
 
    if @user.get_state == :suspended
      flash[:notice] = 'That user account has been suspended.'
      redirect_to front_url
      return
    end

    if @user.get_state == :deleted
      redirect_to front_url
      return
    end

    ims = headers['if-modified-since']
    if ims and DateTime.parse(ims) > @user.last_login_at
      render :text => '', :status => 304
      return
    end

    @title = "Profile for #{@user.dn}"

    @profile_section = params[:show]
    sections = ["about_claims", "in_cred", "by_claims", "comments", "votes", "out_cred", "contacts"]
    @profile_section = "by_claims" unless sections.member? @profile_section
    
    # for "best qualities"
    unless @profile_section == "in_cred"
      @overall_score, @tagged_scores = Cred.scores(:user => @user, :limit => 6)
      @norm_cred_scores = Cred.scores_by_tag_and_user(@tagged_scores.keys, [@user.id], :normalized => true)
      @in_tags = Tag.find_all_by_id(@tagged_scores.keys)
      @in_tags.sort! {|a, b|(@tagged_scores[b.id] or 0) <=> (@tagged_scores[a.id] or 0)}
    end

    # for the give cred widget
    if liu
      if @cred_from_liu = Cred.find_by_source_id_and_sink_id(liuid, @user.id)
        @cred_from_liu_tags = @cred_from_liu.tag_list
      else
        @cred_from_liu_tags = ''
      end
    end

    @non_primary_identifiers = @user.identifiers.reject {|i| i.primary == true}
    @interests = @user.tags
    @groups = @user.groups
    fmt = @user.created_at.year == DateTime.now.year ? '%B %d' : '%B %d, %Y'
    @user_since = @user.created_at.strftime(fmt)

    @claim_tags = Tag.find_by_sql(["select tags.*, count(*) tag_count from tags join taggings on taggings.tag_id = tags.id join claims on taggings.taggable_id = claims.id and taggings.taggable_type = 'Claim' and claims.user_id = ? group by tags.id order by tag_count desc limit 23", @user.id])

    @claim_count = Claim.count(:conditions => ['user_id = ? AND state = 1', @user.id])
    @comment_count = Comment.count(:conditions => ['user_id = ?', @user.id])
    @agree_count = ClaimVote.count(:conditions => ['user_id = ? AND vote = true', @user.id])
    @disagree_count = ClaimVote.count(:conditions => ['user_id = ? AND vote = false', @user.id])
    @flipflop_count = ClaimVoteHistory.count(:conditions => ['user_id = ?', @user.id]) - (@agree_count + @disagree_count)

    @ignoring = !UserBlocking.find_by_user_id_and_blocked_user_id(liuid, @user.id).nil? #rails2.3

    @ignores_count = UserBlocking.count(:conditions => ['user_id = ?', @user.id])
    @ignored_count = UserBlocking.count(:conditions => ['blocked_user_id = ?', @user.id])

    # microid
    microids = @non_primary_identifiers.collect {|i| i.value}
    microids << @openid
    @microids = microids.collect {|i|
      proto = is_iname?(i) ? 'xri' : i.split(':')[0]
      "#{proto}+http:sha1:"+Digest::SHA1.hexdigest(Digest::SHA1.hexdigest(i)+Digest::SHA1.hexdigest(xprofile_url(@user.s)))}

    # rss links
    @rss_about_link = rss_claims_url(:about => @user.s, :only_path=>false)
    @rss_by_link = rss_claims_url(:by => @user.s, :only_path=>false)
    @rss_links = [@rss_by_link,@rss_about_link]

    case @profile_section
    when "by_claims"
      @history_box_content = p_by_claims(@user.id)
    when "about_claims"
      @history_box_content = p_about_claims(@user.id)
    when "votes"
      @history_box_content = p_votes(@user.id)
    when "comments"
      @history_box_content = p_comments(@user.id)
    when "in_cred"
      @history_box_content = p_in_cred(@user.id)
    when "out_cred"
      @history_box_content = p_out_cred(@user.id)
    when "contacts"
      @history_box_content = p_contacts(@user.id)
    end
  end

  def all_votes
    claim = Claim.find_by_urlslug(params[:urlslug])
    @votes, @voters, @scores_by_user_id = claim.votes_with_users_and_scores
  end

  def rank
    @page = params[:page].to_i
    params[:by] ||= "claims"
    if @page.nil? or @page < 1
      @page = 1
    end
    offset = ((@page - 1) * 23)
    limit_frag = "LIMIT #{offset}, 23"
    @tag = Tag.find_by_name(params[:tag])
    @tag_name = @tag.name if @tag

    if @tag
      cred_tag_join = " JOIN taggings ON taggable_type = 'Cred' 
                                     AND taggable_id = creds.id
                                     AND tag_id = #{@tag.id}"
      claim_tag_join = " JOIN taggings ON taggable_type = 'Claim' 
                                     AND taggable_id = claims.id
                                     AND tag_id = #{@tag.id}"
    elsif !params[:tag].blank?
      @title = "Tag \"#{params[:tag]}\" has not been used yet."
      @users = []
      return
    end

    @sort = params[:by]
    if @sort == "creds_given"
      sql = "SELECT users.id, users.nickname, COUNT(creds.id) cnt FROM users 
               JOIN creds ON users.id = creds.source_id"
      if @tag
        sql << cred_tag_join
        @title = "People who've given #{@tag} cred to the most people"
      else
        @title = "People who've given cred to the most people"
      end
      @cnt_title = "people"
    elsif @sort == "creds_gotten"
      sql = "SELECT users.id, users.nickname, COUNT(creds.id) cnt FROM users 
               JOIN creds ON users.id = creds.sink_id"
      if @tag
        sql << cred_tag_join
        @title = "People who've gotten #{@tag} cred from the most people"
      else
        @title = "People who've gotten cred from the most people"
      end
      @cnt_title = "people"     
    elsif @sort == "contacted"
      sql = "SELECT users.id, users.nickname, COUNT(*) cnt FROM users 
               JOIN contacts ON users.id = contacts.contact_id"
      if @tag
        sql << " JOIN taggings ON taggable_type = 'Contact' 
                                     AND taggable_id = contacts.id
                                     AND tag_id = #{@tag.id}"
        @title = "People called a contact (#{@tag}) by the most people"
      else
        @title = "People called a contact by the most people"
      end
      @cnt_title = "people"
    elsif @sort == "agreeability"
      sql = "SELECT users.id, users.nickname, SUM(CASE WHEN claim_votes.vote = (claims.yeas < claims.nays) THEN -1 ELSE 1 END) cnt FROM claim_votes
               JOIN users ON claim_votes.user_id = users.id
               JOIN claims ON claim_votes.claim_id = claims.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who agree with the majority most often about #{@tag}"
      else
        @title = "People who agree with the majority most often"
      end
      @cnt_title = "votes in majority less votes in minority"
    elsif @sort == "personal_agreeability"
      sql = "SELECT users.id, users.nickname, SUM(CASE WHEN sv.vote = ov.vote THEN 1 ELSE -1 END) cnt FROM claim_votes ov
               JOIN users ON ov.user_id = users.id AND users.id <> #{liuid}
               JOIN claim_votes sv ON sv.user_id = #{liuid}
                                  AND sv.claim_id = ov.claim_id"
      if @tag
        sql << " JOIN taggings ON taggable_type = 'Claim' 
                              AND taggable_id = sv.claim_id
                              AND taggable_id = ov.claim_id
                              AND tag_id = #{@tag.id}"
        @title = "People who agree with you most about #{@tag}"
      else
        @title = "People who agree with you most"
      end
      @cnt_title = "assent less dissent"
    elsif @sort == "personal_disagreeability"
      sql = "SELECT users.id, users.nickname, SUM(CASE WHEN sv.vote = ov.vote THEN -1 ELSE 1 END) cnt FROM claim_votes ov
               JOIN users ON ov.user_id = users.id AND users.id <> #{liuid}
               JOIN claim_votes sv ON sv.user_id = #{liuid}
                                  AND sv.claim_id = ov.claim_id"
      if @tag
        sql << " JOIN taggings ON taggable_type = 'Claim' 
                              AND taggable_id = sv.claim_id
                              AND taggable_id = ov.claim_id
                              AND tag_id = #{@tag.id}"
        @title = "People who disagree with you most about #{@tag}"
      else
        @title = "People who disagree with you most"
      end
      @cnt_title = "dissent less assent"
    elsif @sort == "comments"
      sql = "SELECT users.id, users.nickname, COUNT(comments.id) cnt FROM users
               JOIN comments ON comments.user_id = users.id"
      if @tag
        sql << " JOIN taggings ON taggable_type = 'Claim' 
                              AND taggable_id = comments.claim_id
                              AND tag_id = #{@tag.id}"
        @title = "People who have commented most on claims about #{@tag}"
      else
        @title = "People who have commented most"
      end
      @cnt_title = "comments"
    elsif @sort == "claims"
      sql = "SELECT users.id, users.nickname, COUNT(claims.id) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most claims about #{@tag}"
      else
        @title = "People who've made the most claims"
      end
      @cnt_title = "claims"
    elsif @sort == "votes"
      sql = "SELECT users.id, users.nickname, COUNT(claim_votes.id) cnt FROM users
               JOIN claim_votes ON claim_votes.user_id = users.id"
      if @tag
        sql << " JOIN taggings ON taggable_type = 'Claim' 
                              AND taggable_id = claim_votes.claim_id
                              AND tag_id = #{@tag.id}"
        @title = "People who have voted most on claims about #{@tag}"
      else
        @title = "People who have voted on the most claims"
      end
      @cnt_title = "votes"
    elsif @sort == "votes_on_claims"
      sql = "SELECT users.id, users.nickname, SUM(claims.yeas + claims.nays) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most voted claims about #{@tag}"
      else
        @title = "People who've made the most voted claims"
      end
      @cnt_title = "votes"
    elsif @sort == "votes_per_claim"
      sql = "SELECT users.id, users.nickname, SUM(claims.yeas + claims.nays - 1)/COUNT(*) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"     
      if @tag
        sql << claim_tag_join
        @title = "People with the most votes per claim about #{@tag}"
      else
        @title = "People with the most votes per claim"
      end
      @cnt_title = "votes (not including claimant's)"
    elsif @sort == "watched_claims"
      sql = "SELECT users.id, users.nickname, COUNT(*) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1
               JOIN flaggings ON flaggings.claim_id = claims.id
                             AND flaggings.watch = true"
      if @tag
        sql << claim_tag_join
        @title = "People whose claims about #{@tag} are most watched"
      else
        @title = "People whose claims are most watched"
      end
      @cnt_title = "eyeballs"
    elsif @sort == "trashed_claims"
      sql = "SELECT users.id, users.nickname, COUNT(*) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1
               JOIN flaggings ON flaggings.claim_id = claims.id
                             AND flaggings.trash = true"
      if @tag
        sql << claim_tag_join
        @title = "People whose claims about #{@tag} are most trashed"
      else
        @title = "People whose claims are most trashed"
      end
      @cnt_title = "trashcans"
    elsif @sort == "nays_on_claims"
      sql = "SELECT users.id, users.nickname, SUM(claims.nays) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most disagreed with claims about #{@tag}"
      else
        @title = "People who've made the most disagreed with claims"
      end
      @cnt_title = "disagree votes"
    elsif @sort == "yeas_on_claims"
      sql = "SELECT users.id, users.nickname, SUM(claims.yeas) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most agreed with claims about #{@tag}"
      else
        @title = "People who've made the most agreed with claims"
      end
      @cnt_title = "agree votes"
    elsif @sort == "contested_claims"
      sql = "SELECT users.id, users.nickname, 
      SUM(CASE WHEN claims.yeas > claims.nays THEN claims.nays ELSE claims.yeas END) cnt 
               FROM users
               JOIN claims ON claims.user_id = users.id"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most contested claims about #{@tag}"
      else
        @title = "People who've made the most contested claims"
      end
      @cnt_title = "total votes in minority"
    elsif @sort == "discussed_claims"
      sql = "SELECT users.id, users.nickname, SUM(claims.comments_count) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most discussed claims about #{@tag}"
      else
        @title = "People who've made the most discussed claims"
      end
      @cnt_title = "comments"
    elsif @sort == "your_votes_on_claims"
      sql = "SELECT users.id, users.nickname, COUNT(claim_votes.id) cnt FROM users
               JOIN claims ON claims.user_id = users.id
                          AND claims.state = 1
               JOIN claim_votes ON claim_votes.user_id = #{liuid}
                               AND claim_votes.claim_id = claims.id"
      if @tag
        sql << claim_tag_join
        @title = "People who've made the most claims about #{@tag} that you've voted on"
      else
        @title = "People who've made the most claims that you've voted on"
      end
      @cnt_title = "claims"
    elsif @sort == "cred_score"
      st = Cred.score_table_name
      sql = "SELECT users.id, users.nickname, scores.value cnt FROM users
               JOIN #{st} scores ON scores.user_id = users.id"
      if @tag
        sql << " AND scores.tag_id = #{@tag.id}"
        @title = "People with most #{@tag} cred"
      else
        @title = "People with most overall cred"
        sql << " AND scores.tag_id IS NULL"
      end
      @cnt_title = "score"
    end
    if sql
      sql << " GROUP BY users.id ORDER BY cnt DESC " << limit_frag
      @users = User.find_by_sql(sql)
    else
      @users = []
    end

  end

  def quick_find
    offset = (params[:page].to_i - 1) * 20
    offset = 0 if offset < 0
    @search_string = params[:uq]
    begin
      @users = User.find_by_solr(@search_string, :start => offset, :rows => 20)
    rescue
      # try scrubbing search string
      @search_string.gsub!(/[\(<\[\]>\)=!^~\?:;\*\+\-\\]/,'')
      @search_string.gsub!(/OR|AND|NOT/,'')
      @users = User.find_by_solr(@search_string, :start => offset, :rows => 20)
    end
    render :partial => '/user_find_results', :locals => {:users => @users}
  end

  def account
    @user = logged_in_user
  end

  def account_submit
    u = logged_in_user
    u.update_attributes(params[:user])
    u.tag_with(params[:tags])
    
    old_username = nil
    dn = params[:display_name].strip
    if dn and !dn.empty?
      if u.nickname.nil?
        u.nickname = dn
      elsif u.nickname != dn
        old_username = OldUsername.new(:user_id => u.id, :name => u.nickname)
        u.nickname = dn
      end
    else
      if u.nickname
        OldUsername.create(:user_id => u.id, :name => u.nickname)
      end
      u.nickname = nil
    end
    
    u.save
    u.solr_save

    # process image
    image_blob = read_blob(params[:image])

    if image_blob
      # destroy old image is necessary
      old_image = u.image
      if old_image
        u.imagings.destroy_all
        old_image.destroy_image(u)
      end

      begin
        im = Image.from_blob(image_blob, u)
        im.on(u)
      rescue
        flash[:notice] = "Sorry, we couldn't read that image.  Try another."
        redirect_to :action => 'account'
        return
      end
    end

    if u.valid?
      if old_username
        old_username.save
      end
      flash[:notice] = 'Profile saved.'
      redirect_to xprofile_url(u.s)
    else
      @user = u
      render :template => 'user/account'
    end
  end

  def delete_icon
    u = logged_in_user
    i = u.image
    if i
      u.imagings.destroy_all
      i.destroy_image(u)
    end

    redirect_to :action => 'account'
  end
  
  def set_primary
    Identifier.transaction {
      i = Identifier.find(params[:primary_id])
      raise 'doh' unless liu.identifiers.member?(i)
      cur = liu.identifier
      cur.primary = false
      i.primary = true
      i.save
      cur.save
    }
    redirect_to :action => 'account'
  end

  def del_identifier
    i = Identifier.find(params[:id])
    raise 'doh' if i.user != liu
    raise 'cannot delete primary identifer' if i.primary
    i.user = nil
    i.save
    redirect_to :action => 'account'
  end

  def confirm_email
    rc = EmailResponseCode.find_by_code(params[:code])
    if rc.nil? #  or rc.expired?
      flash[:notice] = "Sorry, couldn't find your confirmation code.  Please check the URL and try again."
      redirect_to :controller => 'home'
      return
    end
    u = liu
    u.email = rc.email
    u.save
    flash[:notice] = "You have successfully confirmed #{rc.email} as your email address."
    rc.destroy
    redirect_to :controller => 'home'
  end


  def give_cred
    @user = User.find_by_openid(params[:openid])
    unless @user
      flash[:notice] = 'Unknown user.'
      redirect_to :controller => ''
      return
    end

    @overall_cred, @tagged_cred = Cred.scores(:user_id => @user.id)
    if liu
      if @cred_from_liu = Cred.find_by_source_id_and_sink_id(liuid, @user.id)
        @cred_from_liu_tags = @cred_from_liu.tags.collect {|t| t.name}.join(' ')
      else
        @cred_from_liu_tags = ''
      end
    end
  end

  
  def give_cred_submit
    user = User.find(params[:user_id])

    if user == liu
      flash[:notice] = "Cannot give yourself cred."
      redirect_to xprofile_url(user.s)
      return
    end

    if params[:cred] and not params[:cred].strip.empty?
      cred = Cred.find_or_create_by_source_id_and_sink_id(liuid, user.id)
      old_tags = cred.tags.map{|t|t.name}
      if params[:cred].split(',').size > 200
        flash[:notice] = 'You are limited to giving 200 kinds of cred per person.'
      else
        cred.tag_with(params[:cred])
        new_tags = Tag.parse(params[:cred])
        flash[:notice] = 'Cred given. Scores will be updated shortly!'
        Happening.create(:happenable => cred)

        added_tags = new_tags - old_tags
        removed_tags = old_tags - new_tags
        if added_tags.empty?
          note = ""
        else
          note = "gave you #{oxford_comma_list(added_tags)} cred"
        end
        unless removed_tags.empty?
          note << " and " unless note.empty?
          note << "took back #{oxford_comma_list(removed_tags)} cred"
        end
        Dispatch.create(:user => user, :dispatchable => liu,:reason => note) unless note.empty? 
      end
    elsif params[:add]
      t = Tag.find_or_create_by_name(params[:add])
      cred = Cred.find_or_create_by_source_id_and_sink_id(liuid, user.id)
      Tagging.create(:taggable => cred, :tag_id => t.id)
    elsif params[:remove]
      t = Tag.find_by_name(params[:add])
      cred = Cred.find_by_source_id_and_sink_id(liuid, user.id)
      if t and cred
        ting = Tagging.find_by_tag_id_and_taggable_type_and_taggable_id(t.id, 'Cred', cred.id)
        ting.destroy if ting
        cred.destroy if cred.tags.empty?
      end
    elsif params[:remove_all]
      cred = Cred.find_by_source_id_and_sink_id(liuid, user.id)
      cred.destroy if cred
    elsif cred
      cred.destroy
      flash[:notice] = "Cred taken back."
    end
    
    if params[:render] == 'out_cred'
      @out_users, @out_tags, @out_tags_by_user_id, @out_users_by_tag_id = liu.out_cred_with_extras
      render :partial => 'out_cred', :locals => {:user => liu, :out_users => @out_users, :out_tags_by_user_id => @out_tags_by_user_id}
    elsif params[:render] == 'in_cred'

    else
      redirect_to xprofile_url(user.s)
    end
  end

  def ignore
    if add = params[:add]
      u = User.find_by_id(add)
      if u
        UserBlocking.find_or_create_by_user_id_and_blocked_user_id(liuid, u.id)
        render :partial => 'ignoring', :locals => {:user => u, :ignoring => true}
        return
      else
        # return an error code XXX 
        render :status => 500, :text => "Couldn't find that user."
      end
    elsif remove = params[:remove]
      u = User.find_by_id(remove)
      if ub = UserBlocking.find_or_create_by_user_id_and_blocked_user_id(liuid, u.id)
        ub.destroy
        render :partial => 'ignoring', :locals => {:user => u, :ignoring => false}
        return
      else
        # return an error code XXX 
        render :status => 500, :text => "You were not ignoring that person."
      end
    end
  end

  def settings
    @ignored_users = liu.blocked_users
  end

  def delete_account_submit
    session[:delete_account] = true
    redirect_to :action => 'delete_account_confirm'
  end

  def delete_account_confirm
  end

  def delete_account_final
    if session[:delete_account] == true
      session[:delete_account] = nil
      u = liu
      u.set_state(:deleted)
      u.save!
      flash[:notice] = 'Account deleted'
      redirect_to front_url
    end
  end

#  def XXXdelete_account_final
#    if session[:delete_account] == true
#      session[:delete_account] = nil
#      ActiveRecord::Base.transaction {
#        u = liu
#
#        # unset identifier as primary
#        pi = u.identifier
#        pi.primary = false
#        pi.save!

        # delete all imges
#        u.images.each {|i|
#          i.destroy_image(u)
#        }

#       u.destroy
#        session[:user_id] = nil
#      }
#      flash[:notice] = 'Account deleted.'
#      redirect_to front_url
#    else
#      redirect_to :action => 'settings'
#    end
# end

  include UserHelper
  def api_user_info
    user = User.find_by_openid(params[:openid])
    unless user
      render :text => "error: no user for that openid\n", :status => 400
      return
    end
    
    stuff = user_api_info(user)

    render :text => OpenID::Util.kvform(stuff), :status => 200
  end

  def tag
    @by = by = params.fetch(:by, :interest).to_sym

    @tag = params[:tag]
    if @tag.nil?
      flash[:notice] = "Need a tag to show that page."
      redirect_to front_url
      return      
    end

    # set page title
    if by == :interest
      @title = 'Users interested in ' + @tag    
    elsif by == :cred
      @title = 'Users with ' + @tag + ' cred'
    elsif by == :gave_cred
      @title = 'Users who have given ' + @tag + ' cred'
    else
      flash[:notice] = "Don't know how to do that."
      redirect_to front_url
      return
    end
    
    per_page = 30
    @page = params.fetch(:page, 1).to_i
    offset = (@page - 1) * per_page
    t = Tag.find_by_name(@tag)
   
    if t.nil?
      @user_count = 0
      @users = []
    
    elsif by == :interest
      @user_count = User.count_by_sql(["SELECT COUNT(*) FROM users JOIN taggings ON users.id = taggings.taggable_id AND taggings.taggable_type = 'User' AND taggings.tag_id = ?", t.id])

      @users = User.find_by_sql(["SELECT DISTINCT users.* FROM users JOIN taggings ON users.id = taggings.taggable_id AND taggings.taggable_type = 'User' AND taggings.tag_id = ? ORDER BY users.created_at DESC LIMIT #{per_page} OFFSET #{offset}", t.id])
       
    elsif by == :cred
      score_table = Cred.score_class.table_name
      @user_count = User.count_by_sql("SELECT COUNT(*) FROM users JOIN #{score_table} scores ON scores.user_id = users.id AND scores.tag_id = #{t.id}")
      
      @users = User.find_by_sql("SELECT users.* FROM users JOIN #{score_table} scores ON scores.user_id = users.id AND scores.tag_id = #{t.id} ORDER BY scores.value DESC LIMIT #{per_page} OFFSET #{offset}")
      
    elsif by == :gave_cred
      @user_count = User.count_by_sql("SELECT COUNT(*) FROM users WHERE users.id IN (SELECT creds.source_id FROM creds JOIN taggings ON taggings.taggable_type = 'Cred' AND taggings.tag_id = #{t.id} AND taggings.taggable_id = creds.id)")

      @users = User.find_by_sql("SELECT * FROM users WHERE users.id IN (SELECT creds.source_id FROM creds JOIN taggings ON taggings.taggable_type = 'Cred' AND taggings.tag_id = #{t.id} AND taggings.taggable_id = creds.id) ORDER BY users.created_at DESC LIMIT #{per_page} OFFSET #{offset}")

    end
    @last_page_number = (@user_count / per_page)+1
    
    if @user_count > 0
      user_ids = @users.collect {|u| u.id}
      @cred_scores = Cred.scores_for_users(user_ids, :tag_id => t.id, :normalized => true)
    else
      @cred_scores = {}
    end

    # find similar tags
    if t
      @similar_tags = Tag.find_neighbors(t.id,'User',:limit=>7,:min_count=>5) if by == :interest
      @similar_tags = Tag.find_neighbors(t.id,'Cred',:limit=>7,:min_count=>5) if by == :cred
    end
    
  end

  def widgets
  end
  
  def claimroll_setup
  end

end
