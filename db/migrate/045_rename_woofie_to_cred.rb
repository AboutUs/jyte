class RenameWoofieToCred < ActiveRecord::Migration
  def self.up
    rename_table :woofies, :creds
    rename_table :woofie1_scores, :cred1_scores
    rename_column :cred1_scores, :rank, :value
    rename_table :woofie2_scores, :cred2_scores
    rename_column :cred2_scores, :rank, :value
  end

  def self.down
    rename_table :creds, :woofies
    rename_column :cred1_scores, :value, :rank
    rename_table :cred1_scores, :woofie1_scores
    rename_column :cred1_scores, :value, :rank
    rename_table :cred2_scores, :woofie2_scores
  end
end
