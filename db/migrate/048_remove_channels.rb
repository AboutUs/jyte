class RemoveChannels < ActiveRecord::Migration
  def self.up
    drop_table :channels
    drop_table :channel_entries

    Group.destroy_all

    rename_column :groups, :open_membership, :invite_only
    remove_column :groups, :public
  end

  def self.down
  end
end
