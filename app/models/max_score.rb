class MaxScore < ActiveRecord::Base
  belongs_to :tag
  validates_uniqueness_of :tag_id
end
