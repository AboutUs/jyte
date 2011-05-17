class CreateWidgetResource < ActiveRecord::Migration
  def self.up
    add_column :resources, :widget, :text
  end

  def self.down
    remove_column :resources, :widget
  end
end
