package tools.haxelib;

import tools.haxelib.Common;
import hxjson2.JSON;

class ERR {
  public static
  function msg(s:Status) {
    var m = Type.enumConstructor(s);
    return switch(s) {
    case OK_USER(ui):
      JSON.encode({ERR:m,PAYLOAD:ui});
    case OK_PROJECT(info):
      JSON.encode({ERR:m,PAYLOAD:info});
    case OK_SEARCH(s):
      JSON.encode({ERR:m,PAYLOAD:s});
    case ERR_USER(email):
      JSON.encode({ERR:m,PAYLOAD:email});
     default:
       JSON.encode({ERR:m});
    }
  }
}
 
enum Command {
  CMD_SEARCH(query:String,options:Hash<String>);
  CMD_INFO(project:String);
  CMD_USER(email:String);
  CMD_REGISTER(email:String,password:String,fullName:String);
  CMD_SUBMIT(pkgPath:String);
  CMD_DEV(prj:String,dir:String);
}

interface Repository {
  public function cleanup():Void;
  public function submit(password:String):Status;
  public function register(email:String,password:String,fullName:String):Status;
  public function user(email:String):Status;
  public function info(pkg:String):Status;
  public function search(query:String,options:Hash<String>):Status;
}
