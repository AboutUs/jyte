class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column :suffix, :string, :null => false
      t.column :host_num, :integer, :null => false
      t.column :day, :integer, :null => false
    end

    create_table :imagings do |t|
      t.column :image_id, :integer, :null => false
      t.column :imagable_id, :integer, :null => false
      t.column :imagable_type, :string, :null => false
    end

    # remove all the old image stuff
    remove_column :users, :image
    remove_column :groups, :image
    remove_column :resources, :image

    # cruft
    remove_column :users, :claim_weights_count
  end

  def self.down
    drop_table :images
    drop_table :imagings
  end
end
