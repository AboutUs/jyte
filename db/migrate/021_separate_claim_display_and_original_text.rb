class SeparateClaimDisplayAndOriginalText < ActiveRecord::Migration
  def self.up
    rename_column :claims, :title, :original
    add_column :claims, :parsed, :string
    Claim.all.each {|c|
      c.save
    }
  end

  def self.down
    rename_column :claims, :original, :title
    remove_column :claims, :parsed
  end
end
