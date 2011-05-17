class AddClaimTextHash < ActiveRecord::Migration
  def self.up
    add_column :claims, :digest, :string
    add_index :claims, :digest
    Claim.find(:all).each {|c|
      c.save
    }
  end

  def self.down
    remove_column :claims, :digest
  end
end
