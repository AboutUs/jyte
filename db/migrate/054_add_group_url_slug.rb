class AddGroupUrlSlug < ActiveRecord::Migration
  def self.up
    add_column :groups, :urlslug, :string, :null => false
    add_index :groups, :urlslug
  end

  def self.down
  end
end
