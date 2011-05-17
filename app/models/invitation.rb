class Invitation < ActiveRecord::Base
  belongs_to :response, :class_name => 'EmailResponseCode', :foreign_key => :response_id
  belongs_to :sender, :class_name => 'User', :foreign_key => :sender_id
  belongs_to :recipient, :class_name => 'User', :foreign_key => :recipient_id
  belongs_to :group
  belongs_to :claim

  validates_presence_of :sender
  validates_associated :sender, :group, :claim, :recipient, :response

  def validate
    # we have some either/or presence_of constraints
    unless self.response or self.recipient
      errors.add(:recipient, "Needs a recipient - user or email response code")
    end
  
    unless self.group or self.claim
      errors.add(:target, "Needs a group or a claim")
    end
  end
end
