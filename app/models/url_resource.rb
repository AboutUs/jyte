class UrlResource < Resource

  validates_presence_of :url
  validates_uniqueness_of :url

end
