class GMail
  @@service_name = "gmail"

  def initialize(user)
    @consumer = OAuth::Consumer.new(SETTINGS["gmail"]["oauth_key"], 
                                    SETTINGS["gmail"]["oauth_secret"], 
                                    :site => 'https://www.google.com',
                                    :request_token_path => '/accounts/OAuthGetRequestToken',
                                    :access_token_path => '/accounts/OAuthGetAccessToken',
                                    :authorize_path => '/accounts/OAuthAuthorizeToken')
    if user.is_a?(User)
      existing_token = self.class.authorization_token_for(user)
      if existing_token
        @access_token = OAuth::AccessToken.new(@consumer, existing_token.token, existing_token.secret)
      end
      @user = user
    end
  end

  def request_token(callback_url)
    @consumer.get_request_token({:oauth_callback => callback_url},
                                {:scope => 'http://www.google.com/m8/feeds/'}) 
  end

  def authorize(token, secret, options)
    request_token = OAuth::RequestToken.new(
        @consumer, token, secret)
    @access_token = request_token.get_access_token(options)
  end

  def authorized?
    @consumer.authorized?
  end

  def store_access_token
    existing_token = self.class.authorization_token_for(@user)
    if existing_token
      existing_token.token = @access_token.token
      existing_token.secret = @access_token.secret
      existing_token.save!
    else
      AuthorizationToken.create(:user => @user, :service => @@service_name,
                                                :token => @access_token.token,
                                                :secret => @access_token.secret)
    end
  end

  def remove_access_token
    existing_token = self.class.authorization_token_for(@user)
    existing_token.destroy if existing_token
  end

  def self.authorization_token_for(user)
    AuthorizationToken.find_by_service_and_user_id(@@service_name, user.id)
  end

  # GDATA
  def contacts
    contacts_batch_url = "http://www.google.com/m8/feeds/contacts/default/full?max-results=2000"
    doc = REXML::Document.new(@access_token.get(contacts_batch_url).body)
    REXML::XPath.match(doc, "//entry/gd:email").map{|e| e.attributes["address"]}
  end
end
