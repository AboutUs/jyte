class CreateMaxScores < ActiveRecord::Migration
  def self.up
    create_table :max_scores do |t|
      t.column :tag_id, :integer
      t.column :value, :float
    end
  end

  def self.down
    drop_table :max_scores
  end
end
