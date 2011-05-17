require 'rubygems'
require 'fileutils'
require 'socket'

class Image < ActiveRecord::Base
  
  has_many :imagings
  validates_presence_of :host_num, :day, :suffix

  def Image.for_users(user_ids)
    uid_frag = '('+user_ids.join(',')+')'
    image_hash = {}
    find_by_sql("SELECT images.*, imagings.imagable_id user_id 
                   FROM images JOIN imagings ON imagings.image_id = images.id
                                            AND imagings.imagable_type = 'User'
                                            AND imagings.imagable_id IN #{uid_frag}").each {|i|
      image_hash[i.user_id.to_i] = i
    }
    return image_hash
  end

  def Image.from_blob(image_blob, imagable)
    logger.info "IMAGE.from_blob #{image_blob.size}"
    begin
      i = Magick::Image.from_blob(image_blob)[0]  # pass on the animation 4 now
    rescue
      return nil
    end
    
    

    day = nil
    suffix = nil

    imagable.image_sizes.each {|size|
      sized_image = self.send('size_'+size, i)
      sized_image.format = 'PNG'
      day, suffix = write_png(sized_image.to_blob, size, day, suffix)      
    }
   
    image = Image.create(:host_num => HOST_NUM,
                         :day => day,
                         :suffix => suffix)
  end

  def Image.size_orig(i)
    return i
  end

  def Image.size_big(i)
    return i.change_geometry('%dx>' % BIG_ICON_WIDTH) do |c,r,_i|
      _i.resize(c, r)
    end
  end
  
  def Image.size_thumb(i)
    # resize such that the larger side becomes THUMB_ICON_WIDTH
    if i.columns > i.rows
      g_string = '%dx' % [THUMB_ICON_WIDTH]
    elsif i.rows > i.columns
      g_string = 'x%d' % [THUMB_ICON_WIDTH]
    else
      # cols = rows, so we do a straight resize
      g_string = '%dx%d!' % [THUMB_ICON_WIDTH,THUMB_ICON_WIDTH]
    end

    # perform the resize
    i = i.change_geometry(g_string) do |c,r,_i|
      _i.resize(c, r)
    end

    # make it square again by compositing i onto a square transparent
    # image
    b = Magick::Image.new(THUMB_ICON_WIDTH,THUMB_ICON_WIDTH) {
      self.background_color = 'transparent'
    }
    return b.composite(i, Magick::CenterGravity, Magick::OverCompositeOp)
  end

  def Image.size_claim(i)
    return i.change_geometry('%dx>' % '500') do |c,r,_i|
      _i.resize(c, r)
    end
  end

  def Image.write_png(png_data, size, day=nil, suffix=nil)
    unless day
      day = Time.now.to_i / 60 / 60 / 24
    end

    day_s = "%08d" % day
    bucket_s = bucket(day)
    
    full_path = STATIC_IMAGE_DIR.join(HOST_NUM.to_s).join(bucket_s).join(day_s)
    FileUtils.mkdir_p(full_path)
    
    unless suffix
      mktemp_file_name = full_path.join("#{size}-XXXXXX")
      file_name = `mktemp #{mktemp_file_name}`.strip
      FileUtils.chmod(0644, file_name)
      suffix = file_name.to_s.split('-')[-1]
    else
      file_name = full_path.join("#{size}-#{suffix}")
    end
    
    file_name = file_name.to_s.chomp('/')

    f = File.new(file_name, 'w+')
    f.write(png_data)
    f.close

    FileUtils.mv(file_name, file_name+'.png')

    return [day, suffix]
  end

  def Image.bucket(day)
    "%03d" % (day % 1000)
  end

  # XXX: this should be in a helper i think
  def url(size)
    raise NotImplementedError
  end

  def filename(size)
    STATIC_IMAGE_DIR.join(HOST_NUM.to_s).join(Image.bucket(self.day)).join("%08d" % self.day).join("#{size}-#{self.suffix}.png")
  end

  # delete files on disk and then destory record
  def destroy_image(imagable)
    filenames = []
    imagable.image_sizes.each {|s|
      filenames << self.filename(s)
    }

    FileUtils.rm(filenames)
    self.destroy
  end
  
  # check to make sure the backing image files are there
  def check(imagable)
    imagable.image_sizes.each {|s|
      return false unless File.exists?(self.filename(s))
    }
    return true
  end

  def on(imagable)
    imagings.create :imagable => imagable
  end

  def url_fragment(size)
    [HOST_NUM.to_s, Image.bucket(self.day), "%08d" % self.day, "#{size}-#{self.suffix}.png"].join('/')
    
  end

end
