class AuthorizationToken < ActiveRecord::Base
  belongs_to :user
end
