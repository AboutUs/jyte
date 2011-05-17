class Dispatch < ActiveRecord::Base
  belongs_to :user
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_id'
  belongs_to :dispatchable, :polymorphic => true

  validates_presence_of :user_id
  validates_associated :user, :sender, :dispatchable
  validates_uniqueness_of :dispatchable_id, :scope => [:user_id, :dispatchable_type, :reason]
end

