class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :openid, :string

      t.column :created_at, :datetime
      t.column :last_login_at, :datetime
    end
  end

  def self.down
    drop_table :users
  end
end
