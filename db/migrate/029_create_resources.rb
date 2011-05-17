class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.column :type, :string

      # Resource Base
      t.column :name, :string

      # ImageResource
      t.column :image, :string

      # UrlResource
      t.column :url, :string
      
      # LocationResource
      t.column :location, :string
      t.column :lat, :float
      t.column :long, :float
      t.column :zipcode, :string
    end

    create_table :resourceables do |t|
      t.column :resourceable_type, :string
      t.column :resourceable_id, :integer
      t.column :resource_id, :integer
    end

  end

  def self.down
    drop_table :resources
    drop_table :resourceables
  end
end
