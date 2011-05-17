#Output some interesting stats for each week there is data

first_claim = Claim.first
last_claim = Claim.last
weekend = last_claim.created_at

while weekend > first_claim.created_at
  weekstart = weekend - 7.days

  claims = Claim.count(:conditions => ["created_at >= ? and created_at < ?", weekstart, weekend])
  votes = ClaimVote.count(:conditions => ["created_at >= ? and created_at < ?", weekstart, weekend])
  comments = Comment.count(:conditions => ["created_at >= ? and created_at < ?", weekstart, weekend])
  users = User.count(:conditions => ["created_at >= ? and created_at < ?", weekstart, weekend])

  puts "#{weekstart.strftime("%Y-%m-%d")}, #{users}, #{claims}, #{votes}, #{comments}"
  
  # setup for the next week
  weekend = weekstart
end 
