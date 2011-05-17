class Tag < ActiveRecord::Base
  has_many :taggings

  acts_as_solr :fields => [:name]

  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  def validate
    # take the tags out of the tag.
    unless self.name == strip_tags(self.name)
      errors.add(:name, "Nice try, joker")
    end
  end

  def self.parse(list)
    tag_names = []

    tag_names.concat list.split(/,/)

    # strip whitespace from the names
    tag_names = tag_names.map { |t| t.strip }

    # delete any blank tag names
    tag_names = tag_names.delete_if { |t| t.empty? }
    
    return tag_names
  end

  def self.find_neighbors(tag_id_or_name, taggable_type, options={})
    if tag_id_or_name.class == String
      t = self.find_by_name(tag_id_or_name)
      return [] if t.nil?
      tag_id = t.id
    else
      tag_id = tag_id_or_name
    end

    return [] if tag_id.nil?

    limit = options.fetch(:limit, 10)
    min_count = options.fetch(:min_count, 1)

    find_by_sql([
                 "SELECT tags.*, tc.count AS ncount FROM tags, tag_counts tc " +
                 "WHERE tags.id = tc.mentioned_tag_id AND tc.tag_id = ? " +
                 "AND tc.taggable_type = ? " +
                 "AND tc.count >= ? " +
                 "ORDER BY tc.count desc LIMIT ?",
                 tag_id, taggable_type, min_count, limit])
  end

  def tagged
    @tagged ||= taggings.collect { |tagging| tagging.taggable }
  end
  
  def on(taggable)
    taggings.create :taggable => taggable
  end
  
  def ==(comparison_object)
    super || name == comparison_object.to_s
  end
  
  def to_s
    name
  end

  def after_create
    self.solr_save
  end

end
