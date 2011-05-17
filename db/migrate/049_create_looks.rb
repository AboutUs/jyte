class CreateLooks < ActiveRecord::Migration
  def self.up
    create_table :looks do |t|
      t.column :object_id, :integer
      t.column :object_type, :string
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :looks
  end
end
