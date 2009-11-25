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

  
  interface Config {
    function globals():Global ;
    function library():Library;
    function executable(?id:String):Executable;
    function repo(?id:String):Repo;
    function file():String;
  }  



class ConfigJson implements Config {
  var json:Dynamic;
  
  public
  function new (j:String) {
    json = hxjson2.JSON.decode(j);
  }

  public 
  function globals():Global {
    return Reflect.field(json.hbl,"global");
  }

  public
  function library():Library {
    return Reflect.field(json.hbl,"library");
  }

  public 
  function executable(?id:String):Executable {
    return Reflect.field(json.hbl,"executable");
  }

  public 
  function repo(?id:String):Repo {
    return Reflect.field(json.hbl,"sourceRepo");
  }

  public 
  function file():String {
    return json.hbl.file;
  }
}