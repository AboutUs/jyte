class RemoveIdTypeAndAddEmailToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string
    Identifier.find(:all, :conditions => 'id_type = "email"').each { |i|
      u = i.user
      u.email = i.value
      u.save
      i.destroy
    }
    remove_column :identifiers, :id_type
  end

  def self.down
    add_column :identifiers, :id_type, :string
    User.find(:all, :conditions => 'email IS NOT NULL').each {|u|
      Identifier.create(:value => u.email, :id_type => 'email', :user_id => u.id)
    }
    remove_column :users, :email
  end
end
