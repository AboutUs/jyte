class SiteController < ApplicationController
  #before_filter :auto_login
  before_filter :check_logged_in, :except => [:index, :find_users, :all_claims, :search,:contact,:tos,:api]

  def index
    # a featured claim has more than 25 votes.
    #@recent_claims = Claim.find_by_sql('SELECT claims.* FROM claims JOIN featured_claims ON claims.id = featured_claims.claim_id AND claims.state = 1 ORDER BY featured_claims.id DESC LIMIT 5')
    # top 5 most recent claims with more than 5 votes
    @recent_claims = Claim.find(:all, :conditions => ["claim_votes_count > 5"], :limit => 5,
                                      :order => "id desc")

    batch_load_claim_data(@recent_claims.collect {|c| c.id})
    
    @norm_cred_scores = {}
    @norm_cred_scores[nil] = Cred.scores_for_users @recent_claims.map{|c|c.user_id}, :normalized => true

    @toptags = Tag.find_by_sql("SELECT tags.*, COUNT(taggings.id) AS tagging_count FROM tags JOIN taggings ON taggings.tag_id = tags.id AND taggings.taggable_type = 'Claim' WHERE tags.name != 'jyte' GROUP BY taggings.tag_id ORDER BY tagging_count DESC LIMIT 10")
    @three_tag_names = @toptags.sort{|a,b|rand(3)-1}[0..2].map{|t|t.name}

    if logged_in?
      @liu_votes = ClaimVote.find_all_votes_hash(liuid,
                                              @recent_claims.collect{|c|c.id})
    end
    @rss_links = [rss_claims_url(:order=>'featured',:format=>'rss',
                                 :only_path=>false)]

    headers['x-xrds-location'] = url_for :only_path => false, :controller => 'auth', :action => 'xrds'
  end

  def search
    @title = "Search"
    @search_string = params[:q]
    @page = params[:page].to_i
    if @page.nil? or @page < 1
      @page = 1
    end
    return if @search_string.nil?
    offset = ((@page - 1) * 10)
    limit_frag = "LIMIT #{offset}, 10"
    begin
      @claims = Claim.find_by_solr(@search_string, :start => offset, :rows => 10)
      @claims.reject!{|c| c.state != 1}
      @comments = Comment.find_by_solr(@search_string, :start => offset, :rows => 10)
      @users = User.find_by_solr(@search_string, :start => offset, :rows => 10)
    rescue
      # try scrubbing search string
      flash[:notice] = "There was an error with your search string.  These results are for a similar query."
      @search_string.gsub!(/[\(<\[\]>\)=!^~\?:;\*\+\-\\]/,'')
      @search_string.gsub!(/OR|AND|NOT/,'')
      @claims = Claim.find_by_solr(@search_string, :start => offset, :rows => 10)
      @claims.reject!{|c| c.state != 1}
      @comments = Comment.find_by_solr(@search_string, :start => offset, :rows => 10)
      @users = User.find_by_solr(@search_string, :start => offset, :rows => 10)
    end
    claim_ids = @claims.collect {|cl|cl.id}
    @comment_claims = @comments.reject {|com|claim_ids.member? com.claim_id}.collect {|com| com.claim}.uniq

    # get the first tag in the query
    # XXX multiple tags?
    words = @search_string.split(' ').reject{|w|w.size < 3}[0..5]
    unless words.empty?
      w_frag = '(' << (['?']*words.size).join(',') << ')'
      tags = Tag.find_by_sql(["SELECT * FROM tags WHERE name IN #{w_frag}",words].flatten)
    end

    unless tags.nil? or tags.empty?
      tag_ids = tags.map{|t|t.id}
      tag_frag = "(#{tag_ids.join(',')})"
      if tags.size == 1
        @tag_names = tags[0].name
      else
        @tag_names = tags[0..-2].map{|t|t.name}.join(', ') << " or #{tags[-1].name}"
      end
      scores = Cred.score_class.table_name
      @cred_users = User.find_by_sql("SELECT users.*, SUM(scores.value) tag_cred FROM users JOIN #{scores} scores ON scores.user_id = users.id AND scores.tag_id IN #{tag_frag} GROUP BY users.id ORDER BY tag_cred DESC, users.id DESC #{limit_frag}")
      @tag_users = User.find_by_sql("SELECT users.*, COUNT(taggings.id) tag_count FROM users JOIN taggings ON taggings.taggable_type = 'User' AND taggings.taggable_id = users.id AND taggings.tag_id IN #{tag_frag} GROUP BY users.id ORDER BY tag_count DESC, users.id DESC #{limit_frag}")
      @groups = Group.find_by_sql("SELECT groups.*, COUNT(taggings.id) tag_count FROM groups JOIN taggings ON taggings.taggable_type = 'Group' AND taggings.taggable_id = groups.id AND taggings.tag_id IN #{tag_frag} GROUP BY groups.id ORDER BY tag_count DESC, groups.id DESC #{limit_frag}")
      @tag_claims = Claim.find_by_sql("SELECT claims.*, COUNT(taggings.id) tag_count FROM claims JOIN taggings ON taggings.taggable_type = 'Claim' AND taggings.taggable_id = claims.id AND taggings.tag_id IN #{tag_frag} AND claims.state = 1 GROUP BY claims.id ORDER BY tag_count DESC, claims.id DESC #{limit_frag}")
    else
      @cred_users = @tag_users = @groups = @tag_claims = []
    end

    if logged_in?
      claim_ids |= @comments.collect {|c| c.claim_id}
      claim_ids |= @tag_claims.collect {|c| c.id}
      @liu_votes = ClaimVote.find_all_votes_hash(liuid, claim_ids)
    end
  end


  def openid_search
    ids = Identifier.find_like(params[:q])
    render_text '<ul>'+ ids.collect {|i| '<li>'+i.value+'</li>'}.join('')  +'</ul>'
  end

  def contact
  end

  def tos
  end

  def api
  end

end
