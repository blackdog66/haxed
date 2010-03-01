package haxed;

import haxed.Common;
import bdog.JSON;

class Marshall {
  public static function
  fromJson(d:Dynamic):Status {
    var e;
    if (Reflect.field(d,"PAYLOAD") != null)
      e = Type.createEnum(Status,d.ERR,[d.PAYLOAD]);
    else
      e = Type.createEnum(Status,d.ERR);
    return e;
  }

  /* jsonp is the jsonp callback string */
  public static function
  toJson(s:Status,?jsonp:String):Dynamic {
    var m = Type.enumConstructor(s);
    var j = switch(s) {
    case OK_USER(ui):
      JSON.encode({ERR:m,PAYLOAD:ui});
    case OK_PROJECT(info):
      JSON.encode({ERR:m,PAYLOAD:info});
    case OK_PROJECTS(prjs):
      JSON.encode({ERR:m,PAYLOAD:prjs});
    case OK_SEARCH(s):
      JSON.encode({ERR:m,PAYLOAD:s});
    case OK_LICENSES(l):
      JSON.encode({ERR:m,PAYLOAD:l});
    case ERR_LICENSE(l):
      JSON.encode({ERR:m,PAYLOAD:l});
    case ERR_USER(email):
      JSON.encode({ERR:m,PAYLOAD:email});
    case OK_SERVERINFO(si):
      JSON.encode({ERR:m,PAYLOAD:si});
    case OK_TOPTAGS(tt):
      JSON.encode({ERR:m,PAYLOAD:tt});
    default:
      JSON.encode({ERR:m});
    }
    return (jsonp != null) ? (jsonp +"("+j+");") : j;
  }
}
