class Claiming < ActiveRecord::Base
  belongs_to :claim
  belongs_to :claimable, :polymorphic => true
end
