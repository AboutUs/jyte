# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

task :pull => [:darcspull, :migrate]

task :darcspull do |t|
    sh "darcs pull"
end

# XXX: these should go in jyte/lib/tasks/jyte.rake (which doesn't exist)
namespace :jyte do
  
  desc 'Calc user ranks'
  task :calc_cred => :environment do |t|

    while true
      start = Time.now
      begin
        Cred.calc
      rescue ActiveRecord::Transactions::TransactionError
        STDERR.puts("#{Time.now} - Calc aborted, TransactionError")
        Kernel.sleep(3600)
      else
        STDERR.puts("#{Time.now} - Calc took #{Time.now - start} seconds.")
      end
      Kernel.sleep(3600)
    end        
  end

  desc 'Cred dump'
  task :cred_dump => :environment do |t|
    
    temp_filename = '/tmp/cret.txt.tmp'
    final_filename = Pathname.new(RAILS_ROOT).join('/var/jyte/static/misc/cred.txt')

    f = File.open(temp_filename, 'w')
    f.write("# generated #{DateTime.now.to_s}\n#\n")
    f.write("# line format: from_openid\tto_openid\tcsv cred tags\n#\n")
    f.write("# Contents of this file are distrubuted under the \n# Creative Commons Attribution-Noncommercial-Share Alike 2.5  License\n")
    f.write("# http://creativecommons.org/licenses/by-nc-sa/2.5/\n#\n")

    Cred.find(:all).each {|c|
      line = "#{c.source.openid}\t#{c.sink.openid}\t#{c.tag_list}\n"
      f.write(line)
    }
    f.close
    FileUtils.mv(temp_filename, final_filename)
    `gzip -f #{final_filename}`
  end

  desc 'User dump'
  task :user_openid_dump => :environment do |t|
    f= File.open('users.txt','w')
    User.find(:all).each {|u|
      f.write("#{u.openid}\n")
    }
    f.close
  end

  desc 'Minify Jyte Javascript'
  task :minifyjs => :environment do |t|
    libs = ['public/javascripts/prototype.js',
            'public/javascripts/effects.js',
            'public/javascripts/dragdrop.js',
            'public/javascripts/dragdrop.js',
            'public/javascripts/controls.js',
            'public/javascripts/application.js',
            'public/javascripts/global.js',
            'public/javascripts/claimpage.js',
            'public/javascripts/prototype_extensions.js'
           ]
    jsmin = 'script/javascript/jsmin.rb'
    final = 'public/javascripts/j.js'

    # create single js file
    tmp = Tempfile.open('all')
    libs.each {|lib| open(lib) {|f| tmp.write(f.read)}}
    tmp.rewind

    # minify js
    %x[ruby #{jsmin} < #{tmp.path} > #{final}]
    puts "\n#{final}"
  end

  desc 'GC bot sessions'
  task :gc_bot_sessions => :environment do |t|
    chunks = 10000
    last_id = 0
    while last_id != nil
      sessions = Session.find(:all,
                              :limit => chunks,
                              :conditions => ['id > ?',last_id],
                              :order => 'id ASC')

      p "Got #{sessions.length} sessions #{last_id}"

      if sessions.length > 0
        last_id = sessions[-1].id.to_i
        to_delete = []
        sessions.each {|s|
          to_delete << s.id if Marshal.load(Base64.decode64(s.data))[:user_id].nil?
        }
        
        if to_delete.length > 0
          p "Deleting #{to_delete.length} sessions..."
          Session.delete_all(["id IN (#{to_delete.join(',')})"])
        else
          p 'No sessions to delete in this batch'
        end
        
      else
        last_id = nil
      end
      Kernel.sleep(0.5)
    end
  end

  desc 'Run all jyte garbage collection tasks'
  task :gc => [:gc_sessions, :gc_openid_store]

  desc 'Remove all sessions that have not been updated in over a week'
  task :gc_sessions => :environment do |t|
    CGI::Session::ActiveRecordStore::Session.delete_all(['updated_at < ?', 1.week.ago])
  end     

  desc 'GC Happenings'
  task :gc_happenings => :environment do |t|
    h = Happening.find(:all, :order => 'id DESC', :limit => 1)[0]
    Happening.destroy_all(['id < ?', h.id - 15])
  end

  desc 'Remove stale nonces'
  task :gc_openid_store => :environment do
    ActiveRecordOpenIDStore.new.gc
  end

  desc 'recalc yeas/nays'
  task :recalc_yeas_nays => :environment do |t|

      Claim.find(:all, :order => 'id DESC').each {|c|
    ActiveRecord::Base.transaction {
        c.yeas = c.yea_votes.length
        c.nays = c.nay_votes.length
        c.save
      }

    }
  end

  desc 'delete bad votes'
  task :delete_bad_votes => :environment do
    ActiveRecord::Base.transaction {
      badvotes=[]
      Claim.find(:all).each{|c|
        c.voters.uniq.each{|u|
          badvotes += ClaimVote.find_by_sql(['select * from claim_votes where user_id = ? AND claim_id = ? order by created_at desc limit 1, 1000', u.id, c.id])
        }
      }
      puts "#{badvotes.size} bad votes.  Deleting..."
      badvotes.each {|v| v.destroy}
    }
  end

  # a temp task for cleaning up bad data from the mentioned identifiers
  desc 'clean up mentioned identifeirs'
  task :clean_mi => :environment do
    for i in 0..Claim.count
      seen = []
      mis = MentionedIdentifier.find_all_by_claim_id(i)
      next if mis.nil?
      mis.each {|mi|
        x = [mi.identifier_id, mi.order]
        if seen.member?(x)
          mi.destroy
        else
          seen << x
        end
      }
    end
  end

  task :tag_counts => [:init_tag_counts_table, :load_tag_counts]

  desc 'init tag_counts table'
  task :init_tag_counts_table => :environment do
    conn = ActiveRecord::Base.connection
    ActiveRecord::Base.transaction {
      begin
        conn.drop_table :tag_counts
      rescue
        nil
      end
      conn.create_table(:tag_counts, :id => false, :options => 'ENGINE=MyISAM') do |t|
        t.column :tag_id, :integer
        t.column :mentioned_tag_id, :integer
        t.column :taggable_type, :string
        t.column :count, :integer
      end
      conn.add_index :tag_counts, [:tag_id,:taggable_type]
    }
  end

  desc 'load tag counts table from taggings'
  task :load_tag_counts => :environment do
    
    ignore_tags = ['team tomato', 'bubble tea']
    ignore_ids = Tag.find_all_by_name(ignore_ids).map {|t| t.id}

    ['User','Claim','Cred'].each {|klass|

      all_taggings = ActiveRecord::Base.connection.select_all("SELECT tag_id,taggable_id,taggable_type FROM taggings WHERE taggable_type = '#{klass}'")
      
      # tags_for_taggable = {[taggable_id,taggable_type] => [tag_id,]}
      tags_for_taggable = {}
      all_taggings.each {|h|
        key = [h['taggable_id'].to_i, h['taggable_type']]
        tag_id = h['tag_id'].to_i
        next if ignore_ids.member?(tag_id)

        if tags_for_taggable.has_key?(key)
          tags_for_taggable[key] |= [tag_id]
        else
          tags_for_taggable[key] = [tag_id]
        end
      }
      # gc hack
      all_taggings = nil
      GC.start

      # tag_counts = {[tag_id_1,tag_id_2,taggable_type] => count}
      tag_counts = {}
      tags_for_taggable.each {|k,tag_ids|
        
        taggable_id, taggable_type = k

        # permutate and update counts
        tag_ids.each {|tag_id|
          tag_ids_copy = tag_ids.dup
          tag_ids_copy.delete(tag_id)
          tag_ids_copy.each {|tag_id_2|
            key = [tag_id,tag_id_2]
            key.sort!
            key << taggable_type
            if tag_counts.has_key?(key)
              tag_counts[key] += 1
            else
              tag_counts[key] = 1
            end
          }
        }
      }
      # gc hack
      tags_for_taggable = nil
      GC.start

      # generate all the table entries for efficient searching
      le_table = []
      tag_counts.each {|k,count|
        tag_id_1, tag_id_2, taggable_type = k
        count = count / 2
        le_table << [tag_id_1, tag_id_2, taggable_type, count]
        le_table << [tag_id_2, tag_id_1, taggable_type, count]
      }
      tag_counts = nil
      GC.start

      # update database
      chunk = 5000
      (0..le_table.size).step(chunk) { |offset|
        
        rows = le_table[offset..offset+chunk]
        break if rows.size == 0
        
        sql = "INSERT INTO tag_counts (tag_id,mentioned_tag_id,taggable_type,count) VALUES "
        sql += rows.collect {|a,b,c,d| "(#{a},#{b},'#{c}',#{d})"}.join(', ')
        ActiveRecord::Base.connection.execute(sql)
      }
    }
  end
  
end
