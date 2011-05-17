class RssController < ApplicationController
  layout nil

  # XXX Limit to recent stuff? currently we give EVERYTHING

  def claims_about
    if @openid = params[:openid]
      @openid = Identifier.normalize(@openid)
      
      ident = Identifier.find_by_value @openid
      if ident
        @title = "Claims about #{@openid}"
        @claims = ident.claims
      else
        @claims = []
        @title = "No claims about #{@openid}"
      end
    elsif @search = params[:search]
      begin
        @title = "Claims for search '#{@search}'"
        @claims = Claim.find_by_contents(@search)
      rescue
        @title = "Bad search string"
        render :template => 'rss/error'
      end
    else
      @title = "This action needs an 'openid' or a 'search'"
      render :template => 'rss/error'
    end
    @claims = [] if @claims.nil?
    @link = url_for params
    render :template => 'rss/claims'
  end

  def claims_by
    @user = (User.find_by_id(params[:user_id]) or User.find_by_openid(Identifier.normalize(params[:openid])))
    if @user.nil?
      @title = "This action needs a valid 'user_id' or an 'openid' for a jyte user"
      render :template => 'rss/error'
      return
    end
    @claims = @user.claims
    @title = "Claims by #{@user.nickname}(#{@user.openid})"
    @link = url_for params
    render :template => 'rss/claims'
  end

  def comments_on
    @claim = Claim.find_by_id(params[:claim_id])
    if @claim.nil?
      @title = "This action needs a valid 'claim_id'"
      render :template => 'rss/error'
      return
    end
    @comments = @claim.comments
    @title = "Comments on Claim '#{@claim.title}'"
    @link = url_for params
    render :template => 'rss/comments'
  end

  def comments_by
    @user = (User.find_by_id(params[:user_id]) or User.find_by_openid(Identifier.normalize(params[:openid])))
    if @user.nil?
      @title = "This action needs a valid 'user_id' or an 'openid' for a jyte user"
      render :template => 'rss/error'
      return
    end
    @comments = @user.comments
    @title = "Comments by #{@user.nickname}(#{@user.openid})"
    @link = url_for params
    render :template => 'rss/comments'
  end

  def votes_on
    @claim = Claim.find_by_id(params[:claim_id])
    if @claim.nil?
      @title = "This action needs a valid 'claim_id'"
      render :template => 'rss/error'
      return
    end
    if params[:include_old]
      @votes = @claim.all_votes
      @title = "Votes on #{claim.title} including expired ones"
    else
      @votes = @claim.votes
      @title = "Votes on #{claim.title}"
    end
    @link = url_for params
    render :template => 'rss/votes'
  end

  def votes_by
    @user = (User.find_by_id(params[:user_id]) or User.find_by_openid(Identifier.normalize(params[:openid])))
    if @user.nil?
      @title = "This action needs a valid 'user_id' or an 'openid' for a jyte user"
      render :template => 'rss/error'
      return
    end
    if params[:include_old]
      @votes = @user.votes
      @title = "Votes by #{@user.nickname}(#{@user.openid}) including expired ones"
    else
      @votes = @user.current_votes
      @title = "Votes by #{@user.nickname}(#{@user.openid})"
    end
    @link = url_for params
    render :template => 'rss/votes'
  end

  def votes_about
    @user = (User.find_by_id(params[:user_id]) or User.find_by_openid(Identifier.normalize(params[:openid])))
    if @user.nil?
      @title = "This action needs a valid 'user_id' or an 'openid' for a jyte user"
      render :template => 'rss/error'
      return
    end
    @link = url_for params
    render :template => 'rss/votes'
  end

  def dispatches
    # XXX provide users with keys for this feed
    @user = (User.find_by_id(params[:user_id]) or User.find_by_openid(Identifier.normalize(params[:openid])))
    if @user.nil?
      @title = "This action needs a valid 'user_id' or an 'openid' for a jyte user"
      render :template => 'rss/error'
      return
    end
    @link = url_for params
    render :template => 'rss/dispatches'
  end

end
