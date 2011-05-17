class AddUserProfile < ActiveRecord::Migration
  def self.up
    add_column :users, :image, :string
    add_column :users, :description, :text
  end

  def self.down
    remove_column :users, :description
    remove_column :users, :image
  end
end
