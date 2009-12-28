package tools.haxelib;

/*
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
  var synopsis:String;
  var description:String;
  var tags:Array<String>;
  var website:String;
  var license:String;
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