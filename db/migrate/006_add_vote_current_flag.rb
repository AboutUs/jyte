class AddVoteCurrentFlag < ActiveRecord::Migration
  def self.up
    add_column :votes, :current, :boolean, :default => true
  end

  def self.down
    remove_column :votes, :current
  end
end
