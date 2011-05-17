require 'csv'
class CreateZipcodes < ActiveRecord::Migration
  def self.up
    #create_table :zipcodes do |t|
    #  t.column :code, :string
    #  t.column :city, :string
    #  t.column :state, :string
    #  t.column :latitude, :string
    #  t.column :longitude, :string
    #end
    #zips = CSV::Reader.create(File.open("#{RAILS_ROOT}/lib/zipcode20040810.csv"))
    #zips.shift # skip the column definitions
    #zips.each {|row|
    #  Zipcode.create(:code => row[0], :city => row[1], :state => row[2], :latitude => row[3], :longitude => row[4])
    #}
  end

  def self.down
    #drop_table :zipcodes
  end
end
