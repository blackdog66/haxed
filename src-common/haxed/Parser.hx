package haxed;

import haxed.Common;

import bdog.Reader;
import bdog.ChunkedFile;
import bdog.Tokenizer;
import bdog.SMachine;
import bdog.Os;

using haxed.Validate;
using Lambda;
using StringTools;

private enum TToks {
  TDoc;
  TIndent(abs:Int);
  TWhite;
  TString(s:String);
  TKey(k:String);
  TComment;
  TTab;
  THereDoc;
  THereEnd;
}

private enum State {
  SDoc;
  SSection;
  SKey;
  SProp;
  SVal;
  SMulti;
  SIndent;
  SError(e:String);
  SHereDoc;
  SHereNext;
}

class Parser {

  var curProp:String;
  var multiIndent:Int;
  var multiVal:StringBuf;
  var keyIndent:Int;
  var hxp:Hxp;
  static var parser = new hscript.Parser();
  static var interp = new hscript.Interp();
  static var reScript = ~/(.*?)::$/s;
  
  static function
  script(v:String,c:Config) {

    var imports = c.section("import");
    if (imports != null) {
      var classes = Reflect.field(imports,"classes");
      if (classes != null) {
        var cl:Array<String> = Validate.toArray(classes);
        for (c in cl) {
          var
            t = c.split("."),
            kls ;
          if (t.length == 1)
            kls = t[0];
          else
            kls = t.pop();
          
          interp.variables.set(kls,Type.resolveClass(c));
        }
      }
    }
    
    if (reScript.match(v)) {
      try {
        var
          s = reScript.matched(1),
          script = parser.parseString(s),
          result;
        
        result = interp.execute(script);

        #if TRACESTATES
        trace("executed "+s+" result is "+result);
        #end
        
        return result;
        
      } catch(ex:Dynamic) {        
        throw "Script Exception:"+ex+"\n in script\n"+v;
      }
    } 
    
    return v;
  }

  static function
  reference(v:String,c:Config) {
    var
      parts = v.substr(0,v.length-2).trim().split("."),
      sectionName = parts[0],
      val = switch(sectionName) {
      case "build": Reflect.field(c.getBuild(parts[1]),parts[2]);
      case "task": Reflect.field(c.getTask(parts[1]),parts[2]);
      default: Reflect.field(c.section(sectionName),parts[1]);
      }
    
    if (val == null)
      throw "Can't find "+parts+" in reference "+v;
    
    return val;
  }
  
  static function
  getTokenizer(r) {
    var
      tk = new Tokenizer<TToks>(r,LINE);    
    
    tk.match(~/\t/,function(re) { return TTab; })
      .match(~/#/,function(re) {return TComment; },Discard)
      .match(~/^\s+(?=\S)/,function(re) {
        return TIndent(re.matchedPos().len);})
      .match(~/^\s+/,function (re) { return TWhite; })
      .match(~/^---.*?\n/,function(re) { return TDoc; })
      .match(~/^([a-zA-Z-]+):(?=\s)/,function(re) {
          return TKey(re.matched(1)); })
      .match(~/^::/,function(re) {return THereDoc; })
      .match(~/^(.+?)(?=:{2}|\n)/,function(re) {
          return TString(re.matched(1));
        })
      .group("script")
      .match(~/::/,function(re) { return THereEnd;})
      .use("default");
     
    return tk; 
  }

  public function new() {}

  function newProperty(p) {
    curProp = p;
    multiVal = new StringBuf();
    multiIndent = -1;
  }

  function saveProperty() {
    hxp.setProperty(curProp,multiVal.toString().trim());
  }

  public static function
  fromString(s:String,asHaxed=true):Config {
    var
      p = new Parser(),
      hxp = p.fromReader(new StringReader(s));

    return (asHaxed) ? validate(hxp) : new Config(hxp.hbl);
  }

  public static function
  fromFile(f:String,asHaxed=true) {
    var
      p = new Parser(),
      hxp = p.fromReader(new ChunkedFile(f));
    
    return (asHaxed) ? validate(hxp) : new Config(hxp.hbl);
  }
  
  public function
  fromReader(reader:Reader) {
    var
      me = this,
      tk = getTokenizer(reader),
      p = new SMachine<State,TToks>(SDoc,tk),
      curProp = null,
      Key = TKey(""),
      Str = TString(""),
      Indent = TIndent(0),
      Error = SError("");

    hxp = new Hxp();
    var config = new Config(hxp.hbl);
          
    p.define([
     ONTRAN(SDoc,TDoc,function() {
         return SSection;
       }),
       
     ONTRAN(SSection,Key,function(k:String) {
         me.hxp.setSection(k);
         return SIndent;
       }),
     
     ONTRAN(SIndent,Indent,function(size:Int) {
         me.keyIndent = size;
         return SProp;
       }),
     
     ONTRAN(SProp,Key,function(k:String) {
         var pos = tk.fromBOL();
         if (pos != me.keyIndent) {
           return SError("bad indent for key \""+k+"\", expecting "+me.keyIndent+" got "+pos);
         }

         me.newProperty(k);
         return SVal;
       }),
     
     ONTRAN(SVal,TWhite,function() {
         return SError("key "+curProp+" value is empty");
       }),
     
     ONTRAN(SVal,Indent,function(size:Int) {          
         me.multiIndent = tk.fromBOL() + size;
         return SMulti;  
       }),

     ONTRAN(SMulti,THereDoc,function() {
         tk.mark();
         tk.use("script");
         return SHereDoc;
       }),

     ONTRAN(SHereDoc,THereEnd,function() {
         var
           output = tk.yank(),
           prefix = output.charAt(0),
           result = switch(prefix) {
	         case "=": script(output.substr(1),config);
	         case "!": try { Os.process(output.trim().substr(1,output.length-3)); }
            			catch (ex:Dynamic) { ex; }
         	default:reference(output,config);
         	}

         me.multiVal.add(result);
         
         tk.use("default");
         return SHereNext;
       }),

     ONTRAN(SHereNext,[Indent,TWhite,TDoc],function(t:TToks) {
         me.saveProperty();
           return switch(t) {
           case TIndent(size):
             switch(size) {
             case me.keyIndent:
               SProp;
               
             default:
               SError("After script - bad indent, expecting "+me.keyIndent+" got "+size);
             }           
         case TDoc:
           SSection;
           
           default:
             SMulti;
           }           
       }),
            
     ONTRAN(SMulti,Str,function(s:String) {
         var pos = tk.fromBOL();
         return switch(pos) {
         case me.multiIndent:
           me.multiVal.add("\n"+s);
           SMulti;
         case me.keyIndent:
           me.saveProperty();
           SProp;        
         default:
            if (tk.fromBOL() == 0 && s != "---")
              SError("Expecting ---");
            else
              SError("bad indent, expecting "+me.multiIndent+" got "+pos);
         }
       }),
       
     ONTRAN(SMulti,[Indent,TWhite,TDoc],function(t:TToks) {
         return switch(t) {
         case TIndent(size):
           switch(size) {
           case me.keyIndent:
             me.saveProperty();
             SProp;
             
           case me.multiIndent:
             SMulti;
      
           default:
             SError("bad indent, expecting "+me.keyIndent+" or "+me.multiIndent+" got "+size);
           }           
         case TDoc:
           me.saveProperty();
           SSection;
         
         default:
           SMulti;
         }          
       }),

     ONSTATE(Error,function(e:String) {
         p.syntax(e);
       })
     
    ]);

    p.allow([TWhite,TComment]);

    p.tokenString(function(e:TToks) {
        return switch(e) {
        case TKey(k): k;
        case TDoc: "---";
        default:
          Std.string(e);
        }
      });
    
    p.parse();
    saveProperty();
    
    return hxp;
  }

  static function
  validate(hxp):Config {

    Validate.forSection(Config.GLOBAL)
      .add("author",true)
      .add("author-email",true,Validate.email)
      .add("version",true)
      .add("website",true,Validate.url)
      .add("description",true)
      .add("comments",true)
      .add("tags",false,Validate.toArray)
      .add("license",true,function(v) { return v.toUpperCase() ;} );
    
    Validate.forSection(Config.BUILD)
      .add("name",false,Validate.name)
      .add("depends",false,Validate.depends)
      .add("class-path",true,Validate.directories)
      .add("main-class",true)
      .add("target",true,Validate.target)
      .add("target-file",true)
      .add("options",false,Validate.splitOnComma)
      .add("pre-task",false,Validate.toArray)
      .add("post-task",false,Validate.toArray);

    Validate.forSection(Config.PACK)
      .add("include",false,Validate.directories)
      .add("exclude",false,Validate.directories);

    Validate.forSection(Config.TASK)
      .add("name",true,Validate.name)
      .add("main-class",true,Validate.name)
      .add("class-path",false,Validate.directories)
      .add("params",false,Validate.splitOnNewline)
      .add("depends",false,Validate.depends);
    
    Validate.applyAllTo(hxp);

    return new Config(hxp.hbl);
  }

  public static function
  configuration(s:String):Config {
    return fromFile(s);
  }
}

class Hxp {
  public var hbl:Dynamic;
  var curSection:Dynamic;
  var builds:Array<Build>;
  var tasks:Array<Task>;
  public var sectionOrder:Array<String>;
  var sectionType:String;
  
  public function new() {
    hbl = {};
    curSection = {};
    builds = new Array<Build>();
    tasks = new Array<Task>();
    sectionOrder = new Array<String>();
    sectionType = "";
  }

  public function
  setSection(name) {
    curSection = {};
    switch(name) {
    case Config.BUILD:
      if (Reflect.field(hbl,Config.BUILD) == null)
        Reflect.setField(hbl,Config.BUILD,builds);
      builds.push(curSection);
      sectionType = Config.BUILD;
    case Config.TASK:
      if (Reflect.field(hbl,Config.TASK) == null)
        Reflect.setField(hbl,Config.TASK,tasks);
      tasks.push(curSection);
      sectionType = Config.TASK;
    default:
      Reflect.setField(hbl,Common.camelCase(name),curSection);
      sectionOrder.push(name);
      sectionType = "";
    }
  }
  
  public function
  setProperty(name,values) {
    var fld = Common.camelCase(name);
    Reflect.setField(curSection,fld,values);
    if (name == "name") {
      if (sectionType == Config.BUILD || sectionType == Config.TASK) {   
        sectionOrder.push(sectionType+"___"+values);
      }
    }
  }

}

