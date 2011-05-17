class AddUpdatedAtColumnToSesssions < ActiveRecord::Migration
  def self.up
    add_column :sessions, :updated_at, :datetime
    Session.find(:all).each {|s|
      s.save
    }
  end

  def self.down
    remove_column :sessions, :updated_at
  end
end
