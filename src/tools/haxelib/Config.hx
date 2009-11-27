package tools.haxelib;

/*
  Application interface to config no matter how it's constructed, from hbl or
  json, or xml

  Note, using Array instead of list for json compatibility.

*/

typedef Global = {
  var name:String;
  var authorEmail:String;
  var version:String;
  var synopsis:String;
  var category:String;
  var tags:Array<String>;
}
  
typedef Library = {
  var attrs:Array<String>;
  var depends:Array<String>;
  var sourceDirs:Array<String>;
  var buildable:Bool;
  var options: Array<String>;
}

typedef Executable = {  > Library,
  var mainIs:String;
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
  function library():Library {
    return Reflect.field(data,"library");
  }
  
  public 
  function executable(?id:String):Executable {
    return Reflect.field(data,"executable");
  }
  
  public 
  function repo(?id:String):Repo {
    return Reflect.field(data,"sourceRepo");
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