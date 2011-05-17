class ImageResource < Resource
  file_column :image, :magick => {
    :versions => {
      :favicon => {:size => '20x20!', :crop => '1:1'},
      :icon  => {:size => '48x48!', :crop => '1:1'},
      :medium => {:size => '250x>'}
    }
  }
  
  validates_presence_of :image
end
