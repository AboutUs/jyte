class AddSessionsToDb < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.column :sessid, :string
      t.column :data, :text
    end
    add_index :sessions, :sessid
  end

  def self.down
    drop_table :sessions
  end
end
