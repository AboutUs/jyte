class Twitter
  @@service_name = "twitter"

  def initialize(user)
    params = {}
    if user.is_a?(User)
      params.merge!({:consumer_key => SETTINGS["twitter"]["oauth_key"],
                     :consumer_secret => SETTINGS["twitter"]["oauth_secret"]})
      existing_token = Twitter.authorization_token_for(user)
      if existing_token
        params.merge!({:token => existing_token.token, :secret => existing_token.secret})
      end
      @user = user
    end
    @oauth = TwitterOAuth::Client.new(params)
  end

  def request_token(callback_url)
    @oauth.request_token(:oauth_callback => callback_url)
  end

  def authorize(token, secret, options)
    access_token = @oauth.authorize(token, secret, options)
    @access_token = access_token.token
    @access_secret = access_token.secret
  end

  def authorized?
    @oauth.authorized?
  end

  def friends_of(name)
    @oauth.friends_ids(:screen_name => name)
  end

  def store_access_token
    existing_token = Twitter.authorization_token_for(@user)
    if existing_token
      existing_token.token = @access_token
      existing_token.secret = @access_secret
      existing_token.save!
    else
      AuthorizationToken.create(:user => @user, :service => @@service_name,
                                               :token => @access_token,
                                               :secret => @access_secret)
    end
  end

  def remove_access_token
    existing_token = Twitter.authorization_token_for(@user)
    existing_token.destroy if existing_token
  end

  def self.authorization_token_for(user)
    AuthorizationToken.find_by_service_and_user_id(@@service_name, user.id)
  end
end
