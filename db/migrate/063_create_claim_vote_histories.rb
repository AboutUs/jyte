class CreateClaimVoteHistories < ActiveRecord::Migration
  def self.up
    create_table :claim_vote_histories do |t|
      t.column :user_id, :integer
      t.column :claim_id, :integer
      t.column :vote, :boolean
      t.column :created_at, :datetime
    end
    ClaimVote.find(:all).each {|v| 
      ClaimVoteHistory.create(:user_id => v.user_id, :claim_id => v.claim_id, :vote => v.vote, :created_at => v.created_at)
      unless v.current
        v.destroy
      end
    }
    remove_column :claim_votes, :current
  end

  def self.down
    drop_table :claim_vote_histories
  end
end
