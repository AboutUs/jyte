class AddTimeToResource < ActiveRecord::Migration
  def self.up
    add_column :resources, :time, :datetime
  end

  def self.down
    remove_column :resources, :time
  end
end
