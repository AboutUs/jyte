class CreateOldUsernames < ActiveRecord::Migration
  def self.up
    create_table :old_usernames do |t|
      t.column :user_id, :integer
      t.column :name, :string
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :old_usernames
  end
end
