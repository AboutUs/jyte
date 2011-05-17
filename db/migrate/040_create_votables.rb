class CreateVotables < ActiveRecord::Migration
  def self.up
    create_table :votables do |t|
      t.column :votable_id, :integer
      t.column :votable_type, :string
      t.column :up_votes, :integer
      t.column :down_votes, :integer
    end
    Claim.all.each {|c| 
      votable = Votable.create(:votable => c)
      c.votes.each {|vote|
        vote.votable = votable
        vote.save
      }
      votable.save # run the tabulation again now that the votes have the attribute set
    }
    Comment.all.each {|c| 
      votable = Votable.create(:votable => c)
      c.votes.each {|vote|
        vote.votable = votable
        vote.save
      }
      votable.save # run the tabulation again now that the votes have the attribute set
    }
    remove_column :claims, :yeas
    remove_column :claims, :nays
    remove_column :votes, :votable_type
  end

  def self.down
    add_column :claims, :yeas, :integer
    add_column :claims, :nays, :integer
    add_column :votes, :votable_type, :string
    Vote.all.each {|v| v.votable = v.votable.votable}
    drop_table :votables
    Claim.all.each {|c| c.save} # assuming vote tabulation is in validation
  end
end
