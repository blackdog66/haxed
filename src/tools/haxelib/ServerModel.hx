package tools.haxelib;


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

enum Command {
  SEARCH(query:String);
  INFO(project:String);
  USER(email:String);
  REGISTER(email:String,password:String,fullName:String);
  SUBMIT(pkgPath:String);
  DEV(prj:String,dir:String);
}

interface Repository {
  public function cleanup():Void;
  public function submit():Dynamic;
  public function register(email:String,password:String,fullName:String):Dynamic;
  public function user(email:String):UserInfo;
  
}
