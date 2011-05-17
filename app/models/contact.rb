class Contact < ActiveRecord::Base
  belongs_to :contacter, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :contact, :class_name => 'User', :foreign_key => 'contact_id'

  acts_as_taggable

  validates_uniqueness_of :contact_id, :scope => [:user_id]
  validates_presence_of :contact_id, :user_id

  def validate_on_create
    cuser = User.find_by_id(self.contact_id)

    # contact must be a valid user
    if cuser.nil?
      errors.add(:invalid_user, 'That user does not exist.')
      
      # cannot be your own contact
    elsif self.user_id == self.contact_id
      errors.add(:same_user, 'Cannot be your own contact.')
    end
  end
  
end

