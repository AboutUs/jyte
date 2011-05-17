class OauthController < ApplicationController
  before_filter :check_logged_in

  def gmail_start
    gmail = GMail.new(liu)
    callback = url_for(:controller => :oauth, :action => :gmail_authorization)
    request_token = gmail.request_token(callback)
    session[:gmail_request_token] = request_token.token
    session[:gmail_request_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def gmail_authorization
    gmail = GMail.new(liu)
    gmail.authorize(
      session[:gmail_request_token],
      session[:gmail_request_secret],
      {:oauth_verifier => params[:oauth_verifier]})
    gmail.store_access_token
    flash[:notice] = "GMail authorization stored."
    redirect_to :controller => :contacts, :action => :compare_gmail
  end

  def gmail_deauthorize
    gmail = GMail.new(liu)
    gmail.remove_access_token
    flash[:notice] = "GMail authorization forgotten."
    redirect_to :controller => :contacts, :action => :compare
  end

  def twitter_start
    twitter = Twitter.new(liu)
    callback = url_for(:controller => :oauth, :action => :twitter_authorization)
    request_token = twitter.request_token(callback)
    session[:twitter_request_token] = request_token.token
    session[:twitter_request_secret] = request_token.secret
    redirect_to request_token.authorize_url.sub('authorize', 'authenticate')
  end

  def twitter_authorization
    twitter = Twitter.new(liu)
    twitter.authorize(
      session[:twitter_request_token],
      session[:twitter_request_secret],
      :oauth_verifier => params[:oauth_verifier])
    twitter.store_access_token
    flash[:notice] = "Twitter authorization stored."
    redirect_to :controller => :contacts, :action => :compare
  end

  def twitter_deauthorize
    twitter = Twitter.new(liu)
    twitter.remove_access_token
    flash[:notice] = "Twitter authorization forgotten."
    redirect_to :controller => :contacts, :action => :compare
  end

end
