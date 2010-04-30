package haxed;

import bdog.JSON;

/*
  Used across neko, php and js
*/

/*
  Data structures used in marshalling between targets

*/

interface ServerStore {
  function cleanup():Void;
  function submit(password:String):Status;
  function register(email:String,pass:String,fullName:String):Status;
  function user(email:String):Status;
  function topTags(n:Int):Status;
  function info(prj:String,options:Options):Status;
  function search(query:String,opts:Options):Status;
  function license():Status;
  function account(cemail:String,cpass:String,nemail:String,npass:String,
                            nName:String):Status;
  function projects(options:Options):Status;
  function reminder(email:String):Status;
}


typedef UserInfo = {
  var fullname : String;
  var email : String;
  var projects : Array<{name:String}>;
}

typedef VersionInfo = {
  #if GITSTORE
  var commit:String;
  var version:String;
  #end
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
  var tags: Array<{tag:String}>;
}

typedef TopTagInfo = {
  var tags:Array<{count:Int,tag:String}>;
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
  OK_SEARCH(si:Array<ProjectInfo>);
  OK_LICENSES(lics:Array<LicenseSpec>);
  OK_REGISTER;
  OK_SUBMIT;
  OK_ACCOUNT;
  OK_SERVERINFO(si:ServerInfo);
  OK_REMINDER;
  OK_TOPTAGS(tt:TopTagInfo);
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

/* Command descriptions as enums */

enum LocalCommand {
  LIST;
  REMOVE(pkg:String,ver:String);
  SET(prj:String,ver:String);
  SETUP(path:String);
  CONFIG;
  PACK(path:String);
  DEV(prj:String,dir:String);
  PATH(paths:Array<PrjVer>);
  RUN(param:String,args:Array<String>);
  TEST(pkg:String);
  INSTALL(prj:String,ver:String);
  UPGRADE;
  NEW(interactive:Global);
  BUILD(config:Config,target:String);
  TASK(config:Config,task:Task,prms:Array<Dynamic>);
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
  TOPTAGS(topn:Int);
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
  removeSwitch(k:String) {
    switches.remove(k);
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
  var name:String;
  var author:String;
  var authorEmail:String;
  var version:String;
  var comments:String;
  var description:String;
  var tags:Array<String>;
  var website:String;
  var license:String;
  var derivesFrom:Array<String>;
  var depends:Array<PrjVer>;
}
  
typedef Build = {
  var name:String;
  var depends:Array<PrjVer>;
  var classPath:Array<String>;
  var target:String;
  var targetFile:String;
  var mainClass:String;
  var options: Array<String>;
  var preTask:Array<String>;
  var postTask:Array<String>;
}

typedef Pack = {
  var include:Array<String>;
  var exclude:Array<String>;
}

typedef Task = { > Build,
  var params:Array<Dynamic>;
}

typedef Repo = {
  var attrs:Array<String>;
  var type:String;
  var location:String;
  var tag:String;
}
  
class Config {
  public static var GLOBAL = "project";
  public static var BUILD = "build";
  public static var FILE = "file";
  public static var PACK = "pack";
  public static var TASK = "task";

  public var data:Dynamic;

  public function new(d:Dynamic) {
    data = d;
  }
  
  public inline function
  globals():Global {
    return Reflect.field(data,GLOBAL);
  }
  
  public inline function
  build():Array<Build> {
    return Reflect.field(data,BUILD);
  }

  public inline function
  pack():Pack {
    return Reflect.field(data,PACK);
  }

  public inline function
  tasks():Array<Task> {
    return Reflect.field(data,TASK);
  }
  
  public inline function
  file():String {
    return globals().name + "." + Common.HXP_EXT;
  }

  public function
  section(n:String) {
    var s = Reflect.field(data,n);
    if (s == null) trace("Warning section:"+n+" does not exist!");
    return s;
  }

  public function
  getTask(n:String) {
    for (t in tasks())
      if (t.name == n)
        return t;
    return null;
  }

  public function
  getDepends(?build:String) {
    var
      deps = [],
      gd = globals().depends;
     
    if (gd != null)
      deps = deps.concat(gd);

    if (build != null) {
      var bd = getBuild(build).depends;
      if (bd != null)
        deps = deps.concat(bd);
    }

    return deps;
  }
  
  public function
  getBuild(?name:String) {
    var builds = build();
    if (builds != null) {
      if (name != null) {
        for (b in build()) {
          if (b.name == name)
            return b;
        }
      }
      return builds[0];
    }
    return null;
  }
}

class ConfigJson extends Config {
  public
  function new (j:String) {
    super(JSON.decode(j));
  }
}

class Common {
  public static var CONFIG_FILE = "haxed.json";
  public static var HXP_EXT = "haxed";
  public static var HXP_FILE = "YOUR_PROJECT_NAME." + HXP_EXT;
  public static var HXP_TEMPLATE = "template." + HXP_EXT;
  public static var HAXED_DIR = "./.haxed/";
  public static var TASK_DIR = HAXED_DIR+"tasks/";

  
  static var alphanum = ~/^[A-Za-z0-9_.-]+$/;
  
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
