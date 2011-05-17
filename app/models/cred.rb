class Cred < ActiveRecord::Base
  acts_as_taggable

  belongs_to :source, :class_name => 'User', :foreign_key => 'source_id'
  belongs_to :sink, :class_name => 'User', :foreign_key => 'sink_id'

  validates_presence_of :source_id, :sink_id
  validates_uniqueness_of :sink_id, :scope => :source_id

  def validate
    if source_id == sink_id
      errors.add(:text, "Cannot give yourself cred.")
    end
  end

  def self.score_table_setting
    setting = OpenIdSetting.find_by_setting('cur_score_table')
    if setting.nil? # XXX Is this the right place to be initializing this?
      setting = OpenIdSetting.create(:setting => 'cur_score_table', :value => 1)
    end
    return setting.value
  end

  def self.swap_score_tables
    t = OpenIdSetting.find_by_setting('cur_score_table')
    if t.value == '1'
      t.value = '2'
    else
      t.value = '1'
    end
    t.save
  end

  # return the class of the current score table for reading
  def self.score_class
    return score_table_setting == '1' ? Cred1Score : Cred2Score    
  end

  # class of writable score table
  def self.write_score_class
    return score_table_setting == '1' ? Cred2Score : Cred1Score    
  end

  def self.score_table_name
    return score_table_setting == '1' ? 'cred1_scores' : 'cred2_scores'
  end

  # options:
  # :tag_id, :tag, or :tag_name for tagged score.  defaults to overall score
  # :normalized => true - normalize score
  def self.score(options = {})
    user_id = find_user_id(options)
    tag_id = find_tag_id(options)

    score = score_class.find_by_user_id_and_tag_id(user_id, tag_id)
    if score
      if options[:normalized]
        ms = MaxScore.find_by_tag_id(tag_id)
        score.value / ms.value
      else
        score.value
      end
    else
      if score_class.find_by_user_id_and_tag_id(user_id, nil)
        return 0.0
      else
        return nil
      end
    end
  end

  def self.scores_for_users(user_ids, options = {})
    tag_id = find_tag_id(options)
    scores = score_class.find_all_by_user_id_and_tag_id(user_ids, tag_id)
    scorehash = {}
    if options[:normalized]
      ms = MaxScore.find_by_tag_id(tag_id)
      scores.each{|s| scorehash[s.user_id] = s.value/ms.value }
    else
      scores.each{|s| scorehash[s.user_id] = s.value }
    end
    return scorehash
  end
  
  def self.scores_by_tag_and_user(tag_ids, user_ids, options = {})
    user_id_frag = '('+user_ids.join(',')+')'
    scores = {}
    if tag_ids.empty?
      tag_id_frag = 'tag_id IS NULL'
    else
      tag_id_frag = 'tag_id IN ('+tag_ids.join(',')+') OR tag_id IS NULL'
    end
    sql = "SELECT * FROM #{score_table_name} scores WHERE user_id IN #{user_id_frag} AND (#{tag_id_frag})"
    tag_ids.each {|i| scores[i] = {}}
    scores[nil] = {}
    if options[:normalized]
      maxes = {}
      MaxScore.find_by_sql("SELECT * FROM max_scores WHERE #{tag_id_frag}").each {|m| maxes[m.tag_id] = m.value}
    end
    connection.select_all(sql).each{|r|
      val = r['value'].to_f
      tag_id = r['tag_id']
      tag_id = tag_id.to_i if tag_id
      user_id = r['user_id'].to_i
      if options[:normalized]
        val /= maxes[tag_id]
      end
      scores[tag_id][user_id] = val
    }
    # score 0 instead of nil for users with scores
    scores[nil].keys.each{|uid|
      tag_ids.each{|tid|
        unless scores[tid][uid]
          scores[tid][uid] = 0.0
        end
      }
    }
    return scores
  end

  def self.scores(options)
    user_id = find_user_id(options)
    if user_id.nil?
      raise ArgumentError, 'need to pass in a user_id'
    end

    if (lim = options[:limit].to_i) > 0
      lim_frag = "LIMIT #{lim}"
    else
      lim_frag = ""
    end

    st = score_table_name

    # overall cred
    if options[:normalized]
      sql = "SELECT (scores.value/max_scores.value) FROM #{st} scores
                    JOIN max_scores ON max_scores.tag_id IS NULL
                     AND scores.tag_id IS NULL
                     AND scores.user_id = #{user_id}"
    else
      sql = "SELECT scores.value FROM #{st} scores
                   WHERE scores.tag_id IS NULL
                     AND scores.user_id = #{user_id}"
    end
    overall_score = connection.select_value(sql).to_f

    # tagged cred
    if options[:normalized]
      sql = "SELECT scores.tag_id tag_id, (scores.value/max_scores.value) value FROM #{st} scores
                    JOIN max_scores ON max_scores.tag_id = scores.tag_id
                     AND scores.tag_id IS NOT NULL
                     AND scores.user_id = #{user_id}
              ORDER BY scores.value DESC #{lim_frag}"
    else
      sql = "SELECT scores.tag_id tag_id, scores.value value FROM #{st} scores
                    WHERE scores.user_id = #{user_id}
                     AND scores.tag_id IS NOT NULL
              ORDER BY scores.value DESC #{lim_frag}"
    end

    scores_by_tag_id = {}
    connection.select_all(sql).each {|r|
      scores_by_tag_id[r['tag_id'].to_i] = r['value'].to_f
    }

    return overall_score, scores_by_tag_id
  end
    
  def self.initialize_write_score_table
    ActiveRecord::Base.transaction {
      # We have one table live for reading, and one table for recalculation
      # determine which table we are reading and writing from/to
      conn = ActiveRecord::Base.connection
      if score_table_setting == '1'
        conn.drop_table :cred2_scores
        conn.create_table :cred2_scores do |t|
          t.column :user_id, :integer
          t.column :tag_id, :integer, :default => nil
          t.column :value, :float
        end
        conn.add_index :cred2_scores, [:user_id,:tag_id]
      else
        conn.drop_table :cred1_scores
        conn.create_table :cred1_scores do |t|
          t.column :user_id, :integer
          t.column :tag_id, :integer, :default => nil
          t.column :value, :float
        end
        conn.add_index :cred1_scores, [:user_id,:tag_id]
      end
    }
  end

  def self.find_sink_ids(tag_id = nil)
    if tag_id.nil?
      connection.select_values("SELECT DISTINCT sink_id FROM creds")
    else
      connection.select_values("SELECT DISTINCT creds.sink_id FROM creds JOIN taggings ON taggings.taggable_type = 'Cred' AND taggings.taggable_id = creds.id AND taggings.tag_id = #{tag_id}")
    end
  end

  def self.out_counts(tag_id = nil)
    if tag_id.nil?
      records = connection.select_all("SELECT source_id, COUNT(id) cnt FROM creds GROUP BY source_id")
    else
      records = connection.select_all("SELECT source_id, COUNT(creds.id) cnt FROM creds JOIN taggings ON taggable_type = 'Cred' AND taggable_id = creds.id AND tag_id = #{tag_id} GROUP BY source_id")
    end
    oc = {}
    records.each{|r|
      oc[r['source_id']] = r['cnt'].to_i
    }
    return oc
  end

  def self.all_scores(tag_id = nil)
    if tag_id.nil?
      records = connection.select_all("SELECT user_id, value FROM #{score_table_name} WHERE tag_id IS NULL")
    else
      records = connection.select_all("SELECT user_id, value FROM #{score_table_name} WHERE tag_id = #{tag_id}")
    end
    allscores = {}
    records.each{|r|
      allscores[r['user_id']] = r['value'].to_f
    }
    return allscores
  end

  def self.sources_for_sink(sink_id, tag_id = nil)
    if tag_id.nil?
      connection.select_values("SELECT creds.source_id FROM creds WHERE creds.sink_id = #{sink_id}")
    else
      connection.select_values("SELECT creds.source_id FROM creds JOIN taggings ON taggable_type = 'Cred' AND taggable_id = creds.id AND tag_id = #{tag_id} AND creds.sink_id = #{sink_id}")
    end
  end

  # we should keep an eye on the memory usage of this feller
  # complexity analysis: u number of users, c number of creds
  # memory usage O(u)
  # db queries O(u)
  # arithmetic O(c)
  # and again for each tag, with u and c reduced
  def self.calc
    ActiveRecord::Base.transaction {
      Cred.initialize_write_score_table

      # pagerank parameters
      d = 0.85
      initial_score = (1.0 - d)

      overall_scores = all_scores
      out_count = out_counts()
      out_count.default = 1000000 # protect against cred changing race condition
      
      find_sink_ids.each{|sink_id|
      #  print "sink #{sink_id}\n"
        score = nil
        sources_for_sink(sink_id).each{|source_id|
        #  print " source #{source_id}"
          # only those who already have a score can affect others' scores
          if overall_scores[source_id] and overall_scores[source_id] > 0
          #  print ": #{overall_scores[source_id]}\n"
            score = initial_score if score.nil?
            score += d * overall_scores[source_id] / (out_count[source_id] + 1)
          #else
          #  print " has no score\n"
          end
        }
        unless score.nil?
          write_score_class.create(:user_id => sink_id, 
                                   :value => score)
        #  print " final score for #{sink_id}: #{score}\n"
        #else
        #  print " no score for #{sink_id}.\n"
        end
      }

      # by tag
      cred_tag_ids = connection.select_values("SELECT DISTINCT tag_id FROM taggings WHERE taggable_type = 'Cred'")
      cred_tag_ids.each{|tag_id|
        scores = all_scores(tag_id)
        out_count = out_counts(tag_id)
        out_count.default = 1000000 # protect against cred changing race condition

        find_sink_ids(tag_id).each{|sink_id|
          score = nil
          sources_for_sink(sink_id, tag_id).each{|source_id|
            # only those who already have a score can affect others' scores
            if overall_scores[source_id]
              score = initial_score if score.nil?
              if scores[source_id]
                score += d * scores[source_id] / (out_count[source_id] + 1)
              else
                # starting value for 1 cred from 1 person in a topic with no cred in or out is 1
                # 5 * (0.05 + 0.15)
                score += 0.1 / (out_count[source_id] + 1)
              end
            end
          }
          unless score.nil?
            write_score_class.create(:user_id => sink_id, 
                                     :tag_id => tag_id, 
                                     :value => score)
          end
        }
      }

      # Make people be careful with the cred they give
      # kill scores if they've given cred to bad people
      User.find_bad_ids.each {|i|
        write_score_class.find_all_by_user_id(i).each{|s|
          s.destroy
        }
        Cred.find_all_by_sink_id(i).each {|c| uid = c.source_id
          write_score_class.find_all_by_user_id(uid).each {|s|
            if s.tag_id.nil?
              s.value = -0.001
            else
              s.destroy
            end
          }
        }
      }
      
      top_scores = write_score_class.find_top_scores
      top_scores.each {|ts|
        ms = MaxScore.find_or_create_by_tag_id(ts.tag_id)
        ms.value = ts.value
        ms.save!
      }
      Cred.swap_score_tables
    }
  end

  # seeds must have a loop of cred, or scores will die off
  def self.initialize(seed_list = [1,4])
    # init score tables
    ActiveRecord::Base.transaction {
      Cred.initialize_write_score_table
      seed_list.each{|user_id|
        write_score_class.create(:user_id => user_id, :value => 1.0)
      }
      Cred.swap_score_tables
    }
    20.times{Cred.calc}
  end



  # tests with production data
  def self.test
    test_scores_by_tag_and_user
  end


  private

  def self.find_tag_id(options)
    if options[:tag_id]
      tag_id = options[:tag_id]
    elsif options[:tag]
      tag_id = options[:tag].id
    elsif options[:tag_name]
      tag_id = Tag.find_by_name(options[:tag_name]).id
    end
    return tag_id
  end

  def self.find_user_id(options)
    if options[:user_id]
      return options[:user_id]
    elsif options[:user]
      return options[:user].id
    end
  end

  def self.test_scores_by_tag_and_user
    u = User.find(4) # Dag
    users, tags, tbu, ubt = u.in_cred_with_extras
    s = scores_by_tag_and_user(tags.map{|t|t.id}, users.map{|u|u.id})
    users.each{|u|
      print "User #{u.dn}\n"
      tags.each{|t|
        hs = s[t.id][u.id]
        ds = score(:user => u, :tag => t)
        if ds > 0
          print " #{t.name} "
          if hs == ds
            print "OK: #{hs} \n"
          else
            print "!!!!!!!!!!!!!!!!!!!! hash: #{hs} db: #{ds}\n"
          end
        end
      }
    }
    p users, tags
  end
end
