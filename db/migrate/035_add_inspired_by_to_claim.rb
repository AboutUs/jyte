class AddInspiredByToClaim < ActiveRecord::Migration
  def self.up

    create_table :claimings do |t|
      t.column :claim_id, :integer
      t.column :claimable_id, :integer
      t.column :claimable_type, :string
    end

  end

  def self.down
    drop_table :claimings
  end
end
