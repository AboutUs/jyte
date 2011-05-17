class UserIpLogging < ActiveRecord::Migration
  def self.up
    add_column :users, :created_ip, :string
    add_column :users, :last_login_ip, :string
    add_column :users, :state, :integer, :null => false

    ActiveRecord::Base.transaction {
      User.find(:all).each { |u|
        u.set_state(:early_adopter)
        u.save!
      }
    }
  end

  def self.down
    remove_column :users, :created_ip
    remove_column :users, :last_login_ip
    remove_column :users, :state
  end
end
