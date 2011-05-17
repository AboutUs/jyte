class Imaging < ActiveRecord::Base
  belongs_to :image
  belongs_to :imagable, :polymorphic => true

  validates_associated :imagable, :image
  validates_presence_of :imagable_id, :imagable_type, :image_id
end
