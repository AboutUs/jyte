class DearStrongbad < ActionMailer::Base
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper

  def invite(invitation, response_url)
    recipient = invitation.response.email
    inviter = invitation.sender

    inviter_names = [inviter.openid]
    inviter_names.insert 0, inviter.nickname unless (inviter.nickname.nil? or inviter.nickname.empty?)
    inviter_names.insert -1, inviter.email unless inviter.email.nil?

    recipients    recipient
    from          'Jyte <invites@jyte.com>'
    subject       "#{inviter_names[0]} invites you to Jyte!"

    body          :invitation => invitation, :response_url => response_url, :inviter_names => inviter_names
  end

  # we got this sreg claim that <openid> owns this email address. is this true?
  def confirm(user, email, response_url)
    recipients    email
    from          'Jyte <confirmations@jyte.com>'
    subject       "Confirm your email address on Jyte, #{user.nickname}"
    body          :user => user, :response_url => response_url
  end

  # X new claims have been made about you or people in your network since you last logged in!
  def notify(user)
    recipients    user.email
    from          'Jyte <notifications@jyte.com>'

    conditions = user.network.collect {|i| "identifier_id = #{i.id}"}.join(' OR ')

    @network_claims = Claim.find_by_sql("SELECT * from claims WHERE created_at > #{user.last_seen_at_before_typecast} AND id IN (SELECT claim_id FROM mentioned_identifiers WHERE (#{conditions}))")

    conditions = user.identifiers.collect {|i| "identifier_id = #{i.id}"}.join(' OR ')

    @user_claims = Claim.find_by_sql("SELECT * from claims WHERE created_at > #{user.last_seen_at_before_typecast} AND id IN (SELECT claim_id FROM mentioned_identifiers WHERE (#{conditions}))")

    if @user_claims.length > 0
      if @user_claims.length > 1
        foo = 'claims have'
      else
        foo = 'claim has'
      end
      subject "#{@user_claims.length} new #{foo} been made about you on Jyte" 
    elsif @network_claims.length > 0
      if @network_claims.length > 1
        foo = 'claims have'
      else
        foo = 'claim has'
      end
      subject "#{@network_claims.length} new #{foo} been made about people you know on Jyte"
    else
      return false
    end
    body :user_claims => @user_claims, :network_claims => @network_claims, :user => user
    return true
  end

end
