class Array
  
  def hash_by(attr)
    h = {}
    self.each {|i| h[i.send(attr)] = i}
    return h
  end
  
end


Kernel.srand

class ClaimController < ApplicationController
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper
  include ClaimHelper

  before_filter :auto_login
  before_filter :check_logged_in, :except => [:show, :find, :votes, :random]

  secure_actions :only => [:new_submit,:preview_submit,:vote,:discard_claim,
                          :delete_image,:comment,:publish,:flag,:mark
			  ]
  # XXX:These didn't work on the live site as secure actions for some unknown reason:
  # :save_search,:remove_saved_search]
  
  def new
    @title = "Make a Claim"

    # make sure the person trying to make the claim is a group member
    if params[:group_id]
      group = Group.find_by_id(params[:group_id])
      if group and group.member?(liu)
        @group = group
      end
    end

    @claimable_type = params[:claimable_type]
    @claimable_id = params[:claimable_id]
    if @claimable_type == "Comment"
      @claimable = Comment.find_by_id(@claimable_id)
    elsif @claimable_type == "Claim"
      @claimable = Claim.find_by_id(@claimable_id)
    end
  end
   
  def new_submit
    claim_text = params[:new_claim_text]
    ct = params[:claimable_type]
    cid = params[:claimable_id]

    if claim_text.nil? or claim_text.empty?
      flash[:notice] = 'You cannot make an empty claim'
      redirect_to :action => 'new'
      return
    end

    # XXX comma separation?
    claim_tags = (params[:new_claim_tags] or '')

    c = Claim.create(:user_id => liuid,
                     :original => claim_text)
    unless c.valid?
      if same = c.errors.on(:same)
        flash[:notice] = "Someone already made that claim."
        redirect_to :controller => 'claim', :action => 'show', :urlslug => same
        return
      end
      if errors = c.errors[:text]
        if errors.class == Array
          errors = errors.join(" ")
        end
        flash[:notice] = errors

        if ct
          redirect_to :action => 'new', :text => claim_text, :tags => claim_tags, :claimable_type => ct, :claimable_id => cid
        else
          redirect_to :action => 'new', :text => claim_text, :tags => claim_tags, :group_id => params[:group_id]
        end
        return
      end
    end

    # make sure the person trying to make the claim is a group member
    if params[:group_id]
      group = Group.find_by_id(params[:group_id])
      if group and group.member?(liu)
        c.group_id = group.id
        c.save
      end
    end

    c.tag_with claim_tags

    if ct == 'Comment'
      comment = Comment.find(cid)
      c.inspired_by(comment)
    elsif ct == 'Claim'
      c2 = Claim.find(cid)
      c.inspired_by(c2)
    end

    c = Claim.find_by_id(c.id)

    redirect_to :action => 'preview', :urlslug => c.urlslug
  end
 
  def preview
    @claim = Claim.find_by_urlslug(params[:urlslug])
    if @claim.nil?
      redirect_to :controller => 'home', :action => 'drafts'
      flash[:notice] = "Couldn't find that draft claim."
      return
    elsif @claim.state > 0
      redirect_to :action => 'show', :urlslug => @claim.urlslug
      return
    end
    @title = @claim.title

    scrubbed = @claim.original.downcase.gsub(/[(<\[\]>)=!^~?:*+.,\\]/,'').strip
    scrubbed = scrubbed.gsub(/-/, ' ').gsub('  +', ' ')
    similar_query = scrubbed.split.uniq.reject{|w|w.size < 3}.join(' OR ')
    
    begin
      @similar = Claim.find_by_solr(similar_query, :start => 0, :rows => 10)
      @similar.reject! {|c| c.digest == @claim.digest or c.state != 1}
    rescue
      @similar = []
    end
  end

  def preview_submit
    @claim = Claim.find_by_id(params[:id])
    slug = @claim.urlslug

    if liuid == @claim.user_id and @claim.state == 0
      @claim.original = params[:claim_text]
      @claim.body = params[:claim_body]

      # apply group
      if params[:claim]
        @claim.group_id = params[:claim][:group_id]
      end

      if @claim.save
        slug = @claim.urlslug
      end
      @claim.tag_with params[:claim_tags]

      # apply image
      if image_blob = read_blob(params[:claim_image])
        if old_image = @claim.image
          @claim.imagings.destroy_all
          old_image.destroy_image(@claim)
        end

        if im = Image.from_blob(image_blob, @claim)
          im.on(@claim)
        end
      end

      errors = []
      if text_errors = @claim.errors[:text]
        if text_errors.class == Array
          errors = text_errors
        else
          errors = [text_errors]
        end
      end
      if @claim.errors[:same]
        errors << "Someone already made that claim."
      end
      flash[:notice] = errors.join(' ') unless errors.empty?

      if errors.empty? and params[:commit] == "Publish" or params[:commit] == "Publish Changes"
        redirect_to :action => 'publish', :id => @claim.id
      else
        redirect_to :action => 'preview', :urlslug => slug, :group_id => params[:group_id]
      end
      return
    else
      if not logged_in?
        flash[:notice] = "You must sign in."
      elsif liuid != @claim.user_id
        flash[:notice] = "That is not your claim."
      elsif @claim.state > 0
        redirect_to claim_url(:urlslug => @claim.urlslug)
        return
      end
      redirect_to front_url
    end
  end

  def change_tags
    claim = Claim.find(params[:claim_id])
    if claim.user_id == liuid
      claim.tag_with(params[:tags])
      render :partial => 'tags', :locals => {:claim => claim}
    else
      render :text => "You cannot do that."
    end
  end

  def discard_claim
    claim = Claim.find_by_id(params[:id])
    if claim and liuid == claim.user_id and claim.state == 0
      claim.image.destroy_image(claim) if claim.image
      claim.destroy
      flash[:notice] = 'Draft claim deleted'
    end
    redirect_to front_url
  end

  def delete_image
    @claim = Claim.find(params[:id])
    if liuid == @claim.user_id and @claim.state == 0
      if old_image = @claim.image
        @claim.imagings.destroy_all
        old_image.destroy_image(@claim)
      end
    end
    redirect_to :action => 'preview', :urlslug => @claim.urlslug
  end

  def publish
    @claim = Claim.find_by_id(params[:id])
    if liuid == @claim.user_id
      if @claim.state == 0
        @claim.publish

      elsif params[:retract] and (@claim.state == 1 or @claim.state == 4)
        if @claim.yeas + @claim.nays + @claim.comments_count == 1
          @claim.state = 0
          @claim.save
          Dispatch.find_all_by_dispatchable_type_and_dispatchable_id("Claim", @claim.id).each{|d|d.destroy}
          @claim.solr_destroy
          flash[:notice] = "Claim retracted."
          redirect_to :action => 'preview', :urlslug => @claim.urlslug
          return
        else
          flash[:notice] = "Sorry, too late."
          redirect_to :action => 'show', :urlslug => @claim.urlslug
          return
        end
      end
    else
      if not logged_in?
        flash[:notice] = "You must sign in."
      elsif liuid != @claim.user_id
        flash[:notice] = "That is not your claim."
      end
    end
    if @claim.state > 0
      redirect_to claim_url(:urlslug => @claim.urlslug)
    else
      redirect_to front_url
    end
  end

  def show
    if params[:id]
      @claim = Claim.find_by_id(params[:id], :conditions => 'state > 0')
    elsif params[:urlslug]
      @claim = Claim.find_by_urlslug(params[:urlslug], :conditions => 'state > 0')
    end
    unless @claim
      flash[:notice] = "Didn't find a claim"
      # XXX or 404?
      redirect_to front_url
      return
    end

    ims = headers['if-modified-since']
    modtime = @claim.commented_at
    modtime = @claim.created_at if modtime.nil?
    if ims and DateTime.parse(ims) > modtime
      render :text => '', :status => 304
      return
    end

    if @claim.state == 2
      unless logged_in?
        # XXX maybe issue a 403 if the user-agent doesn't look like a browser
        flash[:notice] = "That claim is yellow flagged.  You must sign in to see it."
        redirect_to front_url
        return
      else
        flash[:notice] = "This claim is yellow flagged.  Only signed in users may see it."
      end
    end

    if @claim.state == 3
      if @claim.user_id == liuid
        flash[:notice] = "This claim is red flagged.  Only you can see it."
      else
        # XXX maybe issue a 403 if the user-agent doesn't look like a browser
        flash[:notice] = "That claim is red flagged and may not be viewed."
        redirect_to front_url
        return
      end
    end
    unless params[:urlslug]
      redirect_to :urlslug => @claim.urlslug
      return
    end
    
    if @claim.state == 4
      unless @claim.group.member?(liu)
        flash[:notice] = "You must be a member of #{@claim.group.name} to see that claim"
        redirect_to front_url
        return
      end

    end

    @title = @claim.title + " - Cast your vote"

    @claimant_vote = @claim.user.vote_on(@claim)
    if @claimant_vote
      @claimant_disagrees = @claimant_vote.vote == false
    end
    
    if @claimant_disagrees
      dis = " but disagreed"
    else
      dis = ""
    end
    @meta_tags = {"description" => "#{@claim.user.dn} claimed#{dis}, #{@claim.title}  #{@claim.yeas} agree and #{@claim.nays} disagree. #{@claim.comments_count} comments.",
                  "keywords" => @claim.tag_list
                  }

    @comments = Comment.find_by_sql("SELECT * FROM comments WHERE claim_id = #{@claim.id}")
    @user_icons = Image.for_users(@comments.map{|c|c.user_id}.uniq) unless @comments.empty?

    if logged_in?
      # Clear user's dispatches to this claim
      Dispatch.find_all_by_dispatchable_type_and_dispatchable_id_and_user_id('Claim', @claim.id, logged_in_user_id).each {|d| d.destroy }

      # clear the dispatches to the comments as well
      Dispatch.find_by_sql(["SELECT dispatches.* FROM dispatches JOIN comments ON comments.claim_id = ? AND dispatches.dispatchable_type = 'Comment' AND dispatches.dispatchable_id = comments.id AND dispatches.user_id = ?", @claim.id, logged_in_user_id]).each { |d|
        d.destroy
      }

      # the validation sometimes fails. argh.
      looks = Look.find_all_by_user_id_and_object_type_and_object_id(liuid, 'Claim', @claim.id, :order => 'created_at') 
      if looks.empty?
        Look.create(:user_id => liuid, :object => @claim)
      else
        looks[0].touch
        if looks.size > 1
          looks[1..-1].each{|l|
            RAILS_DEFAULT_LOGGER.info("deleting duplicate look on claim #{@claim.title} for user #{liu.display_name}")
            l.destroy
          }
        end
      end

      @blocked_user_ids = liu.blocked_user_ids      
    end

    tag_ids = Claim.connection.select_values("SELECT tag_id FROM taggings WHERE taggable_type = 'Claim' AND taggable_id = #{@claim.id}")
    @liuvote, @yea_vote_users, @nay_vote_users = votes_for_claim(@claim, tag_ids)

    if tag_ids.empty?
      @similar = []
    else
      tag_ids_frag = '(' + tag_ids.join(',') + ')'
      similar_sql = "SELECT claims.*
                       FROM claims
                       JOIN taggings ON taggings.taggable_id = claims.id
                                    AND taggings.taggable_type = 'Claim'
                                    AND taggings.tag_id IN #{tag_ids_frag}
                      WHERE claims.id <> #{@claim.id}
                        AND claims.state = 1
                      GROUP BY claims.id
                      ORDER BY COUNT(taggings.id) DESC, id
                      LIMIT 5"
      @similar = Claim.find_by_sql(similar_sql)
    end

    @sameclaims = Claim.find_all_by_digest(@claim.digest, :conditions => ['state = 1 AND id != ?', @claim.id])

    @can_edit_tags = !! (liuid.to_i == @claim.user_id or Contact.find_by_user_id_and_contact_id(@claim.user_id,liuid))

    cred_user_ids = ([liuid.to_i]+(@yea_vote_users+@nay_vote_users).map{|u|u.id}+@comments.map{|c|c.user_id}).uniq
    @norm_cred_scores = {}
    @norm_cred_scores[nil] = Cred.scores_for_users(cred_user_ids, :normalized => true)
  end



  def invite
    invitee = params[:openid_or_email]
    if invitee.nil? or invitee.strip.empty?
      render :text => "Please enter an OpenID or email address."
      return
    end
    
    cid = params[:claim_id].to_i
    raise if cid == 0
    user = User.find_by_openid_or_email(invitee)
    inv = Invitation.new(:sender_id => logged_in_user_id,
                         :claim_id => cid)
    if user
      claim = Claim.find(cid)
      if (user.voted? claim or user.commented? claim)
        render :text => "#{user.dn} has already been to this claim"
        return
      elsif Dispatch.find_by_user_id_and_dispatchable_type_and_dispatchable_id(user.id, 'Claim', claim.id)
        render :text => "This claim is already on #{user.dn}'s list."
        return
      else
        user.dispatch(claim, :from => liu, :reason => 'invite')
        render :text => "Invited #{user.dn}"
      end
    elsif invitee.match(/.+@.+/)
      if erc = EmailResponseCode.find_by_email(invitee)
        if Invitation.find_by_response_id_and_claim_id(erc.id, cid)
          render :text => "That person has already been invited to view this claim."
        else
          inv.response = erc
          inv.save!
          render :text => "Jyte will only send one invitation email per address, but we've added this to their list for when they arrive"
        end
        return
      else # Haven't sent a mail yet
        erc = EmailResponseCode.create(:email => invitee)
        inv.response = erc
        inv.save!
        response_url = url_for :controller => 'auth', :action => 'invite_response', :code => erc.code
        DearStrongbad.deliver_invite(inv, response_url)
        @invitee = invitee
        render :text => "Sent an invitation to that email address."
      end
    else
      render :text => "No user with that OpenID has yet signed into Jyte.  We can send an email invitation if you provide an email address."
      return
    end
  end

  def find
    if params[:bc_order]
      params[:order] = params[:bc_order]
      params[:bc_order] = nil
      redirect_to params
      return
    end
    @page = params[:page].to_i
    @page = 1 if @page == 0

    @claims, extras = find_claims({:count => true,
                                  :linked_title => true,
                                  :limit => 10,
                                  :offset => (@page - 1) * 10,
                                  :user_id => liuid,
                                  :tagnames => true,
                                  }.merge(clean_search_params(params)))
    @search_title = extras[:title]
    @title = strip_tags(@search_title)
    @claim_count = extras[:count]
    @tagnames = extras[:tagnames]

    # this view can do rss?
    @rss_links = []
    if rss_allowed?
      rss_params = params.dup
      rss_params[:only_path] = false
      rss_params[:page] = nil
      @rss_link = rss_claims_url(rss_params)
      @rss_links << @rss_link

      if params[:format] == 'rss'
        rss_params[:format] = nil
        @rss_channel_link = find_claims_url(rss_params)

        headers['Content-Type'] = 'text/xml'
        render :template => 'rss/claims', :layout => false
        return
      end
    else
      @rss_link = nil
    end
    
    batch_load_claim_data(@claims.collect {|c| c.id})

    @start_n = 10 * @page - 9
    @end_n = 10 * @page
    @end_n = @claim_count if @end_n > @claim_count
    
    @norm_cred_scores = {}
    @norm_cred_scores[nil] = Cred.scores_for_users(@claims.map{|c|c.user_id}, :normalized => true)

    if logged_in?
      @liu_votes = ClaimVote.find_all_votes_hash(liuid,@claims.map{|c|c.id})
    end

    # Stuff for the left column
    # If we have some tags, show contextual tag info (similar tags,
    # interested users, user's w/ that cred)
    if @tagnames and @tagnames.size > 0 and (tag = Tag.find_by_name(@tagnames[0]))
      @tag = tag
      scores = Cred.score_class.table_name
      @users = User.find_by_sql("SELECT users.id, users.nickname FROM users JOIN #{scores} scores ON scores.user_id = users.id AND scores.tag_id = #{tag.id} ORDER BY scores.value DESC LIMIT 10")
      cred_users_ids = @users.map{|u|u.id}
      if @users.empty?
        @users_title = "No users with #{tag.name} cred"
      else
        @users_title = "Users with most #{tag.name} cred"
      end
      @more_users = User.find_by_sql("SELECT users.id, users.nickname FROM users JOIN taggings ON taggings.taggable_type = 'User' AND taggings.taggable_id = users.id AND taggings.tag_id = #{tag.id} ORDER BY users.id DESC LIMIT 10").reject{|u|cred_users_ids.member? u.id}[0..14]
      if @more_users.empty?
        # may not strictly be true... oh well.
        @more_users_title = "No users interested in #{tag.name}"
      else
        @more_users_title = "Users interested in #{tag.name}"
      end
      @similar_tags = Tag.find_neighbors(tag.id, 'Claim', :min_count=>2)
    elsif params[:interests] and logged_in?
      @interests = liu.tags
      unless @interests.empty?
        @users_title = "Users with similar interests"
        tids = @interests.map{|t|t.id}
        @users = User.find_by_sql("SELECT users.id, users.nickname FROM users JOIN taggings ON taggings.taggable_type = 'User' AND taggings.taggable_id = users.id AND taggings.tag_id IN (#{tids.join(',')}) WHERE users.id != #{liuid} GROUP BY users.id ORDER BY count(*) DESC LIMIT 10")
      end
    else
      @static_tags_title = "Tags"
      @static_tags =  %w(jyte politics food music internet philosophy psychology life religion language programming culture science technology silly humor).sort

      @users_title = "Today's Top Claimants"
      yesterday = Claim.connection.quoted_date(DateTime.now - 1)
      @users = User.find_by_sql("SELECT users.id, users.nickname, SUM(claims.yeas + claims.nays - 1) AS claim_count FROM users JOIN claims ON claims.user_id = users.id AND claims.state = 1 AND claims.created_at > '#{yesterday}' GROUP BY claims.user_id ORDER BY claim_count DESC LIMIT 10")
      @users_link_to_claims = true
    end
  end

  # the full interface to find
  def advanced_search
    @saved_searches = liu.settings[:saved_searches] or {}
  end

  def save_search
    u = liu
    unless u.settings[:saved_searches]
      u.settings[:saved_searches] = {}
    end
    search = clean_search_params(params)
    errors = []
    if url_for(params.update(:action => 'find')).size > 2000
      errors << "That search is too long."
    end
    search_name = params[:search_name]
    if search_name.size > 50
      errors << "That name is too long."
    end
    if search_name.empty?
      errors << "Your search needs a name."
    end
    if u.settings[:saved_searches].size > 19
      errors << "You can only have 20 saved searches.  Remove some or use bookmarks to save additional searches."
    end
    if errors.empty?
      u.settings[:saved_searches].update(search_name => search)
      u.save
    end
    if !request.xhr?
      unless errors.empty?
        flash[:notice] = errors.join(' ')
      end
      redirect_to params.update(:action => 'advanced_search')
    else
      if errors.empty?
        render :partial => 'saved_searches'
      else
        render :text => errors.join(' '), :status => 500
      end
    end
  end

  def remove_saved_search
    u = liu
    if u.settings[:saved_searches]
      u.settings[:saved_searches].delete(params[:name])
      u.save
    end
    if !request.xhr?
      redirect_to request.referer
    else
      render :partial => 'saved_searches'
    end
  end

  def vote
    claim_id = params[:claim_id].to_i
    raise if claim_id == 0

    approval = (params[:vote] == 'yes')

    ch = Claim.connection.select_one("SELECT group_id, state FROM claims WHERE claims.id = #{claim_id}")
    state = ch['state'].to_i
    group_id = ch['group_id'].to_i
    if state == 4 
      unless GroupMembership.find_by_user_id_and_group_id(liuid,group_id)
        render :text => 'cannot vote on this group claim', :status => 403
        return
      end
    elsif state != 1
      render :text => 'cannot vote this claim', :status => 403
      return
    end

    v = ClaimVote.find(:first, :conditions => ["claim_id = ? AND user_id = ?", claim_id, liuid])
    if v
      v.vote = approval
      v.save
    else
      ClaimVote.create!(:claim_id => claim_id, :user_id => liuid, :vote => approval)
    end

    Dispatch.find(:all, :conditions => ["dispatchable_type = 'Claim' AND dispatchable_id = ? AND user_id = ?", claim_id, liuid]).each{|d|d.destroy}

    if !request.xhr?
      redirect_to :controller => 'claim', :action => 'show', :id => params[:claim_id] #XXX added by brian to stop exceptions for non-js users or clicked while logged out users
    else
      # XXX: what do we really want to do here?
      render :text => 'voted'
    end
  end

  def votes
    @claim = Claim.find_by_id(params[:id])
    unless @claim
      flash[:notice] = "Sorry, that claim could not be found."
      if ref = request.referer
        redirect_to ref
      else
        redirect_to front_url
      end
      return
    end
    
    options = {
      :per_page => 30,
      :order => 'claim_votes.created_at DESC',
      :joins => 'JOIN users ON users.id = claim_votes.user_id',
      :include => :user
    }
    
    @voted = voted = params[:votes]
    if voted == 'yes'
      options[:conditions] = ["claim_id = ? AND vote = true AND #{User.exclude_sql}", @claim.id]
    elsif voted == 'no'
      options[:conditions] = ["claim_id = ? AND vote = false AND #{User.exclude_sql}", @claim.id]
    else
      options[:conditions] = ["claim_id = ? AND #{User.exclude_sql}", @claim.id]
    end
    
    @votes = ClaimVote.paginate(:all, options.merge({:page => params[:page], :per_page => 30}))
    
  end

  def comment
    @claim = Claim.find(params[:claim_id])

    group_id = @claim.group_id
    if group_id
      unless GroupMembership.find_by_user_id_and_group_id(liuid,group_id)
        render :text => 'cannot comment on this group claim', :status => 403
        return
      end
    end

    c = Comment.new(:claim_id => params[:claim_id],
                    :user_id => session[:user_id],
                    :body => params[:body])

    if !request.xhr?
      c.save
      redirect_to claim_url(:urlslug=>@claim.urlslug, :anchor=>'new_comment')
    elsif params[:preview]=='t'
      c.created_at = DateTime.now
      render :partial => 'comment_preview', :locals => {:c => c}
    elsif params[:publish]=='t'
      c.save
      l = Look.find_by_user_id_and_object_type_and_object_id(liuid, 'Claim', @claim.id)
      if l.nil? # odd
        l = Look.new(:user_id => liuid, :object => @claim) 
      end
      l.touch
      @blocked_user_ids = liu.blocked_user_ids      
      com_html = render_to_string :partial => 'comment', :collection => @claim.comments
      html = com_html + " <script type='text/javascript'>
                            $('comment_preview').innerHTML = ''; 
                            $('new_comment_textarea').value = '';
                          </script>"
      render :text => html
    else
      raise "Bad comment submission"
    end
    
  end
 
  def flag
    c = Claim.find_by_id(params[:claim_id])
    if c or liu.can_flag(c)
      # Flagging.create(:user_id => liuid, :claim_id => c.id)
      c.flag(:red)
      c.save
      redirect_to claim_url(:urlslug => c.urlslug)
    else
      flash[:notice] = "You can't flag that claim."
      redirect_to front_url #claim_url(:urlslug => c.urlslug)
    end
  end

  def mark
    cid = params[:claim_id].to_i
    cid == 0 and raise
    raise unless params[:watch] or params[:trash]
    Dispatch.find_all_by_dispatchable_type_and_dispatchable_id_and_user_id('Claim', cid, liuid).each {|d|
      d.destroy
    }
    f = Flagging.find_or_create_by_user_id_and_claim_id(liuid, cid)
    if params[:watch] == 'y'
      f.watch = true
    else
      f.watch = false
    end
    if params[:trash] == 'y'
      f.trash = true
    else
      f.trash = false
    end
    f.save
    if !request.xhr?
      redirect_to request.referer
    else
      render :text => ''
    end
  end

  def tagroll_setup
    @tags = params[:tags] || ''
    @tags = Tag.parse(@tags).join(', ')
  end

  def random
    c = Claim.count

    claim = Claim.find_by_id(rand(c))
    while claim.nil? or 
        claim.state != 1 or  
        (logged_in? and ill=liu.settings[:ignore_list] and ill.member?(claim.user_id)) or 
      (logged_in? and Flagging.find_by_user_id_and_claim_id_and_trash(liuid,claim.id,true))
      
      claim = Claim.find_by_id(rand(c))
    end

    redirect_to claim_url(claim.urlslug)
  end


  def inspiration_tree

  end

  def inspiration_tree_xml
    @base_claim = Claim.find(params[:id])
    @root_claim = @base_claim.root_inspiring_claim
    if @root_claim.nil?
      #error
      raise
    end
    
    render :text => inspired_claims_xml(@root_claim, :root => true)
    
  end


  private

  ALLOWED_RSS_ORDERS = [nil,'featured'] #nil is recent
  def rss_allowed? # this is weird to have in a separate function since it's used exactly once
    return false unless ALLOWED_RSS_ORDERS.member?(params[:order])
    return false if params[:voted] or params[:comments]
    return false if params[:group_id]
    return true
  end

  def attr_escape(s) # XXX use a real escaper
    s.gsub("'","&#39;")
  end

 def find_claims(options)
    extras = {}
    errors = []
    
    if options[:states] == :all
      cond_list = []
    elsif options[:states].nil?
      if options[:group_id]
        cond_list = []
      else
        cond_list = ["claims.state = 1"]
      end
    elsif states = options[:states].map{|s|s.to_i}
      cond_list = ["claims.state IN (#{states.join(',')})"]
    else
      raise "bad states option"
    end

    user_id = options[:user_id]
    if user_id
      user_id = user_id.to_i
      user = User.find(user_id)
      ignore_list = user.blocked_user_ids
    end

    join_list = []
    
    if options[:order] == 'voted'
      order = '(claims.yeas + claims.nays) DESC'
      title = "Most voted on claims"
    elsif options[:order] == 'discussed'
      order = 'claims.comments_count DESC'
      cond_list << 'claims.comments_count > 0'
      title = "Most discussed claims"
    elsif options[:order] == 'contested'
      order = "CASE WHEN claims.yeas > claims.nays THEN claims.nays ELSE claims.yeas END DESC"
      cond_list << "claims.nays > 0 AND claims.yeas > 0"
      title = "Contested claims"
    elsif options[:order] == 'solid'
      order = "CASE WHEN claims.yeas > claims.nays THEN claims.yeas - 4 * claims.nays ELSE claims.nays - 4 * claims.yeas END DESC"
      cond_list << "(claims.nays > 1 OR claims.yeas > 1)"
      title = "Solid claims"
    elsif options[:order] == 'recently_commented'
      title = "Recently commented on claims"
      order = "claims.commented_at DESC"
      cond_list << 'claims.comments_count > 0'
      group_frag = "GROUP BY claims.id"
    elsif options[:order] == 'recently_voted'
      title = "Recently voted on claims"
      cond_list << '(claims.yeas + claims.nays) > 1'
      order = "claims.voted_at DESC"
      group_frag = "GROUP BY claims.id"
    elsif options[:order] == 'featured'
      order = 'claims.created_at DESC'
      title = "Featured claims"
      join_list << "JOIN featured_claims ON claims.id = featured_claims.claim_id"
    elsif options[:order] == 'relevance' 
      title = "Most relevant claims"
      order = "COUNT(*) DESC"
      group_frag = "GROUP BY claims.id"
    elsif options[:order] == 'oldest'
      order = 'claims.created_at'
      title = "Oldest claims"
    elsif options[:order] == 'watched'
      # XXX we could maintain a count
      join_list << "JOIN flaggings AS sf ON claims.id = sf.claim_id AND sf.watch = true"
      order = 'COUNT(*) DESC'
      group_frag = "GROUP BY claims.id"
      title = "Most watched claims"
    elsif options[:order] == 'trashed'
      # XXX we could maintain a count
      join_list << "JOIN flaggings AS sf ON claims.id = sf.claim_id AND sf.trash = true"
      order = 'COUNT(*) DESC'
      group_frag = "GROUP BY claims.id"
      title = "Most trashed claims"
    else
      order = 'claims.created_at DESC'
      title = "Newest claims"
    end
    
    if user_id

      if (group_id = options[:group_id].to_i) != 0
        if GroupMembership.find_by_group_id_and_user_id(group_id, user_id)
          cond_list << "claims.group_id = #{group_id}"
          group = Group.find(group_id)
          cond_list << "claims.state = 4"
          if options[:linked_title]
            title << " for <a href='#{group_url(:urlslug => group.urlslug)}'>#{ERB::Util.h(group.name)}</a>"
          else
            title << " for #{ERB::Util.h(group.name)}"
          end
        else
          errors << "You are not a member of that group."
          cond_list << "claims.state = 1"
        end
      end

      if options[:voted] == 'no'
        title << " you have not yet voted on"
        join = "LEFT JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id}"
        join_list << join
        cond_list << "claim_votes.id IS NULL"
      elsif options[:voted] == 'yes'
        title << " you have voted on"
        join = "JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id}"
        join_list << join
      elsif options[:voted] == 'up'
        title << " you have agreed with"
        join = "JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id} AND claim_votes.vote = true"
        join_list << join
      elsif options[:voted] == 'down'
        title << " you have disagreed with"
        join = "JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id} AND claim_votes.vote = false"
        join_list << join
      elsif options[:voted] == 'minority'
        title << " you voted with the minority"
        join = "JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id} AND claim_votes.vote = (claims.yeas < claims.nays)"
        join_list << join
      elsif options[:voted] == 'majority'
        title << " you voted with the majority"
        join = "JOIN claim_votes ON claim_votes.claim_id = claims.id AND claim_votes.user_id = #{user_id} AND claim_votes.vote = (claims.yeas > claims.nays)"
        join_list << join
      end
      if options[:visited]
        title << " you have visited"
        join = "JOIN looks visits ON visits.object_type = 'Claim' AND visits.object_id = claims.id AND visits.user_id = #{user_id}"
        join_list << join
      end
      if options[:watched]
        title << " you are watching"
        join = "JOIN flaggings wings ON wings.claim_id = claims.id AND wings.watch = true AND wings.user_id = #{user_id}"
        join_list << join
      end
      if options[:trashed]
        title << " you have filtered"
        join = "JOIN flaggings tings ON tings.claim_id = claims.id AND tings.trash = true AND tings.user_id = #{user_id}"
        join_list << join
      elsif options[:order] != 'trashed'
        cond_list << "claims.id NOT IN (SELECT claim_id FROM flaggings WHERE user_id = #{user_id} AND trash = true)"
      end
      if options[:new_comments]
        title << " with new comments"
        join = "LEFT JOIN looks ON looks.object_type = 'Claim' AND looks.object_id = claims.id AND looks.user_id = #{user_id}"
        cond_list << "(looks.id IS NULL OR claims.commented_at > looks.updated_at)"
        # A casualty of removing the comments join
        #unless ignore_list.empty?
        #  join += " AND comments.user_id NOT IN (#{ignore_list.join(',')})"
        #end
        join_list << join
      end
    end

    if about = options[:about]
      if about.downcase == 'contacts' and logged_in?
        join = "JOIN mentioned_identifiers ON mentioned_identifiers.claim_id = claims.id AND mentioned_identifiers.identifier_id IN (SELECT identifiers.id FROM identifiers JOIN contacts ON contacts.contact_id = identifiers.user_id AND contacts.user_id = #{liuid})"
        join_list << join
        title << " about your contacts"
      else
        vals = options[:about].split(' ').map{|oid| 
          begin
            Identifier.normalize(oid)
          rescue URI::InvalidURIError
            errors << "#{oid} is not a valid OpenID."
            next
          end
        }
        abis = Identifier.find_all_by_value(vals)
        unless abis.empty?
          abi_ids = abis.map{|i|i.id}
          join = "JOIN mentioned_identifiers ON mentioned_identifiers.claim_id = claims.id AND mentioned_identifiers.identifier_id IN (#{abi_ids.join(',')}) "
          join_list << join
          
          title << " about "
          if options[:linked_title]
            title << oxford_comma_list(abis.map{|abi|
              if abi.user_id 
                "<a href=\"#{xprofile_url(abi.value)}\">#{ERB::Util.h(abi.shorten)}</a>"
              else
                "<a href=\"#{abi.value}\" target=\"_blank\">#{ERB::Util.h(abi.shorten)}</a>"          
              end
              }, 'or')

          else
            title << oxford_comma_list(abis.map{|abi| ERB::Util.h(abi.shorten) }, 'or')
          end
        end
      end
    end

    if options[:comments_by]
      if options[:comments_by].downcase == 'contacts' and logged_in?
        join = "JOIN comments bycomments ON bycomments.claim_id = claims.id AND bycomments.user_id IN (SELECT contact_id FROM contacts WHERE user_id = #{liuid})"
        join_list << join
        title << " with comments from your contacts"
      else
        openids = options[:comments_by].split(' ')
        cbyus = User.find_all_lite_by_openid(openids)
        if openids.size < cbyus.size
          errors << "Some of those users could not be found."
        end      
        unless cbyus.empty?
          cbyuids = cbyus.map{|u|u.id}
          join = "JOIN comments bycomments ON bycomments.claim_id = claims.id AND bycomments.user_id IN (#{cbyuids.join(',')})"
          join_list << join
          names = oxford_comma_list(cbyus.map{|u|u.dn}, "or")
          title << " with comments from #{names}"
        end
      end
    end

    if options[:voted_by]
      if options[:voted_by].downcase == 'contacts' and logged_in?
        join = "JOIN claim_votes byvotes ON byvotes.claim_id = claims.id AND byvotes.user_id IN (SELECT contact_id FROM contacts WHERE user_id = #{liuid})"
        join_list << join
        title << " voted on by your contacts"
      else
        openids = options[:voted_by].split(' ')
        vbyus = User.find_all_lite_by_openid(openids)
        if openids.size < vbyus.size
          errors << "Some of those users could not be found."
        end
        unless vbyus.empty?
          vbyuids = vbyus.map{|u|u.id}
          join = "JOIN claim_votes byvotes ON byvotes.claim_id = claims.id AND byvotes.user_id IN (#{vbyuids.join(',')})"
          join_list << join
          names = oxford_comma_list(vbyus.map{|u|u.dn}, "or")
          title << " voted on by #{names}"
        end
      end
    end

    if options[:by]
      if options[:by].downcase == 'contacts' and logged_in?
        cond_list << "claims.user_id IN (SELECT contact_id FROM contacts WHERE user_id = #{liuid})"
        title << " by your contacts"
      else
        openids = options[:by].split(' ')
        byus = User.find_all_lite_by_openid(openids)
        if openids.size < byus.size
          errors << "Some of those users could not be found."
        end
        unless byus.empty?
          byuids = byus.map{|u|u.id}
          cond_list << "claims.user_id IN (#{byuids.join(',')})"
          names = oxford_comma_list(byus.map{|u|u.dn}, "or")
          title << " by #{names}"
        end
      end
    end

    if options[:not_by] 
      if options[:not_by].downcase == 'contacts' and logged_in?
        cond_list << "claims.user_id NOT IN (SELECT contact_id FROM contacts WHERE user_id = #{liuid})"
        title << " not by your contacts"
      else
        openids = options[:not_by].split(' ')
        nbyus = User.find_all_lite_by_openid(openids)
        if openids.size < nbyus.size
          errors << "Some of those users could not be found."
        end
        if defined? byus and byus
          nbyus.reject!{|u|byus.member? u}
        end
        unless nbyus.empty?
          nbyuids = nbyus.map{|u|u.id}
          cond_list << "claims.user_id NOT IN (#{nbyuids.join(',')})"
          names = oxford_comma_list(nbyus.map{|u|u.dn}, "or")
          title << " not by #{names}"
        end
      end
    end

    if user_id
      il = ignore_list
      if il and defined? byuids and byuids
        il.reject!{|i|byuids.member? i}
      end
      if il and not il.empty?
        cond_list << "claims.user_id NOT IN (#{il.join(',')})"
      end
    end

    if logged_in? and options[:interests]
      tag_ids = user.tags.map{|t|t.id}
      join = "JOIN taggings ON taggings.taggable_type = 'Claim' AND taggings.taggable_id = claims.id AND taggings.tag_id IN (#{tag_ids.join(',')})"
      join_list << join
      title << " tagged with your interests"
    elsif options[:tags] or options[:tag]
      t = options[:tags]
      t = options[:tag] + "," unless t
      tagnames = Tag.parse(t).reject{|n|n.empty?}
      tags = Tag.find_all_by_name(tagnames)
      if tagnames.size > tags.size
        errors << "Some of those tags could not be found."
      end
      unless tags.empty?
        tag_ids = tags.map{|t|t.id}
        join = "JOIN taggings ON taggings.taggable_type = 'Claim' AND taggings.taggable_id = claims.id AND taggings.tag_id IN (#{tag_ids.join(',')})"
        join_list << join
        names = oxford_comma_list(tags.map{|t|t.name}, "or")
        title << " tagged with #{names}"
      end

      extras[:tagnames] = tagnames if options[:tagnames]
    end

    if options[:filter_tags]
      tagnames = Tag.parse(options[:filter_tags])
      ftags = Tag.find_all_by_name(tagnames)
      if tagnames.size > ftags.size
        errors << "Some of those tags could not be found."
      end
      if defined? tags and tags
        ftags.reject{|t| tags.member? t}
      end
      unless ftags.empty?
        tag_ids = ftags.map{|t|t.id}
        join = "LEFT JOIN taggings ftaggings ON ftaggings.taggable_type = 'Claim' AND ftaggings.taggable_id = claims.id AND ftaggings.tag_id IN (#{tag_ids.join(',')})"
        join_list << join
        cond_list << "ftaggings.id IS NULL"
        names = oxford_comma_list(ftags.map{|t|t.name}, "or")
        title << " not tagged with #{names}"
      end
    end

    min_votes = options[:min_votes].to_i
    if min_votes > 0
      cond_list << "(claims.yeas + claims.nays) > #{min_votes}"
      title << " with more than #{min_votes} votes"
    end

    min_score = options[:min_score].to_f
    if min_score > 0
      min_score /= 8 # the display factor
      st = Cred.score_table_name
      join = "JOIN #{st} scores ON scores.tag_id IS NULL AND scores.user_id = claims.user_id AND scores.value > #{min_score}"
      join_list << join
    end

    if options[:limit]
      lim = options[:limit].to_i
      offset = options[:offset].to_i
      limit_frag = "LIMIT #{offset}, #{lim}"
    else
      limit_frag = ""
    end

    join_frag = join_list.join(" ")
    if cond_list.empty?
      cond_frag = ""
    else
      cond_frag = "WHERE " << cond_list.join(" AND ")
    end
    unless defined? group_frag
      group_frag = ""
    end
    sql = "SELECT DISTINCT claims.* FROM claims #{join_frag} #{cond_frag} #{group_frag} ORDER BY #{order} #{limit_frag}"

    claims = Claim.find_by_sql(sql)

    if options[:count]
      extras[:count] = Claim.count_by_sql("SELECT COUNT(*) FROM (SELECT DISTINCT claims.id FROM claims #{join_frag} #{cond_frag}) foo")
    end

    if options[:title] or options[:linked_title]
      extras[:title] = title
    end

    unless errors.empty?
      flash[:notice] = errors.uniq.join(' ')
    end

    if extras.empty?
      return claims
    else
      return claims, extras
    end
  end

  def clean_search_params(orig_params)
    return {:order => orig_params[:order],
            :voted => orig_params[:voted],
            :new_comments => orig_params[:new_comments],
            :tags => orig_params[:tags],
            :tag => orig_params[:tag],
            :interests => orig_params[:interests],
            :filter_tags => orig_params[:filter_tags],
            :by => orig_params[:by],
            :not_by => orig_params[:not_by],
            :about => orig_params[:about],
            :comments_by => orig_params[:comments_by],
            :voted_by => orig_params[:voted_by],
            :min_votes => orig_params[:min_votes],
            :min_score => orig_params[:min_score],
            :visited => orig_params[:visited],
            :watched => orig_params[:watched],
            :trashed => orig_params[:trashed],
            :group_id => orig_params[:group_id],
           }.reject {|k,v| v.nil? or v.empty?}
  end


  def inspired_claims_xml(claim, options = {})
    if @infinite_recursion_protection.nil?
      @infinite_recursion_protection = [claim.id]
    else
      raise 'loop detected' if @infinite_recursion_protection.member? claim.id
      @infinite_recursion_protection << claim.id
    end
    if options[:root]
      xml = "<root color='#cc8888 ' "
    elsif options[:comment]
      xml = "<node color='#8888cc' "
    else
      xml = "<node color='#88cc88' "
    end
    xml += "text='#{attr_escape(claim.title)}' author='#{attr_escape(claim.user.dn)}' >"

    claim.inspired_claims.each {|c| xml += inspired_claims_xml(c) }
    claim.inspired_claims_from_comments.each {|c| xml += inspired_claims_xml(c, :comment => true) }

    if options[:root]
      xml += "</root>"
    else
      xml += "</node>"
    end

    return xml
  end

  def votes_for_claim(claim, tag_ids)
    max = 10
    yea_vote_users = []
    nay_vote_users = []
    
    @voter_labels = {}

    # add logged in user vote first
    liuvote = nil
    if logged_in?
      liuvote = ClaimVote.find_by_claim_id_and_user_id(@claim.id, liuid.to_i)
      (liuvote.vote ? yea_vote_users : nay_vote_users)  << liu if liuvote
    end
  
    # add claimant vote
    if !logged_in? or claim.user_id != liuid.to_i
      claimant_vote = ClaimVote.find_by_user_id_and_claim_id(claim.user_id,claim.id)
      (claimant_vote.vote ? yea_vote_users : nay_vote_users) << claim.user if claimant_vote
    end
    
    
    mentioned_user_ids = claim.identifiers.select {|i| i.user_id}.map {|i| i.user_id.to_i}
    if mentioned_user_ids.size > 0
      # need votes of mentioned users if they are not the claimant or liu
      needs_vote = mentioned_user_ids.dup
      needs_vote.delete(liuvote.user_id) if liuvote
      needs_vote.delete(claim.user_id)
      
      if needs_vote.size > 0
        ClaimVote.find_by_sql(
           "SELECT claim_votes.* FROM claim_votes
            WHERE claim_votes.claim_id = #{claim.id}
            AND claim_votes.user_id IN (#{needs_vote.join(',')})").each {|v|
              (v.vote ? yea_vote_users : nay_vote_users) << v.user
            }
      end
      
      # add yes votes of contacts on mentioned users
      yea_contact_voters = claim.voters_by_contacts_of_mentioned(
                  :limit => max-yea_vote_users.size,
                  :vote => true,
                  :exclude_ids => yea_vote_users.map {|u|u.id},
                  :mentioned_user_ids => mentioned_user_ids)
      yea_vote_users += yea_contact_voters

      # add no votes of contacts of mentioned users
      nay_contact_voters = claim.voters_by_contacts_of_mentioned(
                  :limit => max-nay_vote_users.size,
                  :vote => false,
                  :exclude_ids => nay_vote_users.map {|u|u.id},
                  :mentioned_user_ids => mentioned_user_ids)
      nay_vote_users += nay_contact_voters

      contact_voter_ids = (yea_contact_voters + nay_contact_voters).map{|u|u.id}
      
      # claimant may not be a contact, but let's add him to this list to get
      # contact info if he is
      contact_voter_ids << claim.user_id
      
      # Build title messagses for contacts
      unless contact_voter_ids.empty?
        mentioned_users = User.find_all_lite(mentioned_user_ids).hash_by(:id)

        Contact.find(:all, :conditions => "contact_id IN (#{contact_voter_ids.join(',')}) AND user_id IN (#{mentioned_user_ids.join(',')})").each {|con|
          unless @voter_labels.has_key? con.contact_id
            @voter_labels[con.contact_id] = "A contact of " 
          else
            @voter_labels[con.contact_id] += "; of " 
          end
          tl = con.tag_list
          tl = " (#{tl})" unless tl.empty?
          @voter_labels[con.contact_id] += "#{mentioned_users[con.user_id].dn} #{tl}"
        }
      end
    end
    
    # add voter label to subjects who voted
    mentioned_user_ids.each {|user_id| @voter_labels[user_id] = 'Subject of claim.'}
    
    # add other yea votes
    if yea_vote_users.size < max
      yea_vote_users += claim.yea_voters(:limit => max-yea_vote_users.size,
                                         :exclude_ids => yea_vote_users.map {|u|u.id},
                                         :tag_ids => tag_ids)
    end
    
    # add other nay votes
    if nay_vote_users.size < max
      nay_vote_users += claim.nay_voters(:limit => max-nay_vote_users.size,
                                         :exclude_ids => nay_vote_users.map {|u|u.id},
                                         :tag_ids => tag_ids)
    end
    
    return [liuvote, yea_vote_users, nay_vote_users]
  end

end
