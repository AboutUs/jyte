class AddSettingsToUser < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction {
      add_column :users, :settings, :text
      User.update_all(['settings = ?', {}.to_yaml])
    }
  end



  def self.down
    remove_column :users, :settings
  end
end
