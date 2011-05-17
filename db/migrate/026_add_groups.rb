class AddGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :image, :string # file column
      t.column :open_membership, :boolean, :default => true
      t.column :public, :boolean, :default => true

      t.column :created_at, :datetime
      t.column :user_id, :integer
    end

    create_table :group_memberships do |t|
      t.column :group_id, :integer
      t.column :identifier_id, :integer
      t.column :moderator, :boolean, :default => false
      t.column :created_at, :datetime
    end
    
    create_table :group_group_memberships do |t|
      t.column :group_id, :integer
      t.column :included_group_id, :integer
      t.column :moderator, :boolean, :default => false
      t.column :created_at, :datetime
    end
    
  end

  def self.down
  end
end
