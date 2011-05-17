class SpyController < ApplicationController
  before_filter :auto_login
  
  def index
    @haps = Happening.find_all_since
  end

  def update
    t = params[:t]
    t = 0 if t.nil?
    t = t.to_i

    show = []
    if params[:show_claims]
      show << 'Claim'
    end
    if params[:show_comments]
      show << 'Comment'
    end
    if params[:show_votes]
      show << 'ClaimVoteHistory'
    end
    if params[:show_cred]
      show << 'Cred'
    end

    if show.empty?
      @haps = Happening.find_all_since(t)
    else
      @haps = Happening.find_all_since(t, :show => show)
    end
    
    # determine latest high water mark
    t = @haps.empty? ? t : @haps[0].id

    @haps.reverse!
    
    r = {'t' => t}
    r_count = 0
    r_html = ''

    if logged_in?
      blocked_user_ids = liu.blocked_user_ids
    else
      blocked_user_ids = []
    end

    @haps.each {|h|
      happenable = h.happenable


      if happenable.nil?
        h.destroy
        next

      elsif happenable.class == Claim
        if blocked_user_ids.member? happenable.user_id
          next
        end

        r["u_#{r_count}"] = render_to_string(:partial => 'spy/claim', :locals => {:claim=>happenable})
        
      elsif happenable.class == Comment
        if blocked_user_ids.member? happenable.user_id
          next
        end
        r["u_#{r_count}"] = render_to_string(:partial => 'spy/comment', :locals=>{:comment=>happenable})

      elsif happenable.class == ClaimVoteHistory
        if blocked_user_ids.member? happenable.user_id
          next
        end
        r["u_#{r_count}"] = render_to_string(:partial => 'spy/vote', :locals => {:vote=>happenable})

      elsif happenable.class == Cred
        r["u_#{r_count}"] = render_to_string(:partial => 'spy/cred', :locals => {:cred=>happenable})

      else
        raise ArgumentError, "Cannot handle happenable of type #{happenable.class}"
      end

      r_count += 1
    }

    r['u_count'] = r_count;

    render :text => r.to_json
  end

end
