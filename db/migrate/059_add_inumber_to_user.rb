class AddInumberToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :i_number, :string
  end

  def self.down
    remove_column :users, :i_number
  end
end
