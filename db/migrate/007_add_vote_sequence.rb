class AddVoteSequence < ActiveRecord::Migration
  def self.up
    add_column :votes, :seq, :integer
    Vote.all.each {|v| v.seq = 1; v.save} # close enough
  end

  def self.down
    remove_column :votes, :seq
  end
end
