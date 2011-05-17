class CreateFlaggings < ActiveRecord::Migration
  def self.up
    create_table :flaggings do |t|
      t.column :user_id, :integer
      t.column :claim_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :flaggings
  end
end
