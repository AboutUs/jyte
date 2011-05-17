class AddMoreIndices < ActiveRecord::Migration
  def self.up
    add_index :claims, :created_at
  end

  def self.down
    remove_index :claims, :created_at
  end
end
