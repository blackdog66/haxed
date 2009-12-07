package tools.haxelib;

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

