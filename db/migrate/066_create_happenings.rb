class CreateHappenings < ActiveRecord::Migration
  def self.up
    create_table :happenings do |t|
      t.column :created_at, :datetime
      t.column :happenable_id, :integer, :null => false
      t.column :happenable_type, :string, :null => false
    end
  end
  
  def self.down
    drop_table :happenings
  end
end
