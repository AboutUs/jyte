/*

	Table of Contents:

		Notice Messages
		Claim Widget
	
*/



/* Notice Messages ------------------------------------- */

var flashFlag = false;
function flash_notice(message)
{
    if (!flashFlag)
        {
            // 1. Disable a second function call until the first one completes
            flashFlag = true;
            
            // 2. Show the flash message
            if(!$('flash_notice_box'))
                {
                    new Insertion.Top(document.body, 
                                      '<div id="flash_notice_box">' + message + ' &nbsp;<a href="#" onclick="close_notice()">Close</a> this message.</div>'
                                      );
                }
            else
                {
                    Element.show('flash_notice_box');
                }
            
        }
}

function close_notice()
{
    Element.hide('flash_notice_box');
    Element.remove('flash_notice_box');
    flashFlag = false;
}
	

/* tug of war update */
function update_tug_of_war(yeas, nays) {
    var tug_of_war_bar = $('tug_of_war_bar');
    var p = (nays / (yeas+nays)*100);
    tug_of_war_bar.style.backgroundPosition = p + '%';

    /* update supporting text */
    $('total_votes_for').innerHTML = ''+yeas;
    $('total_votes_against').innerHTML = ''+nays;
    $('votes_for_percentage').innerHTML = Math.round(100-p)+'%';
    $('votes_against_percentage').innerHTML = Math.round(p)+'%';
}	

function update_agreed_disagreed_lists(current_vote, lorr) {
    var yv = $('your_vote');
    if(yv == null) {
        yv = document.createElement('li');
        yv.setAttribute('id', 'your_vote');
    }

    var list_element = null;
    if ((current_vote == true || current_vote == null) && lorr == 'right') {
        yv.setAttribute('class', $('meta_n_user_link').getAttribute('class'));
        yv.innerHTML = $('meta_n_user_link').innerHTML;
        list_element = $('disagreed_list');
        Element.hide('nobody_disagrees');
    } else if ((current_vote == false || current_vote == null) && lorr == 'left') {
        yv.setAttribute('class', $('meta_y_user_link').getAttribute('class'));
        yv.innerHTML = $('meta_y_user_link').innerHTML;
        list_element = $('agreed_list');
        Element.hide('nobody_agrees');
    }

    if(list_element) {
        Element.hide(yv);
        list_element.insertBefore(yv, list_element.firstChild);
        new Effect.Appear(yv);
    }
}	
	
/* Claim Widget ------------------------------------- */

function open_polls(num)
{
    // Close all previously hovered over widgets (bug fix)
    var allPageTags = new Array(); 
    var allPageTags = document.getElementsByTagName('div');
    
    for (i = 0; i < allPageTags.length; i++)
        {
            if (Element.hasClassName(allPageTags[i], 'making_a_vote'))
                {
                    Element.hide(allPageTags[i]);
                }
        }
    
    Element.show('making_vote_' + num);
}

function keep_open(element)
{
    // This function was developed as a fix that resulted from
    // crossing over from one anchor tag to the other. For some
    // reason it felt that I had left the parent element which
    // uses: onmouseover="open_polls(this);"
    Element.show(element);
}

function close_polls(element)
{
    Element.hide(element);
}


function update_vote(votes_element, voting_element, score) {
    if (typeof(score) == 'number') {
        Element.hide(votes_element);
        Element.hide(voting_element);
        votes_element.innerHTML = voting_element.innerHTML = score;
        new Effect.Appear(voting_element);
        new Effect.Appear(votes_element);
    }
}

var class_names = ['lowest','low','high','higher','highest'];

/* Given the current yeas and nays, return the class name which should
   reflect the vote state.
 */
function vote_widget_class(yeas, nays) {
    var _class = null;
    
    var total = yeas + nays;
    var yea_percent = yeas / total;
    var nay_percent = 1 - yea_percent;
    
    if(yeas > nays) {
        var index = yea_percent * (class_names.length-1);
        _class = class_names[Math.floor(index)] + '_green_value';
    } else if (yeas < nays) {
        var index = nay_percent  * (class_names.length-1);
        _class = class_names[Math.floor(index)] + '_pink_value';
    } else {
        _class = 'even_value';
    }

    return _class;
}

/* given yeas and nays, apply the appropriate class to the vote element */
function update_vote_widget_class(element, yeas, nays) {
    var _class = vote_widget_class(yeas, nays);
    new Element.ClassNames(element).set('showing_votes ' + _class);
}

function id_name_for_num(id_prefix, num) {
    if (num == null) return id_prefix;
    return id_prefix + '_' + num;
}

var vote_urls = [];
var vote_ajaxer = null;
function add_vote(url) {
    vote_urls.push(url);
    dispatch_vote();
}
function dispatch_vote() {
    if (vote_ajaxer) return;
    if (vote_urls.length == 0) return;
    vote_ajaxer = new Ajax.Request(vote_urls.shift(),
                                   {
                                       method:'get',
                                       onSuccess: function() {
                                           vote_ajaxer = null;
                                           dispatch_vote();
                                       }
                                   });
}


var liu_can_vote = [];
var liu_current_votes = [];
function vote_for(clicked_element, lorr, num, vote_url, claim_id)
{
    /* non-mouseover spans to update */
    var left_votes_element = $(id_name_for_num('votes_left_text', num));
    var left_voting_element = $(id_name_for_num('voting_left_text', num));
    
    /* mousedover spans to update */
    var right_votes_element = $(id_name_for_num('votes_right_text', num));
    var right_voting_element = $(id_name_for_num('voting_right_text', num));
    
    /* non-mouseover a to update */
    var a_votes_left_element = $(id_name_for_num('votes_left', num));
    var a_votes_right_element = $(id_name_for_num('votes_right', num));

    /* showing vote div */
    var showing_vote_element = $(id_name_for_num('showing_vote', num));

    current_vote = liu_current_votes[claim_id];

    if(current_vote == null && lorr == 'left') {
        update_vote(left_votes_element, left_voting_element, parseInt(left_votes_element.innerHTML)+1);
        add_vote(vote_url);
    }
    else if(current_vote == null && lorr == 'right') {
        update_vote(right_votes_element, right_voting_element, parseInt(right_votes_element.innerHTML)+1);
        add_vote(vote_url);
    }
    else if(current_vote == true && lorr == 'right') {
        update_vote(left_votes_element, left_voting_element, parseInt(left_votes_element.innerHTML)-1);
        update_vote(right_votes_element, right_voting_element, parseInt(right_votes_element.innerHTML)+1);
        add_vote(vote_url);
    }
    else if(current_vote == false && lorr == 'left') {
        update_vote(left_votes_element, left_voting_element, parseInt(left_votes_element.innerHTML)+1);
        update_vote(right_votes_element, right_voting_element, parseInt(right_votes_element.innerHTML)-1);
        add_vote(vote_url);
    }
    
    if (lorr == 'left') liu_current_votes[claim_id] = true;
    else if (lorr == 'right') liu_current_votes[claim_id] = false;
    
    var yeas = parseInt(left_votes_element.innerHTML);
    var nays = Math.abs(parseInt(right_votes_element.innerHTML));

    update_vote_widget_class(showing_vote_element, yeas, nays);
                      
    Element.addClassName(clicked_element, 'selected');         
    if (num != null) {
        position_background(clicked_element);
    } else {
        position_claim_background(clicked_element);
        update_tug_of_war(yeas, nays);
        update_agreed_disagreed_lists(current_vote, lorr);
    }
    
    if (lorr == 'left') {
        Element.addClassName(a_votes_left_element, 'selected');
        Element.removeClassName(a_votes_right_element, 'selected');
    }
    else {
        Element.addClassName(a_votes_right_element, 'selected');
        Element.removeClassName(a_votes_left_element, 'selected');
    }
}


	
function position_background(element)
{
    // this function is an IE css:hover bug fix
    if (!Element.hasClassName(element, 'selected'))
        {
            element.style.backgroundPosition = '-50px 0';
        }
    else
        {
            element.style.backgroundPosition = '-150px 0';
        }
}

function reposition_background(element)
{
    // this function is an IE css:hover bug fix
    if (!Element.hasClassName(element, 'selected'))
        {
            element.style.backgroundPosition = '0 0';
        }
    else
        {
            element.style.backgroundPosition = '-100px 0';
        }
}

/* handle display of the tab links
   Display of corresponding data must be done separately.
*/
function updateTab(tabName)
{
    var currentTabs = new Array();
    var currentTabs = document.getElementsByClassName('history_tab');
    
    for (i = 0; i < currentTabs.length; i++) {
      if (currentTabs[i].hasClassName('current')) {
        currentTabs[i].removeClassName('current');
      } 
    };
    $(tabName).addClassName('current');

}
