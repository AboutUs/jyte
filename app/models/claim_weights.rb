class ClaimWeights < ActiveRecord::Base

  belongs_to :user, :counter_cache => true
  belongs_to :claim, :counter_cache => true
  
  acts_as_taggable

end
