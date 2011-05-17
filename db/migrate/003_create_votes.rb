class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
        t.column :claim_id, :integer
        t.column :owner_id, :integer
        t.column :vote, :bool
        t.column :comment, :text
    end
  end

  def self.down
    drop_table :votes
  end
end
