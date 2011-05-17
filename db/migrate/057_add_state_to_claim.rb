class AddStateToClaim < ActiveRecord::Migration
  def self.up
    add_column :claims, :state, :integer, :default => 0
  end

  def self.down
    remove_column :claims, :state
  end
end
