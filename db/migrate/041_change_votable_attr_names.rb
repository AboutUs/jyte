class ChangeVotableAttrNames < ActiveRecord::Migration
  def self.up
    rename_column :votables, :up_votes, :up_count
    rename_column :votables, :down_votes, :down_count
  end

  def self.down
    rename_column :votables, :up_count, :up_votes
    rename_column :votables, :down_count, :down_votes
  end
end
