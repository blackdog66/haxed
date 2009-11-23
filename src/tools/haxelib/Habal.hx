package tools.haxelib;

using Lambda;

enum Token {
  PROPERTY(name:String,value:String,info:Info);
  SECTION(name:String,attrs:String,info:Info);
  UNKNOWN(info:Info);
}

typedef Global = {
  var name:String;
  var version:String;
  var synopsis:String;
  var category:String;
  var tags:List<String>;
}

typedef Library = {
  var attrs:List<String>;
  var depends:List<String>;
  var sourceDirs:List<String>;
  var buildable:Bool;
  var options: List<String>;
}

typedef Executable = {  > Library,
  var mainIs:String;
}

typedef Repo = {
  var attrs:List<String>;
  var type:String;
  var location:String;
  var tag:String;
}


private
class Fields {
  static var fldMap:Hash<{keyName:String,required:Bool}>;
  
  static public
  function init() {
    if (fldMap != null) return;
    fldMap = new Hash();
    fldMap.set("name",{keyName:"name",required:true});
    fldMap.set("author-email",{keyName:"authorEmail",required:true});
    fldMap.set("version",{keyName:"version",required:true});
    fldMap.set("project-url",{keyName:"projectUrl",required:true});
    fldMap.set("description",{keyName:"description",required:true});
    fldMap.set("tags",{keyName:"tags",required:true});
    fldMap.set("license",{keyName:"license",required:true});
    
    fldMap.set("haxe-source-dirs",{keyName:"sourceDirs",required:false});
    fldMap.set("main-is",{keyName:"mainIs",required:false});
    fldMap.set("source-repository",{keyName:"sourceRepo",required:false});
    fldMap.set("haxelib-version",{keyName:"haxelibVersion",required:false});    
  }

  static public
  function key(name:String) {
    return fldMap.exists(name) ? fldMap.get(name).keyName : name;
  }

  static public
  function required():List<String> {
    return fldMap
      .filter(function(val) { return val.required == true ;})
      .map(function(val) { return val.keyName; });
  }

}


typedef Property = String;

class Habal {
  public var file:String;
  var properties:Hash<Property>;
  var curSection:String;
  var hbl:Dynamic;
  
  
  public
  function new(f:String) {
    file = f;
    hbl = {};
    properties = new Hash();
    curSection = "global";
    Reflect.setField(hbl,curSection,{});    
  }

  public
  function setSection(name,attrs,info) {
    if (info.indent == 0) {
      
      for (f in properties.keys()) {
        var fld = Fields.key(f);
        var val = parseProperty(fld,properties.get(f));
        Reflect.setField(Reflect.field(hbl,curSection),fld,val);
        //        trace("setting field "+fld+" in "+curSection+" to "+val);
      }
      
      properties = new Hash();
      var newSection = {};
      curSection = Fields.key(name);
      Reflect.setField(newSection,"attrs",spaceSeparated(attrs));
      //trace("processing section "+curSection);
      Reflect.setField(hbl,curSection,newSection);
    } else {
      trace("indent = "+info.indent+" and trying to setSection()");
    }
  }
  
  public
  function setProperty(name,values,info) {
    if (info.indent == 0)
      curSection = "global";

    properties.set(name,values);
  }

  public
  function spaceSeparated(s) {
    return Lambda.map(s.split(" "),function(el) { return StringTools.trim(el); });
  }
  
  function parseProperty(fld:String,val:Dynamic):Dynamic {
    return switch(fld) {
    case "sourceDirs":
      spaceSeparated(val);
    case "tags":
      spaceSeparated(val);
    default:
      val;
    }
    
  }
  
  public
  function globals():Global {
    return Reflect.field(hbl,"global");
  }

  public
  function library():Library {
    return Reflect.field(hbl,"library");
  }

  public
  function executable():Executable {
    return Reflect.field(hbl,"executable");
  }

  public
  function repo():Repo {
    return Reflect.field(hbl,"sourceRepo");
  }  
}

typedef Info = {
  var lineNo:Int;
  var indent:Int;
}
  
class HblTools {

  static var reProp = ~/^([A-Z0-9\-]+):\s+(.*)/i ;
  static var reComp = ~/^([A-Z0-9\-]+)\s?(.*)/i;
  static var reSpaces = ~/^(\s+)(.*)$/;
  
  static
  function tokens(hf:String) {
    var lineNo = -1;
    var baseIndent = -1;
    // make sure there's a final token, so the final section properties are processed
    hf += "\nend"; 
    return hf
      .split("\n")
      .filter(function(line) { return StringTools.trim(line).length > 0; })
      .map(function(line) {
          lineNo++;
          var indent = 0;
          if (reSpaces.match(line)) {
            var idl = reSpaces.matched(1).length;
            // set the first indent to be the multiple for following indents ...
            if (baseIndent == -1) baseIndent = idl;
            if (baseIndent % idl != 0)
              throw "Indentation error line "+lineNo+","+baseIndent+"/"+idl;

            indent = Std.int(baseIndent / idl);
            
            // skip over the processed spaces ...
            line = line.substr(idl);
          }
          
          var info = {lineNo:lineNo,indent:indent};
          if (reProp.match(line)) {
            var lc = reProp.matched(1).toLowerCase();
            return PROPERTY(lc,reProp.matched(2),info) ;
          } else {
            if (reComp.match(line)) {
              var
                name = reComp.matched(1).toLowerCase(),
                attrs = reComp.matched(2);
              return SECTION(name,attrs,info);
            } else {
              return UNKNOWN(info);
            }
          }
        });
  }

  static
  function parse(file:String):Habal {
    var contents = neko.io.File.getContent(file);
    return tokens(contents).fold(function(token,hbl:Habal) {
        switch(token) {
         case UNKNOWN(info):
           throw "Unkown token "+info;
        case PROPERTY(name,val,info):
          hbl.setProperty(name,val,info);
        case SECTION(name,attrs,info):
          hbl.setSection(name,attrs,info);
        }
        return hbl;
      },new Habal(file));
  }

  
  public static
  function process(file:String):Habal {
    Fields.init();
    
    var
      hbl = parse(file),
      glbs = hbl.globals();

    for (r in Fields.required()) {
      if(Reflect.field(glbs,r) == null)
        throw "Field "+r+" must be present";
    }

    return hbl;
  }

}


