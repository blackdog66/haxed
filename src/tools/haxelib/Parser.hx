package tools.haxelib;

import tools.haxelib.Config;

using Lambda;
using StringTools;

enum Token {
  PROPERTY(name:String,value:String);
  SECTION(name:String,attrs:String);
}

private
class Fields {
  static var fldMap:Hash<{keyName:String,required:Bool}>;
  
  static public
  function init() {
    if (fldMap != null) return;
    fldMap = new Hash();
    fldMap.set("project",{keyName:"project",required:true});
    fldMap.set("author",{keyName:"author",required:true});
    fldMap.set("author-email",{keyName:"authorEmail",required:true});
    fldMap.set("version",{keyName:"version",required:true});
    fldMap.set("website",{keyName:"website",required:true});
    fldMap.set("description",{keyName:"description",required:true});
    fldMap.set("comments",{keyName:"comments",required:true});
    fldMap.set("tags",{keyName:"tags",required:true});
    fldMap.set("license",{keyName:"license",required:true});
    
    fldMap.set("classpath",{keyName:"classPath",required:false});
    fldMap.set("main-class",{keyName:"mainClass",required:false});
    fldMap.set("target-file",{keyName:"targetFile",required:false});
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

class Hxp {
  public static var GLOBAL = "global";
  static var reSplit = ~/\s/;

  public var file:String;
  public var hbl:Dynamic;

  var properties:Hash<Property>;
  var curSection:String;
  
  public
  function new(f:String) {
    file = f;
    hbl = {};
    properties = new Hash();
    curSection = GLOBAL;
    Reflect.setField(hbl,curSection,{});    
  }

  public
  function setSection(name,attrs) {
    var curSec = Reflect.field(hbl,curSection);
    for (f in properties.keys()) {
      var fld = Fields.key(f);
      var val = parseProperty(fld,properties.get(f));
      Reflect.setField(curSec,fld,val);
      // trace("setting field "+fld+" in "+curSection+" to "+val);
    }

    validate(curSection,curSec);
      
    properties = new Hash();
    var newSection = {};
    curSection = Fields.key(name);
    Reflect.setField(newSection,"attrs",spaceSeparated(attrs));
    //    trace("processing section "+curSection);
    Reflect.setField(hbl,curSection,newSection);
  }

  static function
  validate(sectionName:String,section:Dynamic) {
    if (sectionName == GLOBAL) {
      Fields.required().iter(function(f) {
          if (Reflect.field(section,f) == null) {
            trace(section);
            throw "Key "+f+ " is required in the global section";
          }
      });
    }
  }

  public
  function setProperty(name,values) {
    properties.set(name,values);
  }

  public function
  spaceSeparated(s) {
    return Lambda.map(reSplit.split(s),function(el)
                      { return StringTools.trim(el); }).array();
  }

  function
  parseLicense(val:String) {
    return val.toUpperCase();
  }
  
  function
  parseProperty(fld:String,val:Dynamic):Dynamic {
    var ret:Dynamic;
    
    switch(fld) {
    case "classPath":
      ret = spaceSeparated(val);
    case "tags":
      ret = spaceSeparated(val);
    case "depends":
      ret = parseDepends(val);
    case "license":
      ret = parseLicense(val);
    default:
      ret = StringTools.trim(val);
    }

    return ret;
  }

  function
  parseDepends(str:String):Array<PrjVer> {
    return str.split(",")
      .map(function(el) {
          var
            t = StringTools.trim(el),
            parts = t.split(" "),
            lp = parts.length;
          
          if (lp == 2) return { prj:parts[0],ver:parts[1],op:null };
          if (lp == 3) return { prj:parts[0],ver:parts[2],op:parts[1] };
          return { prj:parts[0],ver:null,op:null };
          
        }).array();
  } 
}

class ConfigHxp extends Config  {
  public
  function new(h:Hxp) {
    super();
    data = h.hbl;
    Reflect.setField(data,"file",Reflect.field(h,"file"));
  }
}

private enum State {
  START;
  KEY;
  VAL;
  SECT;
  SKIP;
  SKIPPASTNL;
}

class Parser {

  static var curChar = 0;
  static var lineNo = 1;
  static var state = START;
  static var retState = START;
  
  static inline function isWhite(c:String) {
    return c == " " || c == "\t"  || c == "\r" || c == "\n";
  }

  static inline function isNL(c:String) {
    return c == "\n";
  }
  
  static inline function peek(s:String) {
    return s.charAt(curChar+1);
  }

  static inline function tidy(sb:StringBuf) {
    return sb.toString().trim();
  }

  static function nextState(newState:State,?rs:State) {
    if (rs != null) {
      if (newState != SKIP && newState != SKIPTONL) throw "retState only with skips";
      retState = rs;
    }
    
    state = newState;
    //    curChar--;
  }

  public static function tokens(hf:String) {
    curChar = 0;
    
    var
      len = hf.length,
      toks = new List<Token>(),
      curKey = null,
      curVal = null,
      c = "",
      lineStart = 0,
      keyIndent=0,
      valIndent=0;    

    do {
      c = hf.charAt(curChar);

      if (c == "\t")
        throw "I don't like tabs! line:"+ lineNo + ",col:"+(curChar-lineStart); 
      
      if (c == "#") {
        trace("skipped comment at "+lineNo);
        nextState(SKIPPASTNL,START);
      }
      
      if (isNL(c)) {
        trace("at line "+lineNo+", "+hf.substr(lineStart,(curChar-lineStart)));
        lineStart = curChar + 1 ;
        lineNo++;
      }
      
      switch(state) {
      case START:
        if  (!isWhite(c)) {
          curKey = new StringBuf();
          curKey.add(c);
          
          keyIndent = curChar - lineStart;
          nextState(KEY);
        } else {
          nextState(SKIP,START);
        }
      case KEY:
        if (!isWhite(c))
          curKey.add(c);
        else {
          var k = tidy(curKey);
          if (k.endsWith(":")) {
            curVal = new StringBuf();
            nextState(SKIP,VAL);
          } else {
            if (isNL(c)) {
              var ss = SECTION(tidy(curKey).substr(0,-1),"");
              toks.add(ss);
              //        trace(ss);
              nextState(START);
            } else {
              nextState(SECT);
              curVal = new StringBuf();
            }
          }
        }
      case VAL:
        if (!isNL(c))
          curVal.add(c); 
        else {
          var ps = PROPERTY(tidy(curKey).substr(0,-1),tidy(curVal));
          toks.add(ps);
          nextState(START);
        }
      case SECT:
        if (!isNL(c))
          curVal.add(c);
        else {
          var ss = SECTION(tidy(curKey),tidy(curVal));
          toks.add(ss);
          nextState(START);
        }
      case SKIP:
        if(!isWhite(c)) {
          nextState(retState);
          curChar--;
        }
      case SKIPPASTNL:
        if (isNL(c)) {
          nextState(retState);
        }
      }
      
      curChar++;      

      if (lineNo > 30) break;
    } while (curChar < len);       

    toks.add(SECTION("end","")); // force processing of final user section
    trace(toks);
    return toks;
  }

  static
  function parse(file:String):Hxp {
    var contents = neko.io.File.getContent(file);
    return tokens(contents).fold(function(token,hbl:Hxp) {
        switch(token) {
        case PROPERTY(name,val):
          hbl.setProperty(name,val);
        case SECTION(name,attrs):
          hbl.setSection(name,attrs);
        }
        return hbl;
      },new Hxp(file));    
  }
  
  
  public static
  function process(file:String):Hxp {
    Fields.init();
    return parse(file);
  }
  
  public static
  function getConfig(hbl:Hxp):Config {
    return new ConfigHxp(hbl);
  }

}


