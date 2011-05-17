# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def logged_in?
    session[:user_id]
  end
  alias logged_in_user_id logged_in?
  alias liuid logged_in?

  def logged_in_user
    return nil unless logged_in?
    return @logged_in_user if @logged_in_user
    return @logged_in_user = User.find_by_id(session[:user_id])
  end
  alias liu logged_in_user

  def ensure_tag_cache_init
    unless @tags_by_id
      @tags_by_id = {}
      @tags_by_name = {}
    end
  end

  def find_tag(options)
    ensure_tag_cache_init
    if tag_id = options[:tag_id]
      if @tags_by_id[tag_id]
        return @tags_by_id[tag_id]
      else
        tag = Tag.find_by_id(tag_id)
      end
    elsif tag_name = options[:tag_name]
      if @tags_by_name[tag_name]
        return @tags_by_name[tag_name]
      else
        tag = Tag.find_by_name(tag_name)
      end
    else
      tag = options[:tag]
    end
    @tags_by_name[tag.name] = tag
    @tags_by_id[tag.id] = tag
    return tag
  end

  def ensure_user_cache_init
    unless @users_by_id
      @users_by_id = {}
      @users_by_openid = {}
    end
  end

  def claim_link(c)
    link_to(render_claim_title(c,false),
            :controller => 'claim',
            :action => 'show',
            :urlslug => c.urlslug)
  end

  # cache user objects on a per-request basis
  def find_user(options)
    ensure_user_cache_init
    if user = options[:user]
      @users_by_id[user.id] = user
      return user
    elsif user_id = (options[:id] or options[:user_id])
      if @users_by_id[user_id]
        return @users_by_id[user_id]
      else
        user = User.find_by_id(user_id)
        @users_by_id[user_id] = user
        return user
      end
    elsif openid = options[:openid]
      if @users_by_openid[openid]
        return @users_by_openid[openid]
      else
        user = User.find_by_openid(openid)
        if user
          @users_by_openid[openid] = user
          @users_by_id[user.id] = user
        end
        return user
      end
    end
  end

  # openid links to page about that user
  def user_link(options, html_options = {})
    user = find_user options
    if user.nil?
      raise unless openid = options[:openid]
    else
      openid = user.openid
      @users_by_openid[openid] = user
    end

    html_options = {:title => openid}.merge(html_options)

    if options[:nolink] == openid or options[:nolink] == true
      return span_tag(user_display(options), html_options)
    else
      # the line below was commented out because we need to escape
      # slashes in the user profile url.  this is now done in xprofile_url
      #return link_to(user_display(options), {:controller => 'user', :action => 'profile', :openid => denormalize_url(openid)}, html_options)

      dopenid = denormalize_url(openid)
      if dopenid.index('/').nil?
        return link_to(user_display(options),
                       xprofile_url(openid),
                       html_options)
      else
        return link_to(user_display(options),
		       url_for(:controller=>'user',:action=>'profile',:uid=>user.id.to_s,:only_path=>false),
                       html_options)
	end
    end
  end

  def xprofile_url(openid, options={})
    o = {
      :controller => 'user',
      :action => 'profile',
      :openid => denormalize_url(openid),
      :only_path => false
    }
    
    options.update(o)
    
    return url_for(options).gsub(/%2f/i, '/')
  end

  def profile_url(args)
    raise ArgumentError, 'use xprofile_url instead'
  end

  # user nickname or denormalized openid
  def user_display(options)
    user = find_user options
    if user.nil?
      raise unless options[:openid]
      result = h(denormalize_url(options[:openid]))
    else
      result = user.display_name
    end

    if options[:truncate]
      result = truncate(result, options[:truncate])
    end
    
    return result
  end

  def denormalize_url(url)
    no_proto = url.sub(/^http:\/\//, '')
    de_slash = no_proto.sub(/^([^\/]+)\/$/, '\1')
    return de_slash
  end

  def format_datetime(dt)
    return dt.strftime("%c")
  end

  def random_greek_letter
    # Poke fun at web 2.0, the perpetual beta.
    # Also at flickr, now in 'gamma' whatever that means
    greek_letters = ['alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta',
                      'eta', 'theta', 'iota', 'kappa', 'lambda', 'mu', 'nu',
                      'xi', 'omicron', 'pi', 'rho', 'sigma', 'tau',
                      'upsilon', 'phi', 'chi', 'psi', 'omega']
    return greek_letters[Time.now.yday%24]
  end

  def ie6?
    if @ie6.nil?
      ua = request.env['HTTP_USER_AGENT']
      if ua and ua.downcase.index('msie 6')
        @ie6 = true
      else
        @ie6 = false
      end
    end
    return @ie6
  end

  def ie_overlay_style
    if ie6?
      return "filter: alpha(opacity=50);"
    else
      return ""
    end
  end

  def ie_image_tag(source, options = {})
    ie_sucks_monkey_balls = "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{image_path(source)}');"
    style = ie_sucks_monkey_balls + (options[:style] or "")
    options[:style] = style
    image_tag('blank.gif', options)
  end
  
  # work around ie6 for png transparency
  def t_image_tag(source, options = {})
    if ie6?
      ie_image_tag(source, options)
    else
      image_tag(source, options)
    end
  end

  def image_url(image, size)
    if RAILS_ENV == 'production'
      return '/static/'+image.url_fragment(size)
    else
      return '/jimages/'+image.url_fragment(size)
    end
  end

  def oxford_comma_list(words, conjunction = "and")
    if words.size == 1
      s = words[0]
    elsif words.size == 2
      s = words[0] + " #{conjunction} " + words[1]
    else
      s = words[0..-2].join(', ') + ", #{conjunction} " + words[-1]
    end
    s
  end

  # XXX probably we should be using a separate html_options hash
  def icon_image(options={})
    user = find_user options

    options.delete(:user_id)
    options.delete(:user)

    if user 
      openid = user.openid
    elsif options[:openid]
      openid = options[:openid]
    end
    options.delete(:openid)

    size = options[:size] == 'favicon' ? 'favicon' : 'icon'
    size = options.fetch(:size, 'icon')
    
    if @user_icons
      im = @user_icons[user.id]
    else
      im = user.image
    end

    if user and im
      url = image_url(im, size)
      #url = url_for_file_column(user, :image, size)
      return url if options[:url]
    else
      if options[:size] == 'favicon'
        url = image_path("buddyiconfav.jpg")
      elsif size == 'big'
        url = image_path("no_icon_big.png")
      else
        url = image_path('no_icon_thumb.png')
      end
      return url if options[:url]
    end

    options[:alt] = openid
    options[:title] = openid

    linked = options.delete(:linked)

    img_html = image_tag(url, options)

    if linked == false
      return img_html
    elsif linked.kind_of? String
      return "<a href=\"#{linked}\" class=\"header_icon_link\">#{img_html}</a>"
    else
      return "<a href=\"#{xprofile_url(openid)}\" class=\"header_icon_link\">#{img_html}</a>"
    end
  end

  # XXX: ugh, the user and group icon rendering stuff should be merged at some
  # point, i think.
  def group_icon(options)
    group = options.delete(:group)
    raise ArgumentError unless group
    
    size = options.fetch(:size, 'thumb')
    
    if group.image
      url = image_url(group.image, size)
    else
      if size == 'favicon'
        url = image_path("buddyiconfav.jpg")
      elsif size == 'big'
        url = image_path('no_icon_big.png')
      else
        url = image_path('no_icon_thumb.png')
      end    
    end
       
    return url if options[:url]
    
    options[:alt] = h(group.name)
    options[:title] = h(group.name)
    
    img_html = image_tag(url, options)
    if options[:linked] == false
      return img_html
    else
      return link_to(img_html, gurl(group))
    end

  end

  def render_claim_title(claim, fancy = true)
    unless @simple_claim_titles
      @simple_claim_titles = {}
      @fancy_claim_titles = {}
    end
    if fancy and @fancy_claim_titles[claim.id]
      return @fancy_claim_titles[claim.id]
    end
    if not fancy and @simple_claim_titles[claim.id]
      return @simple_claim_titles[claim.id]
    end

    if @identifiers_by_claim_id
      identifiers = @identifiers_by_claim_id[claim.id]
    else
      identifiers = claim.identifiers
    end
  
    names = identifiers.collect {|i|
      if @users_by_user_id and i.user_id
        u = @users_by_user_id[i.user_id.to_i]
      else
        u = find_user(:id => i.user_id)
      end

      if u
        if fancy
          user_link({:user => u}, 
                    {:style => 'text-decoration:none',
                      :title => i.value,
                      :onmouseover => "this.style.textDecoration='underline'",
                      :onmouseout => "this.style.textDecoration='none'"})
        else
          u.dn
        end
      else
        s = strip_tags(i.shorten)
        if fancy
          link_to s, find_claims_url(:about => i.shorten), :title => "Find more claims about #{s}"
        else
          s
        end
      end
    }
    claim.parsed % names
  end
  
  def gmapjsurl
    # XXX: this could be smarter
    url = url_for :controller => '', :only_path => false
    uri = URI.parse(url)
    # why are the &s escaped in this url?
    gurl = 'http://maps.google.com/maps?file=api&amp;v=2&amp;key='

    key = GMAP_KEYS[uri.host]
    unless key
      raise ArgumentError, 'what the gmap key for this url? '+url
    end

    return gurl + key
  end
  
  def params_for_url(url)
    path = url.split('/')[(3..-1)]
    ActionController::Routing::Routes.recognize_path(path)    
  end

  def display_cred(cred)
    # Re adjusted so that the scores don't get too messed up by the cred algorithm
    (cred * 80.0).round/10.0
  end

  # XXX: this needs to escape javascript
  def contact_rel_link(t)
    et = escape_javascript(t)
    '<a href="#" onclick="var _e=$(\'contact_tags\');if(_e.value.length==0)_e.value=\'%s\';else _e.value+=\', %s\';return false;">%s</a>' % [et,et,h(t)]
  end

  def gurl(group)
    group_url :urlslug => group.urlslug
  end
  
  def cw_classes(yeas, nays)
    if yeas == nays
      return ['even_value', 'even_value']
    end

    class_names = ['lowest','low','high','higher','highest']

    if yeas > nays
      percent = nays.to_f / yeas
    else
      percent = yeas.to_f / nays
    end

    green = class_names[((1 - percent) * class_names.length-1).to_i]
    pink = class_names[(percent * class_names.length-1).to_i]
    
    return [green+'_green_value', pink+'_pink_value']
  end

  def cw_class(c)
    return "even_value" if c.yeas == c.nays
    class_names = ["highest_pink_value", "higher_pink_value", "high_pink_value", "low_pink_value", "lowest_pink_value", "lowest_green_value", "low_green_value", "high_green_value", "higher_green_value", "highest_green_value"]
    percent = c.yeas.to_f / (c.yeas + c.nays)
    return class_names[(percent * (class_names.length - 1)).round]
  end

  def user_allowed_links?(user_id)
    cred_n(user_id).to_i > 2
  end

  def cred_n(user_id, options = {})
    return nil unless user_id
    tag = options[:tag]
    if tag
      tag_id = options[:tag].id
    else
      tag_id = options[:tag_id]
    end
    scores = @norm_cred_scores
    if scores and scores[tag_id]
      score = scores[tag_id][user_id]
    else
      p "falling back to query for single score", @title
      score = Cred.score(:user_id => user_id, :normalized => true, :tag_id => tag_id)
    end
    if score.nil?
      return nil
    end
    
    return cred_n_for_score(score)
  end
  
  def cred_n_for_score(score)
    # To hell with precision, let's get more people with big dots.
    if score > 0.4
      if score > 0.6
        if score > 0.9
          return 10
        else
          if score > 0.75
            return 9
          else
            return 8
          end
        end
      else
        if score > 0.5
          return 7
        else
          return 6
        end
      end
    else
      if score > 0.2
        if score > 0.3
          return 5
        else
          return 4
        end
      else
        if score > 0.13
          return 3
        else
          if score > 0.07
            return 2
          else
            if score > 0.0
              return 1
            else
              return 0
            end
          end
        end
      end
    end  
  end

  def cred_img_for_score(score)
    if score.nil?
      return t_image_tag("dots/no_score.png", :class => 'inline', :size => '11x11')
    end
    n = cred_n_for_score(score)
    return t_image_tag("dots/#{n}.png", :class => 'inline', :size => '11x11')
  end

  def cred_img(user_id, options = {})
    n = cred_n(user_id, options)
    if n.nil?
      return t_image_tag("dots/no_score.png", :class => 'inline', :size => '11x11')
    else
      return t_image_tag("dots/#{n}.png", :class => 'inline', :size => '11x11')
    end
  end

  def cred_class_for_score(score)
    return "no_cred_color" if score.nil?
    n = cred_n_for_score(score)
    return "cred_color#{n}"
  end

  def cred_class(user_id, options = {})
    n = cred_n(user_id, options)
    if n.nil?
      return "no_cred_color"
    end
    return "cred_color#{n}"
  end

  def cred_dot_class(user_id, options = {})
    n = cred_n(user_id, tag)
    if n.nil?
      return "no_cred_dot"
    end
    return "cred_dot#{n}"
  end

  def sign_up_url
    if RAILS_ENV == 'production'
      return 'https://www.myopenid.com/affiliate_signup?affiliate_id=119'
    else
      return 'https://www.myopenid.com/affiliate_signup?affiliate_id=1'
    end
  end

  def safe_formatted(s, allow_links=false)
    #s = jsanitize(auto_link(s,:all,:target=>'_blank'))
    if allow_links
      s = auto_link(jsanitize(s, true), :all, {:target=>'_blank'})
    else
      s = auto_link(jsanitize(s), :all, {:target=>'_blank', :rel => 'nofollow'})
    end
    return s.gsub(/\r\n?/, "\n").
             gsub(/\n\n+/, "</p>\n\n<p>").
             gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')
  end

  VERBOTEN_ATTRS = /^(o|on|style|class|a)/
  VERBOTEN_VIDEO_ATTRS = /^(o|on|class)/
  TAG_WHITELIST = %(a ul ol li b strong i br blockquote img em p embed object param pre tt)
  EMBED_SRC_WHITELIST = /^http:\/\/(www\.youtube\.com|video\.google\.com)/

  # this is a modified version of TextHelper.sanitize
  def jsanitize(html, allow_links = false)
    return '' if html.nil?
    # only do this if absolutely necessary
    if html.index("<")
      tokenizer = HTML::Tokenizer.new(html)
      new_text = ""
      
      while token = tokenizer.next
        node = HTML::Node.parse(nil, 0, 0, token, false)
        x = case node
            when HTML::Tag
              unless TAG_WHITELIST.include?(node.name)
                node.to_s.gsub(/</, "&lt;")
              else
                if node.closing != :close
        
                  # bail if it contains parens (javascript?)
	          node.attributes.each {|a_name,a_val|
		  return '' if a_val =~ /[\(\)\n]/
		  }

                  if node.name == 'embed' 
                    if node.attributes['src'] =~ EMBED_SRC_WHITELIST
                      node.attributes.delete('style') if node.attributes['style'] =~ /expression/
                      node.attributes.delete_if { |attr,v| 
                    
                    attr =~ VERBOTEN_VIDEO_ATTRS }
                    else
                      return ''
                    end

                  else
                    node.attributes.delete_if { |attr,v|
                  attr =~ VERBOTEN_ATTRS }
                  end
                  ['href','src'].each { |attr|
                    node.attributes.delete attr if node.attributes[attr] =~ /^javascript:/i
                  }
                end
                if node.name == 'a' and node.attributes
                  node.attributes['target'] = '_blank'
                  unless allow_links
                    node.attributes['rel'] = 'nofollow'
                  end
                end
                node.to_s
              end
            else
              node.to_s.gsub(/</, "&lt;")
            end
        new_text << x
      end
      
      html = new_text
    end
    
    html
  end

  def is_iname?(openid)
    r = ['=', '@'].member?(openid[0].chr)
    return true if r
    return openid.index('xri://') == 0
  end
  
  def linked_tags(tags, sort=false, params=nil, sep=nil)
    if params.nil?
      params = {:controller => 'claim',:action=>'find'}
    end

    if sep.nil?
      sep = '<span style="color:white; font-size: 50%">, </span>' 
    end

    tag_names = tags.collect {|t| t.name}
    tag_names.sort! if sort
    tag_names.collect{|n|
      tag_name = h(n).gsub(' ', '&nbsp;')
      p = params.dup
      p[:tag] = n
      link_to(tag_name, p)
    }.join(sep)
  end

  def is_admin?
    if logged_in? and [:janrain,:jyte_team].member?(liu.get_state)
      return true
    end
    return false
  end

  def claim_has_image?(claim)
    return @claim_has_image.member?(claim.id) if @claim_has_image
    return claim.image
  end
  
  def html_ops_for_voter(claim, user)
    if @voter_labels.has_key?(user.id)
      html_ops = {:title=> @voter_labels[user.id],
                  :style=>'font-weight: bold;'}
    else
      html_ops = {:title => user.openid}
    end
    return html_ops

  end

  def display_tab(text)
    return "<div class=\"left_tab_corner\"></div><div class=\"tab_content\">#{text}</div><div class=\"right_tab_corner\"></div>"
  end

end

