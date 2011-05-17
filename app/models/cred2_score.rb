class Cred2Score < ActiveRecord::Base
  belongs_to :tag
  belongs_to :user

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:tag_id]

  def self.find_top_scores
    find_by_sql("SELECT user_id, tag_id, MAX(value) AS value FROM #{table_name} GROUP BY tag_id")
  end
end
