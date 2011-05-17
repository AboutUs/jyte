class RenameVoteOwnerToUser < ActiveRecord::Migration
  def self.up
    rename_column :votes, :owner_id, :user_id
  end

  def self.down
    rename_column :votes, :user_id, :owner_id
  end
end
