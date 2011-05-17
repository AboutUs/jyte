class CreateAuthorizationTokens < ActiveRecord::Migration
  def self.up
    create_table :authorization_tokens do |t|
      t.integer :user_id
      t.string :service
      t.string :token
      t.string :secret
      t.timestamps
    end
  end

  def self.down
    drop_table :authorization_tokens
  end
end
