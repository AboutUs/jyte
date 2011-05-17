class WidgetResource < Resource
  
  validates_presence_of :widget

  def resize
    if widget.index('youtube.com')
      width_match = widget.match(/width=\"(\d+)\"/)
      if width_match
        width = width_match[1].to_f
      else
        raise ArgumentError, "bad yt width"
      end
      
      height_match = widget.match(/height=\"(\d+)\"/) 
      if height_match
        height = height_match[1].to_f
      else
        raise ArgumentError, "bad yt height"
      end
      
      ratio = height / width
      new_width = 250
      new_height = (new_width * ratio)
      
      resized = widget.dup
      resized.gsub!(width_match[0], "width=\"#{new_width}\"")
      resized.gsub!(height_match[0], "height=\"#{new_height}\"")
      return resized
    elsif widget.index('video.google.com')

      style_match = widget.match(/style=\"width:(\d+)px;\s*height:(\d+)px;"/)
      if style_match
        width = style_match[1].to_f
        height = style_match[2].to_f
        ratio = height / width
        new_width = 250
        new_height = new_width * ratio
        return widget.gsub(style_match[0], "style=\"width:#{new_width}px;height:#{new_width}px;\"")
      else
        raise ArgumentError, "weird google video size"
      end
    end

    raise ArgumentError, "does not look like a youtube or google video"
  end
  
  def clean

  end

end
