class CreateUserBlockings < ActiveRecord::Migration
  def self.up
    create_table :user_blockings do |t|
      t.column :user_id, :integer
      t.column :blocked_user_id, :integer
      t.column :created_at, :datetime
    end
    User.find(:all).each {|u|
      il = u.settings[:ignore_list]
      if il
        User.all_by_id(il).each {|bu|
          UserBlocking.create(:user => u, :blocked_user => bu)
        }
      end
    }
  end

  def self.down
    drop_table :user_blockings
  end
end
