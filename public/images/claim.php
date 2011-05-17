<?
	
	// I am using variables throughout the pages much like the rhtml files will look like.
	
	$firstname = 'Jeremy';
	$lastname = 'Britton';
	$fullname = $firstname . ' ' . $lastname;
	$username = 'jebritton';
	$openid_url = 'http://jebritton.myopenid.com';
	$user_rating = 14.5;
	
	$layout = 'claimpage';
	
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
			/* Claim Widget ------------------------------------- */
				
				function vote_for(element)
				{
					// Increment the vote number
					element.innerHTML = parseInt(element.innerHTML) + 1;
					Element.addClassName(element, 'selected');
					element.style.backgroundPosition = '-240px 0';
					
					if (Element.hasClassName(element, 'left_value'))
					{
						$('votes_left').innerHTML = parseInt($('votes_left').innerHTML) + 1;
						Element.addClassName('votes_left', 'selected');
					}
					else
					{
						$('votes_right').innerHTML = parseInt($('votes_right').innerHTML) + 1;
						Element.addClassName('votes_right', 'selected');
					}
				}
				
				function position_claim_background(element)
				{
					// this function is an IE css:hover bug fix
					if (!Element.hasClassName(element, 'selected'))
					{
						element.style.backgroundPosition = '-80px 0';
					}
					else
					{
						element.style.backgroundPosition = '-240px 0';
					}
				}
				
				function reposition_claim_background(element)
				{
					// this function is an IE css:hover bug fix
					if (!Element.hasClassName(element, 'selected'))
					{
						element.style.backgroundPosition = '0 0';
					}
					else
					{
						element.style.backgroundPosition = '-160px 0';
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
				
				
				<div id="claim_box">
					<h1 id="claim">New Cloud Logo is looking good.</h1>
					<h4 id="claim_made_by">By <span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> on July 4th, 2006</h4>
					
					<div id="supporting_material">
						<img src="global/images/test_image.jpg" alt="SEO title" />
						<h4>Totam Rem Aperiam</h4>
						<p>"Sed ut perspiciatis unde omnis iste natus error sit <a href="#">voluptatem accusantium</a> doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, nulla pariatur?"</p>
						<p><b>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium,</b> totam rem aperiam, eaque ipsa quae ab illo inventore <a href="#">veritatis</a> et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim <a href="#">ipsam voluptatem</a> quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, <a href="#">nulla pariatur</a>?"</p>
					</div>
				</div>
				<div id="at_the_polls_box">
					<div id="make_a_vote_box">
						<div id="showing_vote" class="showing_votes highest_green_value" onmouseover="Element.show('making_vote');">
							<a id="votes_left" href="#_" class="left_value">901</a>
							<a id="votes_right" href="#_" class="right_value">901</a>
						</div>
						<div id="making_vote" class="making_a_vote" style="display: none;" onmouseover="Element.show(this);" onmouseout="Element.hide(this);">
							<a id="votes_for" class="left_value" onclick="vote_for(this);" onmouseover="position_claim_background(this);" onmouseout="reposition_background(this);">901</a>
							<a id="votes_against" class="right_value" onclick="vote_for(this);" onmouseover="position_claim_background(this);" onmouseout="reposition_background(this);">901</a>
						</div>
					</div>
					
					<div id="agreed_disagreed_box">
						<div id="votes_for_box">
							<h4>Agreed <span>(61)</span></h4>
							<table>
								<tr>
									<td>
										<ul class="plain_list dots_on_right">
											<li class="biggest_purple_dot">
												<a href="#">ryanw</a>
											</li>
											<li class="smaller_purple_dot">
												<a href="#">jebritton</a>
											</li>
											<li class="big_purple_dot">
												<a href="#">rkonves</a>
											</li>
											<li class="smallest_purple_dot">
												<a href="#">bzmijewski</a>
											</li>
											<li class="small_purple_dot">
												<a href="#">joelmichael</a>
											</li>
										</ul>
									</td>
									<td>
										<ul class="plain_list dots_on_right">
											<li class="biggest_purple_dot">
												<a href="#">ryanw</a>
											</li>
											<li class="smaller_purple_dot your_vote">
												jebritton (you)
											</li>
											<li class="big_purple_dot">
												<a href="#">rkonves</a>
											</li>
											<li class="smallest_purple_dot">
												<a href="#">bzmijewski</a>
											</li>
											<li class="small_purple_dot">
												<a href="#">joelmichael</a>
											</li>
											<li class="no_dot">
												<a href="#">more...</a>
											</li>
										</ul>
									</td>
								</tr>
							</table>
							<div class="fine_print list_of_groups">
								Voters from 14 groups, including <a href="#">JanRain</a>, <a href="#">ZURB</a>, <a href="#">The Who</a>, and <a href="#">more.</a>
							</div>
						</div>
						<div id="votes_against_box">
							<h4>Disagreed <span>(39)</span></h4>
							<table>
								<tr>
									<td>
										<ul class="plain_list">
											<li class="biggest_purple_dot">
												<a href="#">ryanw</a>
											</li>
											<li class="smaller_purple_dot your_vote">
												jebritton (you)
											</li>
											<li class="big_purple_dot">
												<a href="#">rkonves</a>
											</li>
											<li class="smallest_purple_dot">
												<a href="#">bzmijewski</a>
											</li>
											<li class="small_purple_dot">
												<a href="#">joelmichael</a>
											</li>
											<li class="no_dot">
												<a href="#">more...</a>
											</li>
										</ul>
									</td>
									<td>
										<ul class="plain_list">
											<li class="biggest_purple_dot">
												<a href="#">ryanw</a>
											</li>
											<li class="smaller_purple_dot">
												<a href="#">jebritton</a>
											</li>
											<li class="big_purple_dot">
												<a href="#">rkonves</a>
											</li>
											<li class="smallest_purple_dot">
												<a href="#">bzmijewski</a>
											</li>
											<li class="small_purple_dot">
												<a href="#">joelmichael</a>
											</li>
										</ul>
									</td>
								</tr>
							</table>
							<div class="fine_print list_of_groups">
								Voters from 14 groups, including <a href="#">JanRain</a>, <a href="#">ZURB</a>, <a href="#">The Who</a>, and <a href="#">more.</a>
							</div>
						</div>
						<div class="clear"></div>
					</div>
					<div id="tug_of_war_box">
						<div class="tug_of_war_box_top">
							<div class="tug_of_war_box_left"></div>
							<div class="tug_of_war_box_right"></div>
						</div>
						
						<!-- Box Content -->
						<div class="tug_of_war_box_content">
							<h3 id="total_votes_for">61</h3><h3 id="total_votes_against">39</h3>
							<!-- The bar will be easily (if the votes are 0-100) by applying the votes against as the background position -->
							<div id="tug_of_war_bar" style="background-position: 39% 0;"></div>
							<span id="votes_for_percentage">61.0%</span><span id="votes_against_percentage">39.0%</span>
						</div>
						
						<div class="tug_of_war_box_bottom">
							<div class="tug_of_war_box_left"></div>
							<div class="tug_of_war_box_right"></div>
						</div>
					</div>
				</div>
				<div id="claim_actions_box" class="fine_print">
					<b>Embed Claim</b> <input type="text" onclick="this.select()" value="<a href='http://www.jyte.com/claim/new-cloud-logo-is-looking-good'><img src='path/to/image'/></a>" />
					<a href="#" class="email">Email this</a>
					<a href="#" class="claim">Make a related claim</a>
				</div>
				<div id="claim_comments">
					<h2>Comments</h2>
					
					<!-- Comment 1 -->
					<table class="comment">
						<tr>
							<td>
								<a href="#" class="avatar">
									<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
								</a>
							</td>
							<td>
								<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="agreed">agreed</span>, says</h4>
								<div class="their_words">
									"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore <a href="#">veritatis</a> et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim <a href="#">ipsam voluptatem</a> <b>quia voluptas sit</b> aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, <a href="#">nulla pariatur</a>?"
								</div>
								<div class="comment_actions">
									<span>6 days ago</span>
									<a href="#" class="reply">Reply</a>
									<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
									<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
								</div>
								<div class="open_follow_up_comments">
									<a href="#_" onclick="Effect.BlindDown('follow_up_comments_1');" class="arrow">9 follow-ups</a> to this comment
								</div>
								<div id="follow_up_comments_1" class="follow_up_comments" style="display: none;">
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
																		<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
									<table class="comment">
										<tr>
											<td>
												<a href="#" class="avatar">
													<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
												</a>
											</td>
											<td>
												<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
												<div class="their_words">
													Sed ut perspiciatis unde omnis iste natus error.
												</div>
												<div class="comment_actions">
													<span>6 days ago</span>
													<a href="#" class="reply">Reply</a>
													<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
													<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
												</div>
											</td>
										</tr>
									</table>
								</div>
							</td>
						</tr>
					</table>
					
					<!-- Comment 2 -->
					<table class="comment">
						<tr>
							<td>
								<a href="#" class="avatar">
									<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
								</a>
							</td>
							<td>
								<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> who <span class="disagreed">disagreed</span>, says</h4>
								<div class="their_words">
									Sed ut perspiciatis unde omnis iste natus error.
								</div>
								<div class="comment_actions">
									<span>6 days ago</span>
									<a href="#" class="reply">Reply</a>
									<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
									<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
								</div>
							</td>
						</tr>
					</table>
					
					<!-- Comment 3 -->
					<table class="comment">
						<tr>
							<td>
								<a href="#" class="avatar">
									<img src="global/images/user.jpg" alt="SEO Title" style="height: 48px; width: 48px;" />
								</a>
							</td>
							<td>
								<h4 class="user_who_commented"><span class="inline_dot bigger_purple_dot"><a href="#"><?= $username ?></a></span> says</h4>
								<div class="their_words">
									Sed ut perspiciatis unde omnis iste natus error.
								</div>
								<div class="comment_actions">
									<span>6 days ago</span>
									<a href="#" class="reply">Reply</a>
									<a href="#"><img src="global/images/good_comment.gif" alt="Username made a good comment" /></a>
									<a href="#"><img src="global/images/bad_comment.gif" alt="Username made a bad comment" /></a>
								</div>
							</td>
						</tr>
					</table>
					
					<!-- Add a Comment -->
					<h3 id="new_comment">Make a new comment</h3>
					<textarea></textarea>
					<input type="submit" value="Submit Comment" />
				</div>
				<div id="claims_spun_off_this">
					<h2>Inspired by this</h2>
					<ul class="plain_list">
						<li><a href="#"><span class="inline_score highest_green_value">13-7</span> Three bull's eyes in a row is good.</a></li>
						<li><a href="#"><span class="inline_score higher_green_value">13-7</span> Bull's eyes are difficult to throw.</a></li>
						<li><a href="#"><span class="inline_score low_pink_value">13-7</span> Darts are fun.</a></li>
					</ul>
					
					<h2>Claim history</h2>
					<ul class="plain_list">
						<li><a href="#"><span class="inline_score highest_green_value">13-7</span> Three bull's eyes in a row is good.</a></li>
						<li><a href="#"><span class="inline_score higher_green_value">13-7</span> Bull's eyes are difficult to throw.</a></li>
						<li><a href="#"><span class="inline_score low_pink_value">13-7</span> Darts are fun.</a></li>
					</ul>
					
					<h2>Related topics</h2>
					<p><a href="#">logos,</a> <a href="#">clouds,</a> <a href="#">rain,</a> <a href="#">janrain,</a> <a href="#">design,</a> and <a href="#">windy.</a>
				</div>
			</div>
		</div>
	</body>
</html>