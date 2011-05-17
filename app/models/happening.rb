class Happening < ActiveRecord::Base
  
  belongs_to :happenable, :polymorphic => true
  
  def self.find_all_since(t=0, options = {})
    if options[:show]
      show = options[:show]
      ph_list = '('+show.map{|i|'?'}.join(',')+')'
      return Happening.find(:all,
                            :conditions => ["id > ? AND happenable_type IN #{ph_list}", t]+show,
                            :order => 'id DESC',
                            :limit => 20)
    else
      return Happening.find(:all,
                            :conditions => ['id > ?',t],
                            :order => 'id DESC',
                            :limit => 20)
    end
    
  end
  
end
