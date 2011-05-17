class GeneralizeVotes < ActiveRecord::Migration
  def self.up
    transaction {
      rename_column :votes, :claim_id, :votable_id
      add_column :votes, :votable_type, :string
      #Vote.find_all.each {|v| v.votable_type = "Claim"; v.save}
      #CommentReview.find_all.each {|cr| Vote.create(:vote => cr.kudos, :user_id => cr.user_id, :votable => cr.comment)}
      drop_table :comment_reviews
    }
  end

  def self.down
    transaction {
      create_table "comment_reviews" do |t|
        t.column "user_id", :integer
        t.column "comment_id", :integer
        t.column "kudos", :boolean
      end
      # not sure if this is a good idea... will the model be around if this is run? XXX
      Vote.find(:all, :conditions => "votable_type = 'Comment'").each {|v|
        #CommentReview.create(:user_id => v.user_id, :kudos => v.vote, :comment_id => v.votable_id)
        v.destroy
      }
      Vote.find(:all, :conditions => "votable_type != 'Claim'").each {|v| v.destroy}
      remove_column :votes, :votable_type
      rename_column :votes, :votable_id
    }
  end
end
