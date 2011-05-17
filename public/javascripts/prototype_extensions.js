/* some extensions to the built in javascript objects */

Object.extend(String.prototype,{
  rstrip: function() {
    var s = this.toString();
    while(true) {
      if (s.length > 0 && (s[s.length-1] == ' ' || s[s.length-1] == '\n')) {
        s = s.substr(0,s.length-1);
      } else {
        break;
      }
    }
    return s;
  },
  lstrip: function() {
    var s = this.toString();
    while(true) {
      if (s.length > 0 && (s[0] == ' ' || s[0] == '\n')) {
        s = s.substr(1, s.length-1);
      } else {
        break;
      }
    }
    return s;
  },
  strip: function() {return this.lstrip().rstrip();}
});

Object.extend(Array.prototype, {
 
  /* python slice for javascript arrays! */
  slice: function(start, end) {
    if (end == null) end = 0;
    if (start == null) start = 0;
    if (end > 0) {
      end = this.length - end;
    } else if (end < 0) {
      end = Math.abs(end)
    }
    a = this.toArray();
    for(var i=0; i < start; i++) a.shift();
    for(var i=0; i < end; i++) a.pop();
    return a;
  }
});

/* get outta my face, alert()!  */
function _alert(s) {
  var d = $('_alert');
  if (!d) {
    var d = document.createElement('DIV');
    d.setAttribute('id','_alert');
    d.setAttribute('style','background-color:#a00;color:#fff;');
    if (document.body.firstChild) {
      document.body.insertBefore(d, document.body.firstChild);
    } else {
      document.body.appendChild(d);
    }
  }

  if (s == null) s = 'null';
  else {
    if (typeof(s) == 'string') s = '"'+s+'"';
    else s = s.toString();
  }

  d.style.display = 'block';
  d.innerHTML = '<div style="float:right;margin:0;padding:0;"><a style="color:#fff;" onclick="$(\'_alert\').style.display=\'none\';">close</a></div>' + s
}
