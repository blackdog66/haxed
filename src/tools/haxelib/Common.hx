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
  OK;
  OK_USER(ui:UserInfo);
  OK_PROJECT(pi:ProjectInfo);
  OK_PROJECTS(prj:Array<ProjectInfo>);
  OK_SEARCH(si:SearchInfo);
  OK_LICENSES(lics:Array<{name:String,url:String}>);
  ERR_LICENSE(info:LicenseErr);
  ERR_UNKNOWN;
  ERR_PASSWORD;
  ERR_DEVELOPER;
  ERR_HAXELIBJSON;
  ERR_USER(email:String);
  ERR_REGISTERED;
  ERR_PROJECTNOTFOUND;
  
}

class Marshall {
  public static function
  getStatus(d:Dynamic):Status {
    var e;
    if (Reflect.field(d,"PAYLOAD") != null)
      e = Type.createEnum(Status,d.ERR,[d.PAYLOAD]);
    else
      e = Type.createEnum(Status,d.ERR);
    return e;
  }
}

class Common {
  static var alphanum = ~/^[A-Za-z0-9_.-]+$/;

  public static inline
  function slash(d:String) {
    return StringTools.endsWith(d,"/") ? d : (d + "/") ;
  }

  public static
  function safe( name : String ) {
    if( !alphanum.match(name) )
      throw "Invalid parameter : "+name;
    return name.split(".").join(",");
  }

  public static
  function unsafe( name : String ) {
    return name.split(",").join(".");
  }

  public static
  function pkgName( lib : String, ver : String ) {
      return safe(lib)+"-"+safe(ver)+".zip";
  }

}