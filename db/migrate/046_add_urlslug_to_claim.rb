class AddUrlslugToClaim < ActiveRecord::Migration
  def self.up
    add_column :claims, :urlslug, :string
    Claim.find(:all).each {|c|
      people = c.identifiers.collect {|i|
        if i.user_id
          i.user.identifier.value.sub(/^http:\/\//, '').sub(/^([^\/]+)\/$/, '\1')
        else
          i.value.sub(/^http:\/\//, '').sub(/^([^\/]+)\/$/, '\1')
        end
      }
      text = c.parsed % people
      c.urlslug = text.gsub(" ", "-").gsub(/[^-.\w]/,'').downcase
      c.save
    }
  end

  def self.down
    remove_column :claims, :urlslug
  end
end
