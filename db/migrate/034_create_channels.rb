class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      # t.column :name, :string
      t.column :name, :string
      t.column :user_id, :integer
      t.column :personal, :boolean
    end
    create_table :channel_entries do |t|
      t.column :channel_id, :integer
      t.column :channelable_id, :integer
      t.column :channelable_type, :string
      t.column :created_at, :datetime
      t.column :priority, :integer, :default => 0
    end
    User.find(:all).each {|u| Channel.create(:user_id => u.id, :personal => true)}
  end

  def self.down
    drop_table :channels
  end
end
