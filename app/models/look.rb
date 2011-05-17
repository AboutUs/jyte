class Look < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :user
  validates_associated :object, :user
  validates_presence_of :object_id, :object_type, :user_id
  validates_uniqueness_of :user_id, :scope => [:object_id, :object_type]

end
