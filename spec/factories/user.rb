Factory.define :user do |u|
  u.nickname 'testuser'
  u.state 1
  u.identifier {|i| i.association(:identifier, {:value => "http://#{i.nickname}.myopenid.com",
                                                :primary => true}) }
end

