require 'uri'
require 'digest/sha1'

module SecureAction

  class BadSignature < Exception; end

  def self.included(base) #:nodoc:
    # override url_for
    base.send(:alias_method, :old_url_for, :url_for)
    base.send(:alias_method, :url_for, :secure_url_for)

    # install the before filter for verifying secure action sigs
    base.send(:before_filter, :verify_sig_filter)

    # add the ActionController level class methods for defining
    # secure actions
    base.extend(ClassMethods)
  end

  # Default paramter key for signature.  You may override this method
  # in ApplicationController if you like.
  def sig_params_key
    :_s
  end

  # See the ArgumentError string for details. You must override this method
  # in app/controllers/application.rb
  def session_id_salt
    raise ArgumentError, "You need to define a private ApplicationController.session_id_salt method in app/controllers/application.rb.\nMethod should return a hard coded secret, plus some additional salt like the User's last login time.\nThe secret should be a big random string that does not change.\nExample:\n\nclass ApplicationController < ActionController::Base\n  private\n  def session_id_salt\n    'bigrandomstring'+User.last_login_at.to_s\n  end\nend"
  end

  # Default bad signature handler. You may override this method in
  # ApplicationController if you like.
  def bad_sig_handler
    raise BadSignature
  end

  # get the name of the cookie used to represent the session id
  def session_id
    session_key = ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] || '_session_id'
    return cookies[session_key]
  end

  # Re-implementation of url_for that extracts the target controller and 
  # action, and adds a signature if necessary.
  def secure_url_for(options, *p)
    if session_id and options.is_a?(Hash)
      
      # find out the target controller and action by building the url
      # and then break it up into it's component parts using the
      # inverse_of_url algorithm.
      url = old_url_for(options, *p)
      path = URI.parse(url).path
      parts = ActionController::Routing::Routes.recognize_path(path)      

      target_controller = parts[:controller]
      target_action = parts[:action]

      # add sig if the target action for the target controller has been
      # defined as secure.
      if target_controller
        tc = "#{target_controller.camelize}Controller".constantize
        if tc.is_action_secure?(target_action)
          options[sig_params_key] = Digest::SHA1.hexdigest(session_id + session_id_salt)
        end
      end
    end
    
    old_url_for(options, *p)
  end

  # Dynamic before_filter that verifies signtures of secure actions
  def verify_sig_filter
    if self.class.is_action_secure?(action_name)
      # actual signature sent
      sig = params[sig_params_key]
      
      # if no sig is present, or the actual sig doesn't match the
      # expected sig, invoke the bad_sig_handler
      if !sig or sig != Digest::SHA1.hexdigest(session_id + session_id_salt)
        bad_sig_handler
        return false
      end
    end
    
    return true
  end

  module ClassMethods
    
    def is_action_secure?(action_name)
      action = action_name.to_sym
      if @only_secure_actions and @only_secure_actions.include?(action)
        return true
      elsif @except_secure_actions and !@except_secure_actions.include?(action)
        return true
      end
      return false
    end

    def secure_actions(options)
      emsg = 'Specify :all or :except|:only => [:action]'
      case options
      when Symbol
        if options == :all
          @except_secure_actions = []
        else
          raise ArgumentError, emsg
        end
      when Hash
        if options[:only]
          @only_secure_actions = options[:only].collect {|a| a.to_sym}
        elsif options[:except]
          @except_secure_actions = options[:except].collect {|a| a.to_sym}
        else
          raise ArgumentError, emsg
        end
      else
        raise ArgumentError, emsg
      end
    end

  end
    
end
