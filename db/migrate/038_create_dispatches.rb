class CreateDispatches < ActiveRecord::Migration
  def self.up
    create_table :dispatches do |t|
      t.column :user_id, :integer
      t.column :dispatchable_id, :integer
      t.column :dispatchable_type, :string
      t.column :sender_id, :integer
      t.column :reason, :string
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :dispatches
  end
end
