class CreateClaims < ActiveRecord::Migration
  def self.up
    create_table :claims do |t|
        t.column :owner_id, :integer
        t.column :created_at, :datetime
        t.column :subject_openid, :string
        t.column :title, :string
        t.column :description, :text
    end
  end

  def self.down
    drop_table :claims
  end
end
