class ReviseClaimDesign < ActiveRecord::Migration
  def self.up
    create_table :identifiers do |t|
      t.column :value, :string
      t.column :user_id, :string
      t.column :primary, :boolean
    end
    
    create_table :mentioned_identifiers do |t|
      t.column :claim_id, :integer
      t.column :identifier_id, :integer
      t.column :order, :integer, :default => 0
    end

    rename_column :claims, :owner_id, :user_id
    remove_column :users, :openid

    remove_column :claims, :subject_openid
    remove_column :claims, :object_openid
    remove_column :claims, :relationship
    drop_table :claim_weights
  end

  def self.down
  end
end
