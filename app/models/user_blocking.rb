class UserBlocking < ActiveRecord::Base
  belongs_to :user
  belongs_to :blocked_user, :class_name => 'User', :foreign_key => 'blocked_user_id'
  validates_presence_of :user_id, :blocked_user_id
end
