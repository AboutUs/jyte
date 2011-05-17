class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :comments, [:claim_id, :parent_id]
    add_index :claims, :user_id
    add_index :dispatches, :user_id
    add_index :identifiers, :user_id
    add_index :identifiers, :value
    add_index :votables, [:votable_id, :votable_type], :unique => true
    add_index :votes, :votable_id
    add_index :votes, :user_id
    add_index :groups, :user_id
    add_index :groups, :name
    add_index :group_memberships, :identifier_id
    add_index :group_memberships, :group_id
    add_index :group_group_memberships, :group_id
    add_index :group_group_memberships, :included_group_id
    add_index :resourceables, [:resourceable_id, :resourceable_type]
  end

  def self.down
    remove_index :comments, [:claim_id, :parent_id]
    remove_index :claims, :user_id
    remove_index :dispatches, :user_id
    remove_index :identifiers, :user_id
    remove_index :identifiers, :value
    remove_index :votables, [:votable_id, :votable_type]
    remove_index :votes, :votable_id
    remove_index :votes, :user_id
    remove_index :groups, :user_id
    remove_index :groups, :name
    remove_index :group_memberships, :identifier_id
    remove_index :group_memberships, :group_id
    remove_index :group_group_memberships, :group_id
    remove_index :group_group_memberships, :included_group_id
    remove_index :resourceables, [:resourceable_id, :resourceable_type]
  end
end
