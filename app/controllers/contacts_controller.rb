class ContactsController < ApplicationController

  before_filter :check_logged_in, :except => [:index,:api_roster,:api_is_member]
  secure_actions :only => [:add_submit,:remove_submit,:edit_submit]

  def index
    @user = User.find_by_id(params[:id])
    unless @user
      flash[:notice] = "No contacts for that user."
      redirect_to front_url
      return
    end
    
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

    @contact_of = Contact.find(:all,
                  :conditions => ["contact_id = ? #{blocked_sql}", @user.id],
                  :include => [:contacter])
  end

  def add
    @user = User.find_by_id(params[:user_id])
    unless @user
      flash[:notice] = 'Cannot find user'
      redirect_to :controller => 'contacts'
      return
    end

    # get all existing tags.  this could be more efficient, but we'll
    # save that for later :)
    @all_tags = []
    Contact.find_all_by_user_id(liuid).each {|c| @all_tags |= c.tags.collect {|t| t.name}}
    @all_tags.sort!
  end

  def add_submit
    user = User.find(params[:user_id])
    c = Contact.find_or_create_by_user_id_and_contact_id(liuid, user.id)
    c.tag_with(params[:contact_tags])

    Dispatch.create(:user_id => user.id, :dispatchable => liu, :reason => " added you as a contact.")

    flash[:notice] = 'Contacts updated.'
    redirect_to xprofile_url(user.s)
  end

  def edit
    @contact = Contact.find_by_user_id_and_contact_id(liuid, params[:user_id])
    unless @contact
      flash[:notice] = "No contact relationship found."
      redirect_to :controller=>'contacts',:action => 'index', :id => liuid
      return
    end
    @user = @contact.contact
    @all_tags = []
    Contact.find_all_by_user_id(liuid).each {|c| @all_tags |= c.tags.collect {|t| t.name}}
    @all_tags.sort!
  end

  def edit_submit
    @contact = Contact.find_by_user_id_and_contact_id(liuid, params[:user_id])
    unless @contact
      flash[:notice] = "No contact relationship found."
    else
      @contact.tag_with(params[:contact_tags])
    end
 
    redirect_to :controller=>'contacts',:action => 'index', :id => liuid
  end

  def remove_submit
    c = Contact.find_by_user_id_and_contact_id(liuid, params[:user_id])
    Dispatch.create(:user_id => params[:user_id], :dispatchable => liu, :reason => " removed you as a contact.")
    if c
      c.destroy
      flash[:notice] = 'Contact removed.'
    end
    redirect_to :action => 'index',:id => liuid
  end

  def api_is_member
    ids = identifiers_for
    return if ids.nil?
    
    c_openid = params[:contact_openid]

    if c_openid and !c_openid.empty?
      contact_openid = Identifier.detect(c_openid)
      if ids.member?(contact_openid)
        render :text => 'true', :status => 200
      else
        render :text => 'false', :status => 200
      end
    else
      render :text => 'error: must specify contact_openid', :status => 400
    end
  end

  def api_roster
    ids = identifiers_for
    return if ids.nil?
    render :text => ids.join("\n"), :status => 200 
  end
  
  def compare
  end

  def compare_gmail
    gmail = GMail.new(liu)
    @contacts = gmail.contacts
    if @contacts.is_a?(Net::HTTPUnauthorized)
      flash[:notice] = "Authorization for your gmail contact list was denied. Please reauthorize."
      redirect_to :action => :compare
    end
    @jyters = User.all(:conditions => {:email => @contacts})
    @missing_jyters = @jyters - liu.contacts
  end

  private
  
  def identifiers_for
    user = User.find_by_openid(params[:openid])
    unless user
      render :text => 'error: unknown user', :status => 400
      return nil
    end

    contacts = Contact.find(:all,
                            :conditions => ['user_id = ?', user.id],
                            :include => [:contact])
    
    tag_name = params[:tag]
    if tag_name and !tag_name.empty?

      if tag = Tag.find_by_name(tag_name)
        # not sure how to do a join w/ this... so this is ugly
        tag_conds = '(' + contacts.collect {|c| c.id}.join(',') + ')'
        taggings = Tagging.find(:all,
                                :conditions => ["taggable_id in #{tag_conds} AND tag_id = ? AND taggable_type = ?",tag.id,'Contact'])
        taggings_ids = taggings.collect {|t| t.taggable_id}
        contacts = contacts.find_all {|c| taggings_ids.member?(c.id)}
      else
        contacts = []
      end
      
    end
    
    ids = []
    if params[:primary] == 'true'
      contacts.each {|c| ids << c.contact.openid}
    else
      contacts.each {|c| ids |= c.contact.identifiers.collect {|i| i.value}}
    end
    return ids
  end

end
