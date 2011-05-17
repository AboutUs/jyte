class AddModToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :group_moderator, :boolean, :default => false
    
    # group membership is now User based, not identifier based
    GroupMembership.delete(:all)
    rename_column :group_memberships, :identifier_id, :user_id

    # remove stuff we aren't using.  we can rewrite this later.
    remove_index :group_group_memberships, :group_id
    remove_index :group_group_memberships, :included_group_id
    drop_table :group_group_memberships
  end

  def self.down
    remove_column :invitations, :group_moderator
  end
end
