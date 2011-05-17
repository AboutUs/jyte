class AddVoteTimestamp < ActiveRecord::Migration
  def self.up
    add_column :votes, :created_at, :datetime
    Vote.all.each {|v| v.created_at = DateTime.now; v.save}
  end

  def self.down
    remove_column :votes, :created_at
  end
end
