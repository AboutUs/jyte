class AddBodyToClaim < ActiveRecord::Migration
  def self.up
    add_column :claims, :body, :text
  end

  def self.down
    remove_column :claims, :body
  end
end
