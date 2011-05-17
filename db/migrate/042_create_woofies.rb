class CreateWoofies < ActiveRecord::Migration
  def self.up
    create_table :woofies do |t|
      t.column :source_id, :integer # user
      t.column :sink_id, :integer # user
      t.column :created_at, :datetime
    end

    create_table :woofie1_scores do |t|
      t.column :user_id, :integer
      t.column :tag_id, :integer, :default => nil
      t.column :rank, :float
    end

    create_table :woofie2_scores do |t|
      t.column :user_id, :integer
      t.column :tag_id, :integer, :default => nil
      t.column :rank, :float
    end
    
    User.find(:all).each { |u|
      u.init_woofie
    }
    OpenIdSetting.create(:setting => 'cur_rank_col', :value => '1') 
  end
  
  def self.down
    drop_table :woofies
    drop_table :woofie1_scores
    drop_table :woofie2_scores
  end

end
