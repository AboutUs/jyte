class CreateCommentReviews < ActiveRecord::Migration
  def self.up
    create_table :comment_reviews do |t|
      # t.column :name, :string
      t.column :user_id, :integer
      t.column :comment_id, :integer
      t.column :kudos, :boolean
    end
  end

  def self.down
    drop_table :comment_reviews
  end
end
