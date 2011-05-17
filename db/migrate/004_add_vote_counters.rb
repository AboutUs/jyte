class AddVoteCounters < ActiveRecord::Migration
  def self.up
    add_column :claims, :yeas, :integer, :default => 0
    add_column :claims, :nays, :integer, :default => 0
    Claim.find(:all).each { |c|
      c.yeas = Vote.count(:conditions => "claim_id = #{c.id} AND vote = TRUE")
      c.nays = Vote.count(:conditions => "claim_id = #{c.id} AND vote = FALSE")
      }
  end

  def self.down
    remove_column :claims, :yeas
    remove_column :claims, :nays
  end
end
