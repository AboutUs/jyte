class CreateClaimVotes < ActiveRecord::Migration
  def self.up
    create_table :claim_votes do |t|
      t.column :claim_id, :integer
      t.column :user_id, :integer
      t.column :vote, :boolean
      t.column :created_at, :datetime
      t.column :current, :boolean, :default => true
    end
    add_column :claims, :claim_votes_count, :integer, :default => 0
    add_column :claims, :yeas, :integer, :default => 0
    add_column :claims, :nays, :integer, :default => 0
    Votable.all(:conditions=>{:votable_type => "Claim"}).each {|votable|
      votable.votes.each {|vote|
        ClaimVote.create :claim_id => votable.votable_id, :user_id => vote.user_id, :vote => vote.vote, :current => vote.current
      }
    }
  end

  def self.down
    drop_table :claim_votes
    remove_column :claims, :claim_votes_count
    remove_column :claims, :yeas
    remove_column :claims, :nays
  end
end
