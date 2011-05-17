module UserHelper

  def user_api_info(user)
    stuff = {}
    stuff['nickname'] = user.dn
    stuff['primary_openid'] = user.s
    stuff['incoming_cred_count'] = Cred.count(:conditions => ['sink_id = ?',user.id]).to_s
    stuff['votes_count'] = ClaimVote.count(:conditions => ['user_id = ?',user.id])
    stuff['claims_count'] = Claim.count(:conditions => ['user_id = ? AND state = 1', user.id])
    stuff['comments_count'] = Comment.count(:conditions => ['user_id = ? ', user.id])

    if user.image
      stuff['thumb_icon_url'] = front_url.chomp('/') + image_url(user.image,'thumb')
      stuff['big_icon_url'] = front_url.chomp('/')  + image_url(user.image,'big')
    end
    
    # cred
    overall_score, tag_scores = Cred.scores(:user => user)
    if overall_score
      stuff['cred_total'] = display_cred(overall_score)
    else
      stuff['cred_total'] = '0.0'
    end
    
    if tag_scores.length > 0
      top = tag_scores.collect {|tid,s| [s,tid]}
      top.sort!
      top = top[-5..-1]
      top_tag_ids = top.collect {|s,tid| tid}
      
      tags = Tag.find(:all, :conditions => "id IN (#{top_tag_ids.join(',')})")
      tags_by_id = tags.hash_by(:id)
      stuff['top_cred_tags'] = top.collect {|s,tid| [tags_by_id[tid].name, s]}.reverse
    else
      stuff['top_cred_tags'] = []
    end
      
    return stuff
  end

  def p_about_claims(user_id)
    @user = User.find_by_id(user_id)
    @claims = @user.claims_about :limit => 10
    claim_ids = @claims.map{|c|c.id}
    @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
    batch_load_claim_data(claim_ids)
    @headline = "Claims about #{@user.dn}"
    if @claims.size == 10
      @more_url = url_for :controller => 'claim', :action => 'find', :about => @user.s, :page => 2
    end
    render_to_string :partial => 'claims'
  end

  def p_by_claims(user_id)
    @user = User.find(user_id)
    @claims = @user.recent_claims :limit => 10
    claim_ids = @claims.map{|c|c.id}
    @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
    batch_load_claim_data(claim_ids)
    @headline = "Claims by #{@user.dn}"
    if @claims.size == 10
      @more_url = url_for :controller => 'claim', :action => 'find', :by => @user.s, :page => 2
    end
    render_to_string :partial => 'claims'
  end

  def p_comments(user_id)
    @user = User.find(user_id)
    @claims = @user.claims_commented :limit => 10
    claim_ids = @claims.map{|c|c.id}
    @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
    batch_load_claim_data(claim_ids)
    @headline = "Claims with comments from #{@user.dn}"
    if @claims.size == 10
      @more_url = url_for :controller => 'claim', :action => 'find', :comments_by => @user.s, :page => 2
    end
    render_to_string :partial => 'claims'
  end

  def p_votes(user_id)
    @user = User.find(user_id)
    @voted_claims = @user.claims_voted :limit => 10
    claim_ids = @voted_claims.map{|c|c.id}
    @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
    batch_load_claim_data(claim_ids)
    render_to_string :partial => 'claim_votes'
  end

  def p_in_cred(user_id)
    @user = User.find(user_id)
    
    @in_users, @in_tags, @in_tags_by_user_id, @in_users_by_tag_id = @user.in_cred_with_extras
    @overall_score, @tagged_scores = Cred.scores(:user => @user)
    @in_tags.sort! {|a, b|(@tagged_scores[b.id] or 0) <=> (@tagged_scores[a.id] or 0)}
    user_ids = @in_users.map{|u|u.id} << @user.id
    tag_ids = @in_tags.map{|t|t.id}
    @norm_cred_scores = Cred.scores_by_tag_and_user(tag_ids, user_ids, :normalized => true)
    render_to_string :partial => 'in_cred'
  end

  def p_out_cred(user_id)
    @user = User.find(user_id)
    @out_users, @out_tags, @out_tags_by_user_id, @out_users_by_tag_id = @user.out_cred_with_extras
    
    uids = @out_users.map{|u|u.id} << @user.id
    @user_icons = Image.for_users(uids)
    render_to_string :partial => 'out_cred', :locals => {:out_users => @out_users, :out_tags => @out_tags, :out_tags_by_user_id => @out_tags_by_user_id, :out_users_by_tag_id => @out_users_by_tag_id, :user => @user}
  end
  
  def p_contacts(user_id)
    @user = User.find(user_id)
    
    @contacts = Contact.find(:all,
                             :conditions => ['user_id = ?', @user.id],
                             :include => [:contact])

    # don't include blocked users as contact of
    blocked = @user.blocked_user_ids
    if blocked.size > 0
      blocked_sql = " AND user_id NOT IN (#{blocked.join(',')})"
    else
      blocked_sql = ""
    end

    @contact_of_count = Contact.count_by_sql(["SELECT COUNT(*) FROM contacts WHERE contact_id = ? #{blocked_sql}", @user.id])

    render_to_string :partial => 'contacts', :locals => {:contacts => @contacts,
    :contact_of_count => @contact_of_count}
    
  end

end
