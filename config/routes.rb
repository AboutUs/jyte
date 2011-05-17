ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  map.front '', :controller => "site"

  map.claim('cl/:urlslug',
            :controller => 'claim', :action => 'show',
            :requirements => {:urlslug => /.*/})
  map.short_claim 'cn/:id', :controller => 'claim', :action => 'show'
  
  map.find_claims 'claims/:bc_order', :controller => 'claim', :action => 'find', :bc_order => nil
  map.rss_claims 'rss/claims/:order',:controller=> 'claim',:action => 'find', :order => nil, :format => 'rss'

  map.claim_vote 'claim/vote/:claim_id/:vote', :controller => 'claim', :action => 'vote'
  map.claim_preview 'claim/preview/:urlslug', :controller => 'claim', :action => 'preview',
                    :requirements => {:urlslug => /.*/}

  map.profile2('profile/2/:uid',
	       :controller => 'user', :action => 'profile')

  map.profile('profile/:openid',
              :controller => "user", :action => "profile",
              :requirements => {:openid => /.*/})

  map.group 'groups/:urlslug', :controller => 'group', :action => 'show'

  # widget stuff
  map.claim_widget 'widget/claim/:urlslug', :controller => 'widget', :action => 'claim', :requirements => {:urlslug => /.*/}

  # API stuff
  map.connect 'api/group/:slug/is_member', :controller => 'group', :action => 'api_is_member'
  map.connect 'api/group/:slug/roster', :controller => 'group', :action => 'api_roster'
  map.connect 'api/contacts/roster', :controller => 'contacts', :action => 'api_roster'
  map.connect 'api/contacts/is_member', :controller => 'contacts', :action => 'api_is_member'
  map.connect 'api/user/info', :controller => 'user', :action => 'api_user_info'
  map.conect 'api/cred/by_tags', :controller => 'cred', :action => 'api_cred_by_tags'

  map.connect ':controller/:action/:id'


  # jyte 1.0 urls
  map.connect 'download.html', :controller => 'site',:action => 'index'
  map.connect 'news.xml', :controller => 'site',:action => 'index'
  map.connect 'frankbarnakosinternetdaily.xml', :controller => 'site',:action => 'index'
  map.connect 'venturewirealert.xml',:controller=>'site',:action=>'index'
  map.connect 'fastforward.xml',:controller=>'site',:action=>'index'
  map.connect 'theculturejammersnetwork.xml',:controller=>'site',:action=>'index'
  map.connect 'reviewaday.xml',:controller=>'site',:action=>'index'
  map.connect 'venturewirepeople.xml',:controller=>'site',:action=>'index'
  map.connect 'aladdintheatremailinglist.xml',:controller=>'site'
  map.connect 'streetlife.xml',:controller=>'site'
  map.connect 'dailydose.xml',:controller=>'site'
  map.connect 'download/jyte.exe',:controller=>'site'
  map.connect 'jyte.exe',:controller=>'site'
  map.connect 'rssandatom.html',:controller=>'site'
  map.connect 'tutorial.html',:controller=>'site'
end
