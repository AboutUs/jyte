class WidgetController < ApplicationController

  layout nil

  def claim
    @claim = Claim.find_by_urlslug(params[:urlslug])
    if @claim.nil?
      render :text => 'Unknown claim'
      return
    end
  end
  
  include UserHelper
  include ActionView::Helpers::JavaScriptHelper
  def user_badge
    @user = User.find_by_openid(params[:openid])
    if @user
      @stuff = user_api_info(@user)
    else
      @stuff = {}
    end

    @badge_html = render_to_string(:template => 'widget/user_badge_html')
    @badge_html = escape_javascript(@badge_html)

    headers['Content-Type'] = 'text/javascript'
    render :text => "document.writeln('#{@badge_html}');"
    return
  end

  def tagclaimroll
    @rolltype = 'tag'
    t = params[:tags]
    if t.nil? or t.length == 0
      tags = []
      tagnames = []
    else
      tagnames = Tag.parse(t)
      tags = Tag.find_all_by_name(tagnames)      
    end

    @tagnames = tagnames.join(', ')

    if tags.length > 0
      count = [[1,params.fetch(:count, 5).to_i].max,25].min
      tag_ids = tags.map {|t|t.id}
      if params[:set] == 'all'
        @claims = Claim.find_by_sql(["SELECT claims.* FROM claims JOIN taggings ON taggings.taggable_type = 'Claim' AND taggings.taggable_id = claims.id AND taggings.tag_id in (#{tag_ids.join(',')}) GROUP BY claims.id HAVING COUNT(taggings.id) = #{tag_ids.size} ORDER BY claims.created_at DESC LIMIT ?",count])
      else
        @claims = Claim.find_by_sql(["SELECT claims.* FROM claims JOIN taggings ON taggings.taggable_type = 'Claim' AND taggings.taggable_id = claims.id AND taggings.tag_id IN (#{tag_ids.join(', ')}) WHERE claims.state = 1 ORDER BY claims.created_at DESC LIMIT ?", count])

      end
      @title = "Recent claims tagged #{params[:tags]}"
      batch_load_claim_data(@claims.collect {|c| c.id})
    else
      @claims = []
      @title = "No claims found"
    end

    widget_html = render_to_string(:template => 'widget/claim_roll')
    
    if params[:preview] == 'y'
      render :text => widget_html
    else
      escaped_widget_html = escape_javascript(widget_html)
      headers['Content-Type'] = 'text/javascript'
      render :text => "document.writeln('#{escaped_widget_html}');"
    end
  end

  def claimroll
    @rolltype = 'user'
    @user = User.find_by_openid(params[:openid])    
   
    # ensures a min of 1, max of 25, with a no-value of 5
    count = [[1,params.fetch(:count, 5).to_i].max,25].min

    case params[:type]
    when 'by'
      @claims = Claim.find(:all,
                           :limit => count,
                           :conditions => ['state = 1 AND user_id = ?',@user.id],
                           :order => 'created_at DESC')
      
      @title = "Claims by #{@user.dn}"
                       
    when 'about'
      @claims = Claim.find_by_sql(["SELECT claims.* FROM claims JOIN mentioned_identifiers ON (claims.id = mentioned_identifiers.claim_id AND mentioned_identifiers.identifier_id = ?) WHERE claims.state = 1 ORDER BY claims.created_at DESC LIMIT ?",@user.identifier.id, count])
      batch_load_claim_data(@claims.collect {|c| c.id})
      @title = "Claims about #{@user.dn}"

    when 'voted'
      @claims = Claim.find(:all,
                           :limit => count,
                           :conditions => ['claims.state = 1'],
                           :joins => ["JOIN claim_votes byvotes ON byvotes.claim_id = claims.id AND byvotes.user_id = #{@user.id}"],
                           :order => 'byvotes.created_at DESC',
                           :include => :identifiers)
      @title = "Claims recently voted on by #{@user.dn}"

    when 'watched'
      @claims = Claim.find(:all,
                           :limit => count,
                           :conditions => ['claims.state = 1'],
                           :joins => ["JOIN flaggings on flaggings.claim_id = claims.id AND flaggings.watch = true AND flaggings.user_id = #{@user.id}"],
                           :order => 'flaggings.created_at DESC',
                           :include => :identifiers)
      @title = "Claims #{@user.dn} is watching"

    when 'commented'
      @claims = Claim.find(:all,
                           :limit => count,
                           :conditions => ['claims.state = 1'],
                           :joins => ["JOIN comments bycomments ON bycomments.claim_id = claims.id AND bycomments.user_id = #{@user.id}"],
                           :order => 'bycomments.created_at DESC',
                           :include => :identifiers)

      @title = "Claims recently commented on by #{@user.dn}"
    else
      @claims = []
      @title = "Jyte error"
    end

    unless params[:no_show_vote]
      @votes = ClaimVote.find_all_votes_hash(@user.id,@claims.map{|c|c.id})
    else
      @votes = {}
    end

    widget_html = render_to_string(:template => 'widget/claim_roll')

    if params[:preview] == 'y'
      render :text => widget_html
    else
      escaped_widget_html = escape_javascript(widget_html)
      headers['Content-Type'] = 'text/javascript'
      render :text => "document.writeln('#{escaped_widget_html}');"
    end

  end

end
