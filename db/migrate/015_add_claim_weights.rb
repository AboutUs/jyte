class AddClaimWeights < ActiveRecord::Migration
  def self.up
    create_table :claim_weights do |t|
      t.column :user_id, :integer
      t.column :claim_id, :integer
      t.column :created_at, :datetime
      t.column :score, :integer
    end

    add_column :users, :claim_weights_count, :integer
    add_column :claims, :claim_weights_count, :integer

  end

  def self.down
    drop_table :claim_weights
    remove_column :users, :claim_weights_count
    remove_column :claims, :claim_weights_count
  end
end
