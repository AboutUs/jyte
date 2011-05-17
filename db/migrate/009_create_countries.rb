class CreateCountries < ActiveRecord::Migration
  def self.up
    ## Create country table
    #create_table :countries do |t|
    #  t.column :iso, :string, :size => 2
    #  t.column :noun_phrase, :string, :size => 80
    #  t.column :iso3, :string, :size => 3
    #  t.column :numcode, :integer
    #end
  end

  def self.down
    # drop_table :countries
  end
end

