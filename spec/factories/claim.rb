Factory.define :claim do |c|
  c.original 'Example Claim'
  c.parsed "Example Claim"
  c.state 1
  c.association :user
end

