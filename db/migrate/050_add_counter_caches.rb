class AddCounterCaches < ActiveRecord::Migration
  def self.up
    add_column :votables, :votes_count, :integer, :default => 0
    add_column :claims, :comments_count, :integer, :default => 0

    Claim.find(:all).each {|c|
      c.comments_count = c.comments.length
      c.save!
    }
    
    Votable.find(:all).each {|v|
      v.votes_count = v.votes.length
      v.save!
    }

    # remove cruft
    remove_column :claims, :claim_weights_count
    remove_column :claims, :type
    remove_column :claims, :description
  end

  def self.down
    remove_column :votables, :votes_count
    remove_column :claims, :comments_count
  end
end
