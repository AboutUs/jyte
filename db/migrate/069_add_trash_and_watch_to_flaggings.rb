class AddTrashAndWatchToFlaggings < ActiveRecord::Migration
  def self.up
    add_column :flaggings, :trash, :boolean
    add_column :flaggings, :watch, :boolean
  end

  def self.down
    remove_column :flaggings, :trash
    remove_column :flaggings, :watch
  end
end
