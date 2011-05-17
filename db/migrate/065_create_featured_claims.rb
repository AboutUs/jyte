class CreateFeaturedClaims < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction {
      create_table :featured_claims do |t|
        t.column :claim_id, :integer, :null => false
        t.column :created_at, :datetime
      end
      
      add_index :featured_claims, :claim_id
      
      Claim.find(:all,
                 :conditions => ['state = 1 AND (yeas + nays > 24 OR comments_count > 8)'],
                 :order => 'created_at ASC'
                 ).each {|c| FeaturedClaim.create(:claim_id => c.id)}
    }
  end

    
  def self.down
    ActiveRecord::Base.transaction {
      remove_index :featured_claims, :claim_id
      drop_table :featured_claims
    }
  end
end
