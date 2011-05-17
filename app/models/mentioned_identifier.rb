class MentionedIdentifier < ActiveRecord::Base
  belongs_to :claim
  belongs_to :identifier
  validates_presence_of :claim_id, :identifier_id
  validates_associated :claim, :identifier
end
