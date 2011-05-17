<?
	
	// I am using variables throughout the pages much like the rhtml files will look like.
	
	$firstname = 'Jeremy';
	$lastname = 'Britton';
	$fullname = $firstname . ' ' . $lastname;
	$username = 'jebritton';
	$openid_url = 'http://jebritton.myopenid.com';
	$user_rating = 14.5;
	
	$layout = 'userprofile';
	
	$flash_notice = "<b>Hey {$firstname}!</b>&nbsp; You are now logged in as <b>{$username}</b>!  &nbsp;<a href=\"#\" onclick=\"close_notice();\">Close</a> this message.";
	
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<title>Profile for <?= $fullname ?> (<?= $username ?>)</title>
		
		<meta name="description" content="<?= $fullname ?>'s public profile Jyte." />
		<meta name="keywords" content="<?= $fullname ?>, <?= $username ?>, profile, public, reputation" />
		
		<meta http-equiv="Content-Language" content="en-GB" />
		<meta http-equiv="Content-Script-Type" content="text/javascript" />
		<meta http-equiv="Content-Style-Type" content="text/css" />
		<meta http-equiv="imagetoolbar" content="no" />
		
		<!-- Jyte Favicon -->
		<link rel="icon" href="http://www.jyte.com/favicon.ico" type="image/x-icon" />
		
		<link rel="stylesheet" type="text/css" href="global/css/<?= $layout ?>.css" />

		<script type="text/javascript" src="global/plugins/prototype/prototype.js"></script>
		<script type="text/javascript" src="global/plugins/scriptaculous/scriptaculous.js?load=effects"></script>
		<script type="text/javascript" src="global/js/global.js"></script>
		<script type="text/javascript">
			function updateTab(aTagElement)
			{
				// 1. Remove the current tab's style
				var allAnchorTags = new Array();
				var allAnchorTags = document.getElementsByTagName('a');

				for (i = 0; i < allAnchorTags.length; i++)
				{
					$(allAnchorTags[i]).removeClassName('current');
				}
				
				// 2. Hide the data attached to the current tab
				var allDivTags = new Array();
				var allDivTags = document.getElementsByTagName('div');

				for (i = 0; i < allDivTags.length; i++)
				{
					if(Element.hasClassName(allDivTags[i], 'history_box'))
					{
						Element.hide(allDivTags[i].id);
					}
				}
				
				// 3. Show the current tab and the data attached to it
				aTagElement.addClassName('current');
				Element.show(aTagElement.id + '_box');
			}
			
			function changeToCurrentTab()
			{
				// If a url is passed as ( http://www.jyte.com/index.rhtml#disputed_refuted )
				// it will switch to the Disputed or Refuted tab.
				
				if (location.href.indexOf('#') >= 0)
				{
					// 1. Get the anchor tag from the url
					urlAnchor = location.href.substring(location.href.indexOf('#'), location.href.length);
					anchorId = urlAnchor.substr(1, urlAnchor.length);
					
					if(Element.hasClassName(anchorId, 'history_tab') && anchorId != 'solid_claims')
					{
						// 2. Remove the current tab's style
						var allAnchorTags = new Array(); 
						var allAnchorTags = document.getElementsByTagName('a');
						
						for (i = 0; i < allAnchorTags.length; i++)
						{
							$(allAnchorTags[i]).removeClassName('current');
						}
						
						$(anchorId).addClassName('current');
						
						// 3. Hide the data attached to the current tab
						var allDivTags = new Array();
						var allDivTags = document.getElementsByTagName('div');

						for (i = 0; i < allDivTags.length; i++)
						{
							if(Element.hasClassName(allDivTags[i], 'history_box'))
							{
								Element.hide(allDivTags[i]);
							}
						}
						
						// 4. Show the current tab and the data attached to it
						Element.addClassName(anchorId, 'current');
						Element.show(anchorId + '_box');
					}
				}
			}
		</script>
	</head>

	<body>
		<? if(!empty($flash_notice)) { ?>
			<div id="flash_notice_box"><?= $flash_notice ?></div>
		<? } ?>
		<div id="global_container">
			<div id="constraints_box">
				<!-- Logged In Info Box (top) -->
				<div id="login_info_box">
					<ul>
						<li>Signed in as <a href="#"><?= $username ?></a></li>
						<li>(<a href="#">Sign Out</a>)</li>
						<li><a href="#">Help</a></li>
					</ul>
				</div>
				
				<!-- Site Nav -->
				<div id="site_nav_box">
					<ul>
						<li><a href="#"><b>Jyte</b></a></li>
						<li><a href="#">You</a></li>
						<li><a href="#">Your Stuff</a></li>
						<li><a href="#">Contacts</a></li>
						<li><a href="#">Groups</a></li>
						<li><a href="#">Everybody</a></li>
					</ul>
					<div id="search_box">
						<input type="text" />
						<a href="#">Go</a>
					</div>
					<div class="clear"></div>
				</div>
				
				<!-- Right Side -->
				<div id="user_info_box">
					<h1 id="username"><?= $username ?></h1>
					<div id="user_contact" class="fine_print">
						<span>aka <?= $fullname ?></span>
						<a href="#">Email <?= $firstname ?></a>
						<a href="#">Make a claim about <?= $firstname ?></a>
					</div>
					
					<p>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, nulla pariatur?"</p>
					<div id="openid_url">URL <a href="<?= $openid_url ?>" title="<?= fullname ?>'s Open ID"><?= $openid_url ?></a></div>
					
					<h4 id="user_interests">Interests</h4>
					<p><?= $fullname ?> likes to <a href="#">cycle</a>, <a href="#">lose at halo</a>, <a href="#">lick ketchup packets</a>, <a href="#">eat prune soup</a>, <a href="#">sing songs in open meadows</a>, <a href="#">eat cheese &amp; whine</a>, <a href="#">freestyle about butterflys</a>, eat tuna from a can, ride his bike in the park, and <a href="#">sleep</a>.</p>
					
					<h4 id="user_groups">Groups</h4>
					<p><?= $fullname ?> is a member of <a href="#">ZURB</a>, <a href="#">Breakdancers</a>, <a href="#">Freestyle Rappers</a>, <a href="#">The Mafia</a>, <a href="#">Chocoholics Anonymous</a>, and <a href="#">LuckyOliver</a>.</p>
					
					<h4 style="color: #090;">Very agreeable</h4>
					<ul class="plain_list">
						<li>90% agree over <a href="#">11 claims</a></li>
						<li>56% agree over <a href="#">52 votes</a></li>
						<li>83% agree over <a href="#">18 comments</a></li>
					</ul>

					<p><a href="#" onclick="flash_notice('<b>Hey <?= $firstname ?>!</b>&nbsp; You are now logged in as <b><?= $username ?></b>!');">Test</a> the optional javascript flash notice <i>(Make sure the current one is closed)</i>.</p>
				</div>
				
				<!-- Left Side (User Image & Statboard) -->
				<div id="left_side_box" class="purple_border_box">
					<div class="purple_box_top">
						<div class="purple_box_left"></div>
						<div class="purple_box_right"></div>
					</div>
					
					<!-- Box Content -->
					<div class="purple_box_content" style="padding: 0 6px;">
						<img id="profile_image" src="global/images/user.jpg" alt="image" />
						
						<div id="user_creds_box">
							<h1><?= $user_rating ?></h1>
							<h3>Creds</h3>
							<div class="clear"></div>
						</div>
						
						<div id="user_stats_box">
							<h4 id="best_qualities">Best Qualities</h4>
							<ul>
								<li class="biggest_purple_dot">
									<a href="#" class="attribute">bicycling</a>
									<span class="score">2.8</span>
								</li>
								<li class="smaller_purple_dot">
									<a href="#" class="attribute">brewing</a>
									<span class="score">10</span>
								</li>
								<li class="big_purple_dot">
									<a href="#" class="attribute">drinking</a>
									<span class="score">12</span>
								</li>
								<li class="smallest_purple_dot">
									<a href="#" class="attribute">hacking</a>
									<span class="score">78.9</span>
								</li>
								<li class="small_purple_dot">
									<a href="#" class="attribute">pole vaulting</a>
									<span class="score">99</span>
								</li>
								<li class="bigger_purple_dot">
									<a href="#" class="attribute">speaking</a>
									<span class="score">3.4</span>
								</li>
								<li class="big_purple_dot">
									<a href="#" class="attribute">teaching</a>
									<span class="score">0.3</span>
								</li>
								<li class="smaller_purple_dot">
									<a href="#" class="attribute">halo</a>
									<span class="score">0.7</span>
								</li>
								<li id="show_more_stats">
									<a href="#_" class="attribute" onclick="Effect.BlindDown('remaining_stats'); Element.remove('show_more_stats');">more...</a>
									<span class="score">&nbsp;</span>
								</li>
							</ul>
							<ul id="remaining_stats" style="display: none;">
								<li class="smallest_purple_dot">
									<a href="#" class="attribute">bicycling</a>
									<span class="score">2.8</span>
								</li>
								<li class="bigger_purple_dot">
									<a href="#" class="attribute">brewing</a>
									<span class="score">10</span>
								</li>
								<li class="small_purple_dot">
									<a href="#" class="attribute">drinking</a>
									<span class="score">12</span>
								</li>
								<li class="smallest_purple_dot">
									<a href="#" class="attribute">hacking</a>
									<span class="score">78.9</span>
								</li>
								<li class="biggest_purple_dot">
									<a href="#" class="attribute">pole vaulting</a>
									<span class="score">99</span>
								</li>
								<li class="smaller_purple_dot">
									<a href="#" class="attribute">speaking</a>
									<span class="score">3.4</span>
								</li>
								<li class="bigger_purple_dot">
									<a href="#" class="attribute">teaching</a>
									<span class="score">0.3</span>
								</li>
								<li class="big_purple_dot">
									<a href="#" class="attribute">halo</a>
									<span class="score">0.7</span>
								</li>
							</ul>
						</div>
					</div>
					<!-- End Box Content -->
					
					<div class="purple_box_bottom">
						<div class="purple_box_left"></div>
						<div class="purple_box_right"></div>
					</div>
				</div>
				
				<!-- Bottom -->
				<div id="history_container">
					<div id="tab_nav">
						<span>About:</span>
						<a href="#solid_claims" onclick="updateTab(this);" id="solid_claims" class="current history_tab">
							<div class="left_tab_corner"></div>
							<div class="tab_content">Solid Claims</div>
							<div class="right_tab_corner"></div>
						</a>
						<a href="#disputed_refuted" onclick="updateTab(this);" id="disputed_refuted" class="history_tab">
							<div class="left_tab_corner"></div>
							<div class="tab_content">Disputed or Refuted</div>
							<div class="right_tab_corner"></div>
						</a>
						<span>By:</span>
						<a href="#comments" onclick="updateTab(this);" id="comments" class="history_tab">
							<div class="left_tab_corner"></div>
							<div class="tab_content">Comments</div>
							<div class="right_tab_corner"></div>
						</a>
						<a href="#claims" onclick="updateTab(this);" id="claims" class="history_tab">
							<div class="left_tab_corner"></div>
							<div class="tab_content">Claims</div>
							<div class="right_tab_corner"></div>
						</a>
						<a href="#votes" onclick="updateTab(this);" id="votes" class="history_tab">
							<div class="left_tab_corner"></div>
							<div class="tab_content">Votes</div>
							<div class="right_tab_corner"></div>
						</a>
						<div class="clear"></div>
					</div>
					
					<div id="solid_claims_box" class="history_box">
						<h2>Solid claims</h2>
						<table>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #1 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_1" class="showing_votes highest_green_value" onmouseover="open_polls(1);">
											<a id="votes_left_1" href="#_" class="left_value big_number">2001</a>
											<a id="votes_right_1" href="#_" class="right_value big_number">1001</a>
										</div>
										<div id="making_vote_1" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_1" class="left_value big_number" onclick="vote_for(this, 1);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">2001</a>
											<a id="votes_against_1" class="right_value big_number" onclick="vote_for(this, 1);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">1001</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is an outstanding table tennis player.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score">
									<!-- Voting Widget #2 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_2" class="showing_votes higher_green_value" onmouseover="open_polls(2);">
											<a id="votes_left_2" href="#_" class="left_value selected">701</a>
											<a id="votes_right_2" href="#_" class="right_value">0</a>
										</div>
										<div id="making_vote_2" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_2" class="left_value selected" onclick="vote_for(this, 2);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">701</a>
											<a id="votes_against_2" class="right_value" onclick="vote_for(this, 2);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> works from home.</td>
							</tr>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #3 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_3" class="showing_votes high_green_value" onmouseover="open_polls(3);">
											<a id="votes_left_3" href="#_" class="left_value">501</a>
											<a id="votes_right_3" href="#_" class="right_value selected">0</a>
										</div>
										<div id="making_vote_3" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_3" class="left_value" onclick="vote_for(this, 3);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">501</a>
											<a id="votes_against_3" class="right_value selected" onclick="vote_for(this, 3);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score">
									<!-- Voting Widget #4 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_4" class="showing_votes low_green_value" onmouseover="open_polls(4);">
											<a id="votes_left_4" href="#_" class="left_value">301</a>
											<a id="votes_right_4" href="#_" class="right_value">0</a>
										</div>
										<div id="making_vote_4" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_4" class="left_value" onclick="vote_for(this, 4);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">301</a>
											<a id="votes_against_4" class="right_value" onclick="vote_for(this, 4);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #5 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_5" class="showing_votes lowest_green_value" onmouseover="open_polls(5);">
											<a id="votes_left_5" href="#_" class="left_value">101</a>
											<a id="votes_right_5" href="#_" class="right_value">0</a>
										</div>
										<div id="making_vote_5" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_5" class="left_value" onclick="vote_for(this, 5);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">101</a>
											<a id="votes_against_5" class="right_value" onclick="vote_for(this, 5);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score">
									<!-- Voting Widget #6 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_6" class="showing_votes even_value" onmouseover="open_polls(6);">
											<a id="votes_left_6" href="#_" class="left_value">50</a>
											<a id="votes_right_6" href="#_" class="right_value">50</a>
										</div>
										<div id="making_vote_6" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_6" class="left_value" onclick="vote_for(this, 6);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">50</a>
											<a id="votes_against_6" class="right_value" onclick="vote_for(this, 6);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">50</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #7 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_7" class="showing_votes lowest_pink_value" onmouseover="open_polls(7);">
											<a id="votes_left_7" href="#_" class="left_value">0</a>
											<a id="votes_right_7" href="#_" class="right_value">101</a>
										</div>
										<div id="making_vote_7" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_7" class="left_value" onclick="vote_for(this, 7);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
											<a id="votes_against_7" class="right_value" onclick="vote_for(this, 7);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">101</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score">
									<!-- Voting Widget #8 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_8" class="showing_votes low_pink_value" onmouseover="open_polls(8);">
											<a id="votes_left_8" href="#_" class="left_value">0</a>
											<a id="votes_right_8" href="#_" class="right_value">301</a>
										</div>
										<div id="making_vote_8" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_8" class="left_value" onclick="vote_for(this, 8);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
											<a id="votes_against_8" class="right_value" onclick="vote_for(this, 8);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">301</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #9 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_9" class="showing_votes high_pink_value" onmouseover="open_polls(9);">
											<a id="votes_left_9" href="#_" class="left_value">0</a>
											<a id="votes_right_9" href="#_" class="right_value">501</a>
										</div>
										<div id="making_vote_9" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_9" class="left_value" onclick="vote_for(this, 9);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
											<a id="votes_against_9" class="right_value" onclick="vote_for(this, 9);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">501</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score">
									<!-- Voting Widget #10 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_10" class="showing_votes higher_pink_value" onmouseover="open_polls(10);">
											<a id="votes_left_10" href="#_" class="left_value">0</a>
											<a id="votes_right_10" href="#_" class="right_value">701</a>
										</div>
										<div id="making_vote_10" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_10" class="left_value" onclick="vote_for(this, 10);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
											<a id="votes_against_10" class="right_value" onclick="vote_for(this, 10);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">701</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
							<tr>
								<td class="claim_score">
									<!-- Voting Widget #11 -->
									<div class="claim_voting_widget">
										<div id="showing_vote_11" class="showing_votes highest_pink_value" onmouseover="open_polls(11);">
											<a id="votes_left_11" href="#_" class="left_value">0</a>
											<a id="votes_right_11" href="#_" class="right_value">901</a>
										</div>
										<div id="making_vote_11" class="making_a_vote" onmouseover="keep_open(this);" onmouseout="close_polls(this);" style="display: none;">
											<a id="votes_for_11" class="left_value" onclick="vote_for(this, 11);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">0</a>
											<a id="votes_against_11" class="right_value" onclick="vote_for(this, 11);" onmouseover="position_background(this);" onmouseout="reposition_background(this);">901</a>
										</div>
									</div>
									<!-- End Voting Widget -->
								</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
						</table>
					</div>
					<div id="disputed_refuted_box" class="history_box" style="display: none;">
						<h2>Disputed or Refuted Claims</h2>
						<table>
							<tr>
								<td class="claim_score"><span>+</span>47</td>
								<td class="claim_text"><?= $firstname ?> is an outstanding table tennis player.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>28</td>
								<td class="claim_text"><?= $firstname ?> works from home.</td>
							</tr>
							<tr>
								<td class="claim_score"><span>-</span>83</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>92</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
						</table>
					</div>
					<div id="comments_box" class="history_box" style="display: none;">
						<h2>Comments made by <?= $firstname ?></h2>
						<table>
							<tr>
								<td class="claim_score"><span>+</span>29</td>
								<td class="claim_text"><?= $firstname ?> is an outstanding table tennis player.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>85</td>
								<td class="claim_text"><?= $firstname ?> works from home.</td>
							</tr>
							<tr>
								<td class="claim_score"><span>-</span>02</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>31</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
						</table>
					</div>
					<div id="claims_box" class="history_box" style="display: none;">
						<h2>Claims made by <?= $firstname ?></h2>
						<table>
							<tr>
								<td class="claim_score"><span>+</span>80</td>
								<td class="claim_text"><?= $firstname ?> is an outstanding table tennis player.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>35</td>
								<td class="claim_text"><?= $firstname ?> works from home.</td>
							</tr>
							<tr>
								<td class="claim_score"><span>-</span>72</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>18</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
						</table>
					</div>
					<div id="votes_box" class="history_box" style="display: none;">
						<h2>Votes made by <?= $firstname ?></h2>
						<table>
							<tr>
								<td class="claim_score"><span>+</span>76</td>
								<td class="claim_text"><?= $firstname ?> is an outstanding table tennis player.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>23</td>
								<td class="claim_text"><?= $firstname ?> works from home.</td>
							</tr>
							<tr>
								<td class="claim_score"><span>-</span>45</td>
								<td class="claim_text"><?= $firstname ?> is good at Halo.</td>
							</tr>
							<tr class="alternate">
								<td class="claim_score"><span>+</span>87</td>
								<td class="claim_text"><?= $firstname ?> likes Of Montreal.</td>
							</tr>
						</table>
					</div>
					<script type="text/javascript">
						changeToCurrentTab();
					</script>
				</div>
			</div>
		</div>
	</body>
</html>