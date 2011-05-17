class ReAddContactsRemovePersonalGroups < ActiveRecord::Migration
  def self.up
    #create_table :contacts do |t|
    #  t.column :user_id, :integer, :null => false
    #  t.column :contact_id, :integer, :null => false
    #  t.column :created_at, :datetime
    #end

    remove_column :groups, :type
  end

  def self.down
    add_column :groups, :type
  end
end
