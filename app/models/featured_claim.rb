class FeaturedClaim < ActiveRecord::Base
  
  belongs_to :claim
  validates_uniqueness_of :claim_id

  def self.check_claim_hook(claim)
    return if claim.state != 1
    return if FeaturedClaim.find_by_claim_id(claim.id)

    # heurestic for popular claim
    if (claim.yeas+claim.nays) > 15
      FeaturedClaim.create(:claim_id => claim.id)
    end
  end

end
