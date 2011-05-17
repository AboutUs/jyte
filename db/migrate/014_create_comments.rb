class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      # t.column :name, :string
      t.column :user_id, :integer
      t.column :claim_id, :integer
      t.column :created_at, :datetime
      t.column :body, :text
    end
  end

  def self.down
    drop_table :comments
  end
end
