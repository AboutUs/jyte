# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  local_addresses.clear

  include ApplicationHelper
  layout 'jyte'

  before_filter :check_user_state

  #session :session_key => '_session_id'
  #session :off, :if => proc {|req|
  #  (req.cookies['_session_id'].empty?)
  #}

  private


  #===| FILTERS |===#
  def check_user_state
    if logged_in? and (liu.suspended? or liu.deleted?)
      session[:user_id] = nil
      cookies.delete(:openid)
      redirect_to front_url
      return false
    end
    return true
  end


  def check_logged_in
    if logged_in?

      # updating :last is a round about way of getting the
      # session to re-save itself every week.  Ugh.
      last = session[:last]
      if last.nil? or last < 1.week.ago
        session[:last] = Time.now
      end

      return true
    end

    if request.query_string.nil? or request.query_string.empty?
      dest = request.path 
    else
      dest = request.path + '?' + request.query_string
    end

    if cookies[:openid]
      redirect_to :controller => 'auth', :action => 'login', :dest => dest
    else
      redirect_to :controller => 'auth', :action => 'signup', :dest => dest
    end

    return false
  end

  def auto_login # try openid immediate mode
    if not logged_in? and cookies[:openid] and not session[:tried_immediate]
      dest = request.path + '?' + request.query_string
      redirect_to :controller => 'auth', :action => 'openid_start', :openid_identifier => cookies[:openid], :immediate => true, :dest => dest
      return false
    else
      return true
    end
  end

  def update_user_last_seen
    unless logged_in_user_id.nil?
      u = liu
      u.last_seen_at = DateTime.now
      u.save
    end
  end
  
  # Does the argument look like an email address?
  def is_email_address?(email_address)
    return false unless email_address
    if email_address.match /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      return true
    end
    return false
  end
  
  ##### Invite stuff ######
  # Send an invite to an email address. you must pass in an Invitation object
  # to this method, it will be saved within or destroyed if something bad
  # happens.
  #
  # Use dispatches to invite someone to a group.
  def send_invite(inv, email)
    unless is_email_address?(email)
      return false, 'Could not send invite.  Try using their email address.'
    end

    # find or create a new email response code
    if erc = EmailResponseCode.find_by_email(email)
      inv.response = erc
      inv.save
      if inv.valid?
        return true, 'User invited'
      else
        raise ArguemntError, 'Bad Invitation'
      end
    else
      # haven't sent an email yet.
      erc = EmailResponseCode.create(:email => email)
      inv.response = erc
      inv.save

      if inv.valid?
        resp_url = url_for(:controller => 'auth',
                           :action => 'invite_response',
                           :code => erc.code,
                           :only_path => false)
        DearStrongbad.deliver_invite(inv, resp_url)
        return true, 'Invite sent to ' + ERB::Util.h(email)
      else
        erc.destroy
        return false, 'Invite failed'
      end
    end
    
    raise ArgumentError, 'should not get here'
  end
  
  # limit is 3 megs
  def read_blob(file, limit=3145728)
    return nil if file.nil?
    return nil unless file.respond_to?('read')

    blob = file.read(limit)
    
    if file.read(1)
      return nil
    end
    
    return blob
  end

  def session_id_salt
    'dsnvndfsver26237nfew3h21b4b2b11b'
  end

  def bad_sig_handler
  end	

  # Batch load all the stuff necessary to render a set of claims by
  # the claim_id.  the ApplicationHelper::render_claim_title uses the instance
  # variables created here.
  def batch_load_claim_data(claim_ids)
    return if claim_ids.empty?
    claim_ids = claim_ids.uniq
    @all_mentioned_identifiers = MentionedIdentifier.find_by_sql("SELECT * FROM mentioned_identifiers WHERE claim_id IN (#{claim_ids.join(',')})")
    @all_identifier_ids = @all_mentioned_identifiers.collect {|mi|mi.identifier_id}.uniq
    
    if @all_identifier_ids.length > 0
      @all_identifiers = Identifier.find_by_sql("SELECT * FROM identifiers WHERE id IN (#{@all_identifier_ids.join(',')})")
    else
      @all_identifiers = []
    end

    @all_user_ids = @all_identifiers.collect {|i| i.user_id}.uniq
    @all_user_ids.reject! {|uid| uid == nil}
    
    if @all_user_ids.length > 0
      @all_users = User.find_by_sql("SELECT * FROM users WHERE id IN (#{@all_user_ids.uniq.join(',')})")
    else
      @all_users = []
    end

    @identifiers_by_identifier_id = @all_identifiers.inject({}) {
      |p,e| p[e.id] = e;p}
    
    @users_by_user_id = @all_users.inject({}) {|p,u| p[u.id] = u;p}
    
    @identifiers_by_claim_id = {}    
    claim_ids.each {|claim_id|
      mids = @all_mentioned_identifiers.find_all {|mi| mi.claim_id == claim_id}
      mids.sort! {|mi1,mi2| mi1.order <=> mi2.order}
      @identifiers_by_claim_id[claim_id] = mids.collect {|mi| @identifiers_by_identifier_id[mi.identifier_id]}
    }

    # get image stuff
    @claim_has_image = []
    imagings = Imaging.find_by_sql("SELECT imagable_id FROM imagings WHERE imagable_type = 'Claim' AND imagable_id IN (#{claim_ids.join(',')})")
    imagings.each {|i| @claim_has_image << i.imagable_id }
  end

end
