package tools.haxelib;

/*
  Used across neko, php and js
*/

import hxjson2.JSON;

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

typedef LicenseErr = {
  var licenses:Array<{name:String,url:String}>;
  var given:String;
}

enum Status {
  OK_USER(ui:UserInfo);
  OK_PROJECT(pi:ProjectInfo);
  OK_PROJECTS(prj:Array<ProjectInfo>);
  OK_SEARCH(si:SearchInfo);
  OK_LICENSES(lics:Array<{name:String,url:String}>);
  OK_REGISTER;
  OK_SUBMIT;
  OK_ACCOUNT;
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
    default:
      JSON.encode({ERR:m});
    }
  }
}

class Common {
  static var alphanum = ~/^[A-Za-z0-9_.-]+$/;
  static var emailRe = ~/[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z][A-Z][A-Z]?/i;

  public static inline function slash(d:String) {
    return StringTools.endsWith(d,"/") ? d : (d + "/") ; }

  public static function safe( name : String ) {
    if( !alphanum.match(name) )
      throw "Invalid parameter : "+name;
    return name.split(".").join(","); }

  public static function unsafe( name : String ) {
    return name.split(",").join(".");}

  public static function pkgName( lib : String, ver : String ) {
      return safe(lib)+"-"+safe(ver)+".zip"; }

  public static function validEmail(v:String) {
    return (emailRe.match(v)) ? null : "must be a valid email address"; }

  public static function optionalEmail(v:String) {
    if (v.length > 0) return validEmail(v);
    return null; }
  
  public static function validPW(v) {
    return (v.length >= 5) ? null : "must be >= 5 characters"; }

  public static function optionalPW(v) {
    if (v.length > 0) return validPW(v);
    return null; }

  public static function validUrl(v) {
    var r = ~/^(http:\/\/)?([^:\/]+)(:[0-9]+)?\/?(.*)$/;
    return (r.match(v)) ? null : "invalid http url"; }

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

enum LocalCommand {
  LIST;
  REMOVE(pkg:String,ver:String);
  SET(prj:String,ver:String);
  SETUP(path:String);
  CONFIG;
  PACK(path:String);
  DEV(prj:String,dir:String);
  PATH(paths:Array<{project:String,version:String}>);
  RUN(param:String);
  TEST(pkg:String);
  INSTALL(prj:String,ver:String);
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
}

enum CmdContext {
  LOCAL(l:LocalCommand,options:Options);
  REMOTE(r:RemoteCommand,options:Options) ;
}
