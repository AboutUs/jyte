class AddSocialClaims < ActiveRecord::Migration
  def self.up
    add_column :claims, :type, :string
    add_column :claims, :object_openid, :string
    add_column :claims, :relationship, :string

    Claim.find(:all).each {|c| c.type = 'Claim'; c.save}
  end

  def self.down
    remove_column :claims, :object_openid
    remove_column :claims, :relationship
  end
end
