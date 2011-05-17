class AddGroupIdToCLaim < ActiveRecord::Migration
  def self.up
    add_column :claims, :group_id, :integer, :default => nil
  end

  def self.down
    remove_column :claims, :group_id
  end
end
