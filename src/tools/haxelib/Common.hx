package tools.haxelib;

import hxjson2.JSON;

typedef UserInfo = {
	var fullname : String;
	var email : String;
	var projects : Array<String>;
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

typedef XmlInfo = {
	var project : String;
	var website : String;
	var desc : String;
	var license : String;
	var version : String;
	var versionComments : String;
	var developers : List<String>;
	var dependencies : List<{ project : String, version : String }>;
}

enum Status {
  OK;
  OK_USER(ui:UserInfo);
  OK_PROJECT(pi:ProjectInfo);
  ERR_UNKNOWN;
  ERR_PASSWORD;
  ERR_DEVELOPER;
  ERR_HAXELIBJSON;
  ERR_USER(email:String);
  ERR_REGISTERED;
  ERR_PROJECTNOTFOUND;
}

