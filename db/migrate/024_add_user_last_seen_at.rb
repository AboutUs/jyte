class AddUserLastSeenAt < ActiveRecord::Migration
  def self.up
    add_column :users, :last_seen_at, :datetime
    User.all.each {|u|
      u.last_seen_at = u.created_at
      u.save
    }
  end

  def self.down
    remove_column :users, :last_seen_at
  end
end
