package tools.haxelib;

/*
  Used across neko, php and js
*/

import hxjson2.JSON;

/*
  Data structures used in marshalling between targets

*/

typedef UserInfo = {
  var fullname : String;
  var email : String;
  var projects : Array<{name:String}>;
}

typedef VersionInfo = {
  var date : String;
  var name : String;
  var comments : String;
}

typedef ProjectInfo = {
  var name : String;
  var desc : String;
  var website : String;
  var owner : String;
  var license : String;
  var curversion : String;
  var versions : Array<VersionInfo>;
}

typedef SearchInfo = {
  var items : Array<{id:Int,name:String,context:String}>;
}

typedef LicenseSpec = {
  var pub:Bool;
  var name:String;
  var url:String;
}

typedef LicenseErr = {
  var licenses:Array<LicenseSpec>;
  var given:String;
}

typedef ServerInfo = {
  var name:String;
  var licenses:Array<LicenseSpec>;
}
  
enum Status {
  OK_USER(ui:UserInfo);
  OK_PROJECT(pi:ProjectInfo);
  OK_PROJECTS(prj:Array<ProjectInfo>);
  OK_SEARCH(si:SearchInfo);
  OK_LICENSES(lics:Array<LicenseSpec>);
  OK_REGISTER;
  OK_SUBMIT;
  OK_ACCOUNT;
  OK_SERVERINFO(si:ServerInfo);
  OK_REMINDER;
  ERR_REMINDER;
  ERR_LICENSE(info:LicenseErr);
  ERR_UNKNOWN;
  ERR_NOTHANDLED;
  ERR_PASSWORD(which:String);
  ERR_EMAIL(which:String);
  ERR_DEVELOPER;
  ERR_HAXELIBJSON;
  ERR_USER(email:String);
  ERR_REGISTERED;
  ERR_PROJECTNOTFOUND;
}

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
  
  public static function
  toJson(s:Status):Dynamic {
    var m = Type.enumConstructor(s);
    return switch(s) {
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
    default:
      JSON.encode({ERR:m});
    }
  }
}

/* Command descriptions as enums */

enum LocalCommand {
  LIST;
  REMOVE(pkg:String,ver:String);
  SET(prj:String,ver:String);
  SETUP(path:String);
  CONFIG;
  PACK(path:String);
  DEV(prj:String,dir:String);
  PATH(paths:Array<{project:String,version:String}>);
  RUN(param:String,args:Array<String>);
  TEST(pkg:String);
  INSTALL(prj:String,ver:String);
  UPGRADE;
  NEW(interactive:Global);
  BUILD(prj:String);
}

enum RemoteCommand {
  SEARCH(query:String);
  INFO(project:String);
  USER(email:String);
  REGISTER(email:String,password:String,fullName:String);
  SUBMIT(pkgPath:String);  
  ACCOUNT(cemail:String,cpass:String,nemail:String,npass:String,nname:String);
  LICENSE;
  PROJECTS;
  SERVERINFO;
  REMINDER(email:String);
}

enum CmdContext {
  LOCAL(l:LocalCommand,options:Options);
  REMOTE(r:RemoteCommand,options:Options) ;
}

class Options {
  var switches:Hash<String>;
  
  public function new() {
    switches = new Hash<String>();
  }

  public var repo(getRepo,null):String;

  public function
  gotSome() {
    return Lambda.array(switches).length > 0;
  }
  
  public function
  addSwitch(k:String,v:String) {
    // neko.Lib.println("setting "+k +"="+v);
    switches.set(k,v);
  }

  public function
  getRepo():String {
    return switches.get("-R");
  }

  public function
  getSwitch(s:String):String {
    return switches.get(s);
  }

  public function
  addSwitches(d:Dynamic):Dynamic {
    var n = Reflect.copy(d);
    for(s in switches.keys()) {
      Reflect.setField(n,s,switches.get(s));
    }
    return n;
  }
  
  public function
  flag(s:String):Bool {
    return switches.exists(s);
  }

  public function
  parseSwitches(params:Hash<String>) {
    for (o in params.keys()) {
      if (StringTools.startsWith(o,"-"))
        switches.set(o,params.get(o));
    }
  }
}

/* Configuration Access.
   
  Application interface to config no matter how it's constructed, from hxp or
  json, or xml

  Note, using Array instead of list for json compatibility.

*/

typedef PrjVer = {
  var prj:String;
  var ver:String;
  var op:String;
}

typedef Global = {
  var project:String;
  var authorName:String;
  var authorEmail:String;
  var version:String;
  var comments:String;
  var description:String;
  var tags:Array<String>;
  var website:String;
  var license:String;
  var derivesFrom:Array<String>;
}
  
typedef Build = {
  var attrs:Array<String>;
  var depends:Array<PrjVer>;
  var classPath:Array<String>;
  var target:String;
  var targetFile:String;
  var mainClass:String;
  var options: Array<String>;
}

typedef Pack = {
  var include:Array<String>;
}
  
typedef Repo = {
  var attrs:Array<String>;
  var type:String;
  var location:String;
  var tag:String;
}

  
class Config {
  public static var GLOBAL = "global";
  public static var BUILD = "build";
  public static var FILE = "file";
  public static var PACK = "pack";

  public var data:Dynamic;

  public function new() {}
  
  public function
  globals():Global {
    return Reflect.field(data,GLOBAL);
  }
  
  public function
  build():Build {
    return Reflect.field(data,BUILD);
  }

  public function
  pack():Pack {
    return Reflect.field(data,PACK);
  }
  
  public function
  file():String {
    return Reflect.field(data,FILE);
  }
  
}  

class ConfigJson extends Config {
  public
  function new (j:String) {
    super();
    data =  hxjson2.JSON.decode(j);
  }
}

class Common {
  public static var CONFIG_FILE = "haxelib.json";
  public static var HXP_FILE = "Hxpfile";

  static var alphanum = ~/^[A-Za-z0-9_.-]+$/;

  public static inline function
  slash(d:String) {
    return StringTools.endsWith(d,"/") ? d : (d + "/") ; }

  
  public static function
  safe( name : String ) {
    if( !alphanum.match(name) )
      throw "Invalid parameter : "+name;
    return name.split(".").join(","); }

  public static function
  unsafe( name : String ) {
    return name.split(",").join(".");}

  public static function
  pkgName( lib : String, ver : String ) {
      return safe(lib)+"-"+safe(ver)+".zip";
  }
  
  public static function
  camelCase(s:String) {
    if (s.indexOf("-") != -1) { 
      var
        spl = s.split("-"),
        cc = new StringBuf();

      cc.add(spl[0].toLowerCase());
      for (i in 1 ... spl.length) {
        cc.add(spl[i].charAt(0).toUpperCase() + spl[i].substr(1));
      }
      return cc.toString();
    }
    return s;      
  }  
}
