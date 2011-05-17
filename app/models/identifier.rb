class Identifier < ActiveRecord::Base
  include ApplicationHelper
  require 'uri'

  belongs_to :user

  has_many :mentioned_identifiers
  has_many :claims, :through => :mentioned_identifiers, :order => 'created_at DESC', :conditions => 'claims.state = 1'

  has_many :group_memberships
  has_many :groups, :through => :group_memberships
  has_many :communities, :through => :group_memberships
  has_many :personal_groups, :through => :group_memberships

  validates_presence_of :value
  validates_associated :user

  # shortcut instead of having to do identifier.value everywhere.
  # XXX: this may have unexpected side effects, i'm not sure.
  #def to_s
  #  value
  #end

  def Identifier.find_like(q)
    like_pattern ='%'+q.gsub(' ','%')+'%'
    ids = Identifier.find_by_sql(["SELECT DISTINCT identifiers.* FROM identifiers LEFT JOIN users ON identifiers.user_id = users.id WHERE (users.nickname LIKE ?) OR (identifiers.value LIKE ?)", like_pattern, like_pattern])
    return ids
  end

  def Identifier.find_sloppy(q)
    begin
      norm = normalize(q)
    rescue URI::InvalidURIError
      return nil
    end
    find_by_value(norm)
  end

  # Does this string look like an identifier?
  # XXX rename this guy? He detects and normalizes.
  def Identifier.detect(s)
    return nil unless s
    # i-name detection: starts with @ or =
    if s.match(/^[@=]./)
      return s

    elsif s.match( /^https?:\/\// ) or
      (s.match(/.+\..+/) and s.match( /\.(ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|glgm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|o|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw|aero|biz|cat|com|coop|info|jobs|mobi|museum|name|net|org|pro|travel|gov|edu|mil|int)(\/.*)?$/ )) or s.match(/[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d(\/.*)?/)
      begin
        return normalize(s)
      rescue URI::InvalidURIError
        return nil
      end
    else
      return nil
    end
  end

  def Identifier.shorten(s)
    if s.match(/^[@=]/)
      return s
    else
      return s.sub(/^http:\/\//, '').sub(/^([^\/]+)\/$/, '\1').sub(/#.*/,'')
    end
  end

  def shorten
    Identifier.shorten(value)
  end

  #XXX these should escape the strings
  def display
    return user.identifier.shorten if user_id
    return shorten
  end
  alias display_url display

  def self.normalize(s)
    return s if s.index(/[=@]/) == 0
    if s.index("://").nil?
      s = 'http://' + s
    end
    OpenID::URINorm.urinorm(s)
  end

end
