class EmailResponseCode < ActiveRecord::Base
  has_many :invitations, :foreign_key => 'response_id', :dependent => :destroy
  def before_create
    while self.code.nil? or EmailResponseCode.find_by_code(self.code)
      self.code = rand(2000000000) 
    end
  end
end
