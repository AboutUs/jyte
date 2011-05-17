class GeneralizeIdentifier < ActiveRecord::Migration
  def self.up
    add_column :identifiers, :type, :string
  end

  def self.down
    remove_column :identifiers, :type
  end
end
