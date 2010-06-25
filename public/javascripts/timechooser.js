jQuery.fn.extend({
  time_chooser: function() {
    function move_arrows(e) {
        if(e.keyCode < 37 || 40 < e.keyCode) {
            return true;
        }
        var s = $(this).getSelection();
        var time = this.value.split(":").join("");
        var data = jQuery.data(this,"timechooser");
        var timechooser = (typeof data == "undefined")? TimeChooserNG(time, delivery_from.split(":").join(""), delivery_to.split(":").join(""), 30*60) : data;
        text = e.keyCode;
        switch(e.keyCode) {
          case 37: //left arrow
            s.start--;
            if(s.start == 2) {
              s.start--;
            }
            break;
          case 39: //right arrow
            if (s.end-s.start>0) s.start++;
            if(s.start == 2) {
              s.start++;
            }
            break;
          case 38:
              switch(s.start) {
                case 0:
                  timechooser.ten_hour_jump(1);
                  break;
                case 1:
                  timechooser.add(1*60*60);
                  break;
                case 3:
                  timechooser.add(10*60);
                  break;
                case 4:
                  timechooser.add(1*60);
                  break;
              }
              this.value = timechooser.toString();
            break;
          case 40:
              switch(s.start) {
                case 0:
                  timechooser.ten_hour_jump(-1);
                  break;
                case 1:
                  timechooser.add(-1*60*60);
                  break;
                case 3:
                  timechooser.add(-10*60);
                  break;
                case 4:
                  timechooser.add(-1*60);
                  break;
              }
              this.value = timechooser.toString();
            break;
        }
        jQuery.data(this,"timechooser",timechooser);
        $(this).setSelection(s.start,s.start+1);
        return false;        
    }
    function typing(e) {
      var s = $(this).getSelection();
      if($.browser.mozilla) {
          e.keyCode = e.which;
      }
      if(e.keyCode>47 && e.keyCode < 58) {
        var time = this.value.split("");
        time[s.start] = String.fromCharCode(e.keyCode);
        this.value = time.join("");
        s.start = (s.start++ > this.length)? this.length : s.start;
        if(s.start == 2 || s.start == 5) {
          s.start++;
        }
      }
      $(this).setSelection(s.start,s.start+1);   
      return false;
    }
    this.each(function(i) {
      if($.browser.safari || $.browser.msie) {
        $(this).keydown(move_arrows);
      }
      else {
        $(this).keypress(move_arrows);
      }
      $(this).keypress(typing);
    });
  }
});
var TimeChooserNG = window.TimeChooserNG = function(param, min, max, jump) {
  return new TimeChooserNG.prototype.init(param, min, max, jump);
}

TimeChooserNG.prototype = {
  seconds: 0,
  hours: function() {
    hours = Math.floor(this.seconds/3600);
    return ((hours+"").length == 1)? "0"+hours : hours;
  },
  minutes: function() {
    minutes = Math.floor((this.seconds%3600)/60);
    return ((minutes+"").length == 1 )? "0"+minutes : minutes;
  },
  max: {
    seconds: 60*60*24
  },
  min: {
    seconds: 0
  },
  jump: 0,
  set_jump: function(seconds) {
    this.jump = seconds;
  },
  options: {
    hours: true,
    minutes: true,
    seconds: false
  },
  add: function(seconds) {
    seconds = Math.ceil(seconds/this.jump) * this.jump;
    this.seconds += seconds;
    if(this.seconds > this.max.seconds) {
      this.seconds = this.min.seconds;
    }
    if(this.seconds < this.min.seconds ) {
      this.seconds = this.max.seconds;
    }
  },
  set_hours: function(value) {
     rest = this.seconds-this.hours()*3600;
     this.seconds = value*3600 + rest;
  },
  ten_hour_jump: function(way) {
    var hours = Math.floor(this.hours()/10);
    var h;
    switch(hours+way) {
      case 3:
        h = 0;
        break;
      case -1:
        h = 2;
        break;
      default:
        h=hours+way;
    }
    h = parseInt(h + "" + this.hours()%10);
    if(h>24) {
      h -= 20
    }
    this.set_hours(h)
  },
  toString: function() {
    var output = "";
    if(this.options.hours) {
      output += this.hours();
    }
    if(this.options.minutes) {
      output += ":"+this.minutes();
    }
    if(this.options.seconds) {
      output += ":"+this.seconds - (this.minutes()*60 + this.hours()*60*60)
    }
    return output;
  },
  parse_string: function(str, round) {
    var seconds = 0;
    var time = new Array(3);
    time = [0,0,0];
    var str = str.split("");
    for(var i=0;i<=str.length/2;i+=2) {
      if (str[i] == "0") {
        str[i] = "";
      }
      time[i/2] = parseInt(str[i] + str[i+1]);
    }
    seconds = time[0]*60*60 + time[1]*60 + time[2];
    if(typeof(round) != "undefined") {
      seconds = Math.round(seconds/round)*round;
    }
    return seconds;
  },
  init: function( param, min, max, jump) {
    this.seconds = this.parse_string(param);
    this.min.seconds = this.parse_string(min,1800);
    this.max.seconds = this.parse_string(max,1800);
    this.jump = jump;
    return this;
  }
}
TimeChooserNG.prototype.init.prototype = TimeChooserNG.prototype;