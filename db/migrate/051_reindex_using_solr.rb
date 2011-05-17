class ReindexUsingSolr < ActiveRecord::Migration
  def self.up
    Claim.find(:all).each {|c| c.save!}
    Comment.find(:all).each {|c| c.save!}
    
    # remove ferret index shite
    require 'fileutils'
    FileUtils.rm_rf(Pathname.new(RAILS_ROOT).join('index'))
  end

  def self.down
  end
end
