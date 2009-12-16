package tools.haxelib;

/*
  Application interface to config no matter how it's constructed, from hbl or
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
  var classPaths:Array<String>;
  var target:String;
  var targetFile:String;
  var mainClass:String;
  var options: Array<String>;
}

typedef Repo = {
  var attrs:Array<String>;
  var type:String;
  var location:String;
  var tag:String;
}

  
class Config {
  public var data:Dynamic;

  public function new() {
  }
  
  public 
  function globals():Global {
    return Reflect.field(data,"global");
  }
  
  public
  function build():Build {
    return Reflect.field(data,"build");
  }
  
  public 
  function file():String {
    return Reflect.field(data,"file");
  }
  
}  


class ConfigJson extends Config {
  public
  function new (j:String) {
    super();
    data =  hxjson2.JSON.decode(j);
  }
}