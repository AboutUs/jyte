class Resourceable < ActiveRecord::Base
  belongs_to :resource
  belongs_to :resourceable, :polymorphic => true 

  validates_uniqueness_of :resourceable_id, :scope => [:resource_id]
end
