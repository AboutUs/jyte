require 'active_record/acts/tree'

ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Tree }

