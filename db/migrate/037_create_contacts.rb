class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :user_id, :integer, :null => false
      t.column :contact_id, :integer, :null => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :contacts
  end
end
