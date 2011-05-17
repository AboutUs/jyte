#XXX: move this into environement.rb
require "openid"
require "openid_ar_store"
require 'openid/extensions/sreg'

class AuthController < ApplicationController

  #session :disabled => false, :only => [:openid_start, :invite_response, :rpx_response]
  secure_actions :only => [:logout]
  
  def login
    @openid = cookies[:openid]
    if params[:dest]
      @flash_notice = 'You must sign in to do that.'
    end
  end
  
  def login2
    @openid = cookies[:openid]
    if params[:dest]
      @flash_notice = 'You must sign in to do that.'
    end
  end

  def logout
    # they've logged out, don't try to log them back in w/ immediate mode.
    session[:tried_immediate] = true

    session[:user_id] = nil
    redirect_to :controller => 'site'
  end

  def openid_start
    openid = params[:openid_identifier]
    immediate = params[:immediate]

    if openid.nil? or openid.strip.empty?
      flash[:notice] = 'Please enter your OpenID.'
      redirect_to :action => 'login'
      return
    end

    o_req = nil
    begin
      o_req = consumer.begin(openid)
    rescue OpenID::OpenIDError => e
      RAILS_DEFAULT_LOGGER.info("OpenID '#{openid}' Error: #{e}")
      flash[:notice] = "OpenID Error: #{e}"
      cookies.delete :openid
      redirect_to :action => 'login'
      return
    end
    
    server_url = o_req.endpoint.server_url
    if server_blacklisted?(server_url)
      flash[:notice] = 'Use a different OpenID server.'
      redirect_to :action => 'login'
      return
    end

    dest = params[:dest]
    trust_root = url_for(:controller => 'site', :only_path => false)
    if immediate
      return_to = url_for :action => 'immediate_response', :dest => dest, :only_path => false
    else
      return_to = url_for :action => 'openid_response', :dest => dest, :only_path => false
    end

    # New User Case
    identifier = o_req.endpoint.claimed_id
    unless User.find_by_openid(identifier)
      if immediate # no immediate mode for new users
        session[:tried_immediate] = true
        if params[:dest]
          redirect_to params[:dest]
        else
          redirect_to front_url
        end
        return
      end

      unless server_whitelist_okay(server_url) or botbouncer_okay(identifier)
        redirect_to botbouncer_captcha_url(:return_to => url_for(:only_path => false, :openid_identifier => identifier), :openid => identifier)
        return
      end
      # XXX add policy URL
      sregreq = OpenID::SReg::Request.new
      sregreq.request_fields(['email', 'nickname', 'dob'], true)
      o_req.add_extension(sregreq)
    end

    redirect_to o_req.redirect_url(trust_root, return_to, immediate)
    return
  end

  def immediate_response
    return_to = url_for(:action => 'immediate_response', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}
    o_resp = consumer.complete(parameters, return_to)
    
    case o_resp.status
    when OpenID::Consumer::SUCCESS
      openid = o_resp.display_identifier

      if liuid
        log_info("Logged-in immediate mode: User #{liuid}, OpenID #{openid}")
        redirect_to :controller => 'home'
        return
      end

      user = User.find_by_openid(openid)
      unless user
        log_info("Non-registered immediate mode: OpenID #{openid}")
        render :text => "Error: #{openid} is not registered", :status => 500
        return
      end

      user.last_login_at = DateTime.now
      user.last_login_ip = request.remote_ip
      user.save
      
      session[:user_id] = user.id
      if params[:dest]
        redirect_to params[:dest]
      else
        redirect_to :controller => 'home'
      end
      return

    when OpenID::Consumer::SETUP_NEEDED, OpenID::Consumer::FAILURE, OpenID::Consumer::CANCEL
      session[:tried_immediate] = true
      if params[:dest]
        redirect_to params[:dest]
      else
        redirect_to :action => 'login'
      end
      return

    else

      render :text => "OpenID server returned something strange", :status => 500
      return
    end
      
    raise StandardError, 'should never get here'
  end

  def openid_response
    return_to = url_for(:action => 'openid_response', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}
    o_resp = consumer.complete(parameters, return_to)
    
    case o_resp.status
    when OpenID::Consumer::SUCCESS
      openid = o_resp.display_identifier

      # Try immediate mode next time
      session[:tried_immediate] = nil
      cookies[:openid] = {:value => openid, :expires => Time.now + 500000000}

      # find this identifier, or create it if it doesn't exist
      identifier = Identifier.find_or_create_by_value(openid)

      # if we're already logged in, then we're just claiming
      # another openid.  do it and split.
      if logged_in_user
        if identifier.user_id and User.find_by_id(identifier.user_id)
          if identifier.user_id != liuid
            flash[:notice] = 'Sorry, that OpenID is already attached to an account.'
          end
        else
          identifier.user_id = liuid
          identifier.save
        end
        redirect_to :controller => 'user', :action => 'account'
        return
      end

      # do the inumber dance
      if is_iname?(openid) and \
        o_resp.endpoint.canonical_id and \
        (user = User.find_by_i_number(o_resp.endpoint.canonical_id))
        identifier.user = user
        identifier.save
        session[:user_id] = user.id
        redirect_to :controller => 'claims', :action => 'find'
        return
      end

      user = identifier.user

      # is the new identifier delegated to an existing identifier?
      # if so attach it to the current account and then log in.
      unless user
        s_id = Identifier.find_or_create_by_value(o_resp.endpoint.local_id)
        if s_id and s_id != identifier
          user = s_id.user
          if user
            identifier.user = user
            identifier.save!
            flash[:notice] = "You have successfully added a new OpenID to your account."
          end
        end
      end
      
      # create a new user
      unless user 
        # -= New User =-
        sreg = OpenID::SReg::Response.from_success_response(o_resp)
        user = User.new
        # XXX FIXME: i_number should only be set if it's an iname
        user.i_number = o_resp.endpoint.canonical_id
        user.set_state(:early_adopter)

        identifier.primary = true
        user.last_login_at = DateTime.now
        user.created_ip = request.remote_ip
        user.last_login_ip = request.remote_ip
        user.nickname = sreg ? sreg['fullname'] : nil
        if !user.valid?
          user.nickname = nil
        end
        user.settings = {}
        user.save!
        identifier.user_id = user.id
        identifier.save! 

        if session[:invite_code] # we got here via email invite
          e = EmailResponseCode.find_by_code(session[:invite_code])
          user.email = e.email
          user.save
          
          inv = Invitation.find_by_response_id(e.id, :order => 'created_at')
          if inv.claim_id
            session[:dest] = claim_url :urlslug => inv.claim.urlslug
          else
            session[:dest] = url_for :controller => 'home'
          end

          Invitation.find_all_by_response_id(e.id).each {|inv|
            if inv.group
              inv.recipient = user
              inv.response = nil
              inv.save
            else
              user.dispatch(inv.claim, :reason => 'invite', :from => inv.sender)
              inv.destroy
            end
          }
          
          session[:invite_code] = nil
          e.destroy
          
        else
          # Confirm the email address
          if sreg and email = sreg['email'] 
            user.email = email
            user.save
            #response_code = EmailResponseCode.create(:email => email).code
            #response_url = url_for :controller => 'user', :action => 'confirm_email', :code => response_code
            #begin
            #  DearStrongbad.deliver_confirm(user, email, response_url)
            #rescue
            #  # XXX: handle case where confirm email fails!!!
            #  raise
            #end
          end

        end
        user.claims_about(:limit => 10).each {|c| user.dispatch(c)}
        if params[:dest]
          redirect_to params[:dest]
        else
          flash[:notice] = 'Welcome to Jyte!'
          redirect_to :controller => 'claim', :action => 'find', :order => 'featured'
        end
      else
        # -= Returning User =- 
        user.last_login_at = DateTime.now
        user.last_login_ip = request.remote_ip
        user.save
        if params[:dest]
          redirect_to params[:dest]
        else
          redirect_to :controller => 'claims', :action => 'find'
        end
      end 

      session[:user_id] = user.id
      return

    when OpenID::Consumer::CANCEL
      cookies.delete :openid
      flash[:notice] = 'Login cancelled.'

    when OpenID::Consumer::FAILURE
      if o_resp.identity_url
        flash[:notice] = "Verification of #{o_resp.identity_url} failed: #{o_resp.message}"
      else
        flash[:notice] = "Verification failed: #{o_resp.message}"
      end
    else
      flash[:notice] = 'Unknown response from OpenID server.'
      
    end
    
    redirect_to :action => 'login'
  end

  def rpx_response
    u = URI.parse('https://rpxnow.com/api/v2/auth_info')
    req = Net::HTTP::Post.new(u.path)
    req.set_form_data({'token' => params[:token],
                        'apiKey' => SETTINGS["rpxnow"]["apikey"],
                        'format' => 'json'})

    
    json = http_request(u, req)

    logger.error(json)

    openid = json['profile']['identifier']
    nickname = json['profile']['preferredUsername']
    email = json['profile']['email']
    handle_rpx_response(openid,nickname,email)
  end

  def http_request(uri, req) # for mocking
    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = true
    res = http.request(req)
    JSON.parse(res.body)
  end

  def handle_rpx_response(openid, nickname, email)
      session[:tried_immediate] = nil
      cookies[:openid] = {:value => openid, :expires => Time.now + 500000000}


      if is_iname?(openid)
	
	identifier = Identifier.find_by_value(nickname)
        if identifier and identifier.user
	  user = identifier.user
        else
	  user = User.find_by_i_name(nickname)	
	end	

	unless user
	  identifier = Identifier.find_or_create_by_value(openid)
          if identifier and identifier.user
	    user = identifier.user
          else
	    user = User.find_by_i_name(openid)	
	  end	
	end

      else

        # find this identifier, or create it if it doesn't exist
        identifier = Identifier.find_or_create_by_value(openid)
        user = identifier.user

      end

      # is the new identifier delegated to an existing identifier?
      # if so attach it to the current account and then log in.
      unless user
        s_id = Identifier.find_or_create_by_value(openid)
        if s_id and s_id != identifier
          user = s_id.user
          if user
            identifier.user = user
            identifier.save!
            flash[:notice] = "You have successfully added a new OpenID to your account."
          end
        end
      end
      
      # create a new user
      unless user 
        # -= New User =-
        user = User.new
	if is_iname?(openid)
          user.i_number = openid
	end

        user.set_state(:early_adopter)

        identifier.primary = true
        user.last_login_at = DateTime.now
        user.created_ip = request.remote_ip
        user.last_login_ip = request.remote_ip
        user.nickname = nickname
        if !user.valid?
          user.nickname = nil
        end
        user.settings = {}
        user.save!
        identifier.user_id = user.id
        identifier.save! 

        if session[:invite_code] # we got here via email invite
          e = EmailResponseCode.find_by_code(session[:invite_code])
          user.email = e.email
          user.save
          
          inv = Invitation.find_by_response_id(e.id, :order => 'created_at')
          if inv.claim_id
            session[:dest] = claim_url :urlslug => inv.claim.urlslug
          else
            session[:dest] = url_for :controller => 'home'
          end

          Invitation.find_all_by_response_id(e.id).each {|inv|
            if inv.group
              inv.recipient = user
              inv.response = nil
              inv.save
            else
              user.dispatch(inv.claim, :reason => 'invite', :from => inv.sender)
              inv.destroy
            end
          }
          
          session[:invite_code] = nil
          e.destroy
          
        else
          # Confirm the email address
          if email
            user.email = email
            user.save
            #response_code = EmailResponseCode.create(:email => email).code
            #response_url = url_for :controller => 'user', :action => 'confirm_email', :code => response_code
            #begin
            #  DearStrongbad.deliver_confirm(user, email, response_url)
            #rescue
            #  # XXX: handle case where confirm email fails!!!
            #  raise
            #end
          end

        end
        user.claims_about(:limit => 10).each {|c| user.dispatch(c)}
        if params[:dest]
          redirect_to params[:dest]
        else
          flash[:notice] = 'Welcome to Jyte!'
          redirect_to :controller => 'claim', :action => 'find', :order => 'featured'
        end
      else
        # -= Returning User =- 
        user.last_login_at = DateTime.now
        user.last_login_ip = request.remote_ip
        user.save
        if params[:dest]
          redirect_to params[:dest]
        else
          redirect_to :controller => 'claims', :action => 'find'
        end
      end 

      session[:user_id] = user.id
      return
    
  end

  def xrds
    headers['content-type'] = 'application/xrds+xml'
    xrds = "<?xml version='1.0' encoding='UTF-8'?>
<xrds:XRDS
    xmlns:xrds='xri://$xrds'
    xmlns:openid='http://openid.net/xmlns/1.0'
    xmlns='xri://$xrd*($v*2.0)'>
  <XRD>

    <Service>
      <Type>http://specs.openid.net/auth/2.0/return_to</Type>
      <URI>#{url_for :only_path => false, :controller => 'auth', :action => 'openid_response'}</URI>
      <URI>#{url_for :only_path => false, :controller => 'auth', :action => 'immediate_response'}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
"
  render :text => xrds
  end

  def beta
    if params[:beta_code] == 'jytebyjanrain'
      session[:beta] = true
      if params[:dest]
        redirect_to params[:dest]
      else
        redirect_to :controller => ''
      end
      return
    else
      render :action => 'beta', :layout => false      
    end
  end

  def invite_response
    if logged_in?
      u = liu
      rc = EmailResponseCode.find_by_code(params[:code])
      unless rc.nil?
        u.email = rc.email
        u.save
      end
      redirect_to :controller => 'home'
    else
      # grab the response code and throw it into the session
      session[:invite_code] = params[:code]
      render :template => 'auth/signup'
    end
  end
    

  def crash
    raise 'TheCrash'
  end
    
  private

  def log_info(something)
    RAILS_DEFAULT_LOGGER.info(something)
  end
  
  def consumer
    store = ActiveRecordStore.new
    # fetcher = OpenID::StandardFetcher.new
    # fetcher.ca_path = Pathname.new(RAILS_ROOT).join('cacert.pem').to_s
    return OpenID::Consumer.new(session, store)
  end

  def server_whitelist_okay(server_url)
    whitelist = ["http://www.myopenid.com/server",
                 "https://www.myopenid.com/server",
                 "http://1id.com/sso/",
                ]
    yahoo_re = /^https?:\/\/[\w\.]*(yahoo|yahooapis).[a-z\.]{2,6}\/openid\/op\/auth$/ 
    return whitelist.member?(server_url) || server_url.match(yahoo_re)
  end
  
  def server_blacklisted?(server_url)
    ['http://www.jkg.in/openid'].each {|blacklisted|
      return true if server_url.starts_with?(blacklisted)
    }
    return false
  end
  
  def botbouncer_okay(openid)
    fetcher = OpenID::StandardFetcher.new
    botbouncer = "http://botbouncer.com/api/info"
    url = OpenID::Util.append_args(botbouncer, 'api_key' => SETTINGS["botbouncer"]["apikey"], 'openid' => openid)
    r = nil
    begin
      r = fetcher.fetch(url)
    rescue Timeout::Error
       RAILS_DEFAULT_LOGGER.info("Botbouncer timed out.  Letting #{openid} through. URL: #{url}")
    end
    if r
      furl = r.final_url
      body = r.body
      if body.match "verified:true"
        return true
      elsif
        body.match "verified:false"
        return false
      else
        raise "unexpected response from botbouncer ( #{url} )"
      end
    else
      RAILS_DEFAULT_LOGGER.info("Fetch to botbouncer failed.  Letting #{openid} through. ( #{url} )")
      return true
      # XXX d'oh
    end
  end

  def botbouncer_captcha_url(options)
    botbouncer = "http://botbouncer.com/captcha/queryuser"
    return OpenID::Util.append_args(botbouncer, 'return_to' => options[:return_to], 'openid' => options[:openid])
  end

end
