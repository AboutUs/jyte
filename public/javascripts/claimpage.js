/* Claim Widget on claim show page------------------------------------- */
				
function vote_for_claim(element)
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
