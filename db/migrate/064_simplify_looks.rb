class SimplifyLooks < ActiveRecord::Migration
  def self.up
    add_column :looks, :updated_at, :datetime
    add_index :looks, [:user_id, :object_type, :object_id]   
    (Claim.find(:all) + User.find(:all)).each {|o|
      o.viewers.uniq.each{|u|
        ls = Look.all_by_user_id_and_object_type_and_object_id(u.id, o.class.to_s, o.id, :order => 'created_at')
        unless ls.empty?
          l = ls[0]
          l.updated_at = ls[-1].created_at
          l.save
          ls[1..-1].each{|k|k.destroy}
        end
      }
    }
  end

  def self.down
    remove_column :looks, :updated_at
    remove_index :looks, [:user_id, :object_type, :object_id]   
  end
end
