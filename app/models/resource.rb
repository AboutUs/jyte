class Resource < ActiveRecord::Base
  has_many :resourceables

  def add_to(resourceable)
    resourceables.create :resourceable => resourceable
  end

end

