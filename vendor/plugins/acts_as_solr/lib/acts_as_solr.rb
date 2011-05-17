# Copyright (c) 2006 Erik Hatcher, Thiago Jackiw
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'active_record'
require 'rexml/document'
require 'net/http'
require 'yaml'

# What is acts_as_solr?
# ======================
# This plugin adds full text search capabilities using Solr to any Rails model.
# It was based on the first draft by Erik Hatcher.
# 
# Current Release: 0.04
# ====================
# Released on 11-07-06
# 
# Changes I made:
# ===============
# Please refer to the change log
# 
# Usage:
# ======
# Just include the line below to any of your ActiveRecord models:
# 
#   acts_as_solr
# 
# Or if you want, you can specify only the fields that should be indexed:
# 
#   acts_as_solr :fields => [:name, :author]
# 
# Then to find instances of your model, just do:
# 
#   Model.find_by_solr(query) or Model.find_id_by_solr(query)
# 
# Or if you want to specify the starting row and the number of rows per page:
# 
#   Model.find_by_solr(query, :start => 0, :rows => 10)
# 
# Authors:
# ========
# Erik Hatcher  => First draft
# Thiago Jackiw => tjackiw@gmail.com
# 
# Special Thanks to:
# ==================
# Mingle, LLC (www.mingle.com) for the opportunity
# 
# 
# Released under the MIT license.

module SolrMixin
  @@config = nil
  def post_to_solr(body, mode = :search)
    begin

      unless @@config
        @@config = YAML::load_file(RAILS_ROOT+'/config/solr.yml')
      end

      config = @@config
      if RAILS_ENV == 'development'
        server = config['development']['host']
        port = config['development']['port']
      elsif RAILS_ENV == 'production'
        server = config['production']['host']
        port = config['production']['port']
      end
      url = URI.parse("http://#{server}:#{port}")
      post = Net::HTTP::Post.new(mode == :search ? "/solr/select" : "/solr/update")
      post.body = body
      post.content_type = 'application/x-www-form-urlencoded'
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.request(post)
      end
      return response.body    
    rescue 
      logger.debug "Couldn't connect to the Solr server on #{server}:#{port}. #{$!}"
      false
    end
    
  end

  def solr_optimize
    post_to_solr('<optimize waitFlush="false" waitSearcher="false"/>', :update)
  end

  module Acts #:nodoc:
    module ARSolr #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        include SolrMixin
        
        def get_field_value(field)
          fields_for_solr << field
          define_method("#{field}_for_solr".to_sym) do
            begin
              value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.method(field).call
            rescue
              value = ''
              logger.debug "There was a problem getting the value for the field '#{field}': #{$!}"
            end
          end
        end

        def acts_as_solr(options={}, solr_options={})
          configuration = { 
            :fields => nil,
            :indexed => true,
            :stored => true,
            :background => false,
          }
          
          # Default Solr configuration, shouldn't be changed unless you know what 
          # you're doing because it uses the 'dynamic' type for the fields below.
          solr_configuration = {
            :type_field => "type_t",
            :primary_key_field => "pk_i",
            :default_field => "default"
          }
          
          configuration.update(options) if options.is_a?(Hash)
          solr_configuration.update(solr_options) if solr_options.is_a?(Hash)
          
          class_eval <<-CLE
              include SolrMixin::Acts::ARSolr::InstanceMethods
              if configuration[:background]
                include SolrMixin::Acts::ARSolr::BackgroundMethods
                after_create :solr_save_delayed
              else
                nil
                # do nothing here, we are manually saving our records
                #after_create    :solr_save
              end
              after_destroy :solr_destroy
              
              cattr_accessor :fields_for_solr
              cattr_accessor :configuration
              cattr_accessor :solr_configuration
              
              @@fields_for_solr = Array.new
              @@configuration = configuration
              @@solr_configuration = solr_configuration
              
              if configuration[:fields].respond_to?(:each)
                configuration[:fields].each do |field|
                  get_field_value(field)
                end
              else
                @@fields_for_solr = nil
              end
            CLE
        end

        # Here we do a dynamic search on all the indexed fields of your model, so you don't have
        # to specify a default field name to be searched against, which you normally had to do in 
        # the Solr schema config file. 
        # 
        # Here's a sample (untested) code for your controller:
        # 
        # def search
        #   results = Book.find_by_solr params[:query]
        # end
        # 
        # If you want to search on a specific field, you can search for 'field:value'
        # 
        # Options you can pass in are:
        # :start - The first document to be retrieved (offset)
        # :rows  - The number of rows per page
        # 
        def find_by_solr(query, options={})
          data = process_query(query, options)
          if data
            docs = data['response']['docs']
            return [] if docs.size == 0
            ids = docs.collect {|doc| doc["#{solr_configuration[:primary_key_field]}"]}
            conditions = [ "#{self.table_name}.id in (?)", ids ]
            return self.find(:all, :conditions => conditions)
          end
          return []
        end
        
        # Returns an array with the ids when using this search method:
        # Book.find_id_by_solr "rails" => [1,4,7]
        # 
        def find_id_by_solr(query, options={})
          data = process_query(query, options)
          if data
            docs = data['response']['docs']
            ids = docs.collect {|doc| doc["#{solr_configuration[:primary_key_field]}"]}
            return docs.size == 0 ? "" : ids
          end            
        end
        
        # count_by_solr returns you the total number of documents found
        # Book.count_by_solr 'rails' => 3
        # 
        def count_by_solr(query)        
          data = process_query(query)
          data ? data['response']['numFound'] : 0
        end
                
        # Rebuilds the Solr index
        def rebuild_solr_index
          self.find(:all).each {|content| content.solr_save}
          logger.debug self.count>0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
        end
        
        def fast_rebuild_solr_index(batch_size=100)
          0.step(self.count, batch_size) do |i|
            x = REXML::Element.new('add')
            self.find(:all, :limit => batch_size, :offset => i).each {|c|
              x.add_element(c.to_solr_doc)
            }
            post_to_solr(x.to_s, :update)
          end
          solr_optimize
        end

        private
        def process_query(query, options={})
          return if query.blank?
          begin
            query = "(#{query.gsub(/ *: */,"_t:")}) AND #{solr_configuration[:type_field]}:#{self.name}"
            options = !options.nil? && options.respond_to?(:each_pair) ? options.inject([]){|k,v| k << "#{v.first}=#{v.last}"}.join("&") : nil
            response = post_to_solr("q=#{ERB::Util::url_encode(query)}&wt=ruby&fl=#{solr_configuration[:primary_key_field]}&#{options}")
            begin
              response ? eval(response) : nil
            rescue SyntaxError
              raise response
            end
          rescue
            raise "There was a problem executing your search: #{$!}"
          end            
        end
      end

      module InstanceMethods
        include SolrMixin
        def solr_id
          "#{self.class.name}:#{self.id}"
        end

        # saves to the Solr index
        def solr_save
          logger.debug "solr_save: #{self.class.name} : #{self.id}"
          xml = REXML::Element.new('add')
          xml.add_element to_solr_doc
          response = post_to_solr(xml.to_s, :update)
          solr_commit
          true
        end

        # remove from index
        def solr_destroy
          logger.debug "solr_destroy: #{self.class.name} : #{self.id}"
          post_to_solr("<delete><id>#{solr_id}</id></delete>", :update)
          solr_commit
          true
        end

        @@last_solr_commit = nil
        def solr_commit
          if @@last_solr_commit.nil? or (Time.now - @@last_solr_commit > 30)
            post_to_solr('<commit waitFlush="false" waitSearcher="false"/>', :update)
            @@last_solr_commit = Time.now
          end
        end

        # convert instance to Solr document
        def to_solr_doc
          logger.debug "to_doc: creating doc for class: #{self.class.name}, id: #{self.id}"
          doc = REXML::Element.new('doc')

          # Solr id is <classname>:<id> to be unique across all models
          doc.add_element field("id", solr_id)
          doc.add_element field(solr_configuration[:type_field], self.class.name)
          doc.add_element field(solr_configuration[:primary_key_field], self.id.to_s)

          # iterate through the fields and add them to the document,
          # _t is appended as a dynamic "text" field for Solr
          default = ""
          unless fields_for_solr
            self.attributes.each_pair do |key,value|
              doc.add_element field("#{key}_t", value.to_s) unless key.to_s == "id"
              default << "#{value.to_s} "
            end
          else
            fields_for_solr.each do |field|
              value = self.send("#{field}_for_solr")
              doc.add_element field("#{field}_t", value.to_s)
              default << "#{value.to_s} "
            end
          end
          doc.add_element field(solr_configuration[:default_field], default)
          logger.debug doc
          return doc
        end
        
        def field(name, value)
          field = REXML::Element.new("field")
          field.add_attribute("name", name)
          field.add_attribute("indexed", configuration[:indexed])
          field.add_attribute("stored", configuration[:stored])
          field.add_text(value)
          field
        end

      end
      #Currently you must have Rails Cron enabled to use this sub-module.
      module BackgroundMethods
        def solr_save_delayed
          begin
            command_string = "#{self.class}.find_by_id(#{self.id}).solr_save_one_time"
            unless cron_job = RailsCron.find_by_command(command_string)
              cron_job = RailsCron.new(:concurrent => true)
            end
            cron_job.command = command_string
            cron_job.start = self.class.configuration[:background].minutes.from_now
            cron_job.every = 1.minute
            cron_job.finish = (self.class.configuration[:background] + 2).minutes.from_now
            cron_job.save
          rescue => e
            raise e + "Is rails_cron installed?"
          end
        end
        
        def solr_save_one_time
          self.solr_save
          command_string = "#{self.class}.find_by_id(#{self.id}).solr_save_one_time"
          if cron_job = RailsCron.find_by_command(command_string)
            cron_job.destroy
          end
        end
      end
    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it
ActiveRecord::Base.class_eval do
  include SolrMixin::Acts::ARSolr
end
