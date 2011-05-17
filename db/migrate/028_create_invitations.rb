class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.column :created_at, :datetime
      t.column :response_id, :integer
      t.column :sender_id, :integer
      t.column :recipient_id, :integer
      t.column :claim_id, :integer
      t.column :group_id, :integer
    end
  end

  def self.down
    drop_table :invitations
  end
end
