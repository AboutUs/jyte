class RenameIdType < ActiveRecord::Migration
  def self.up
    rename_column :identifiers, :type, :id_type
  end

  def self.down
    rename_column :identifiers, :id_type, :type
  end
end
