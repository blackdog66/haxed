package haxed;

import haxed.Common;
import haxed.SyntaxTools;

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
}

class HxpParser {

  var curProp:String;
  var multiIndent:Int;
  var multiVal:StringBuf;
  var keyIndent:Int;
  var hxp:Hxp;
  
  static function
  getTokenizer(r) {
    var
      tk = new Tokenizer<TToks>(r,LINE);    
    
    tk.match(~/\t/,function(re) { return TTab; })
      .match(~/#/,function(re) {return TComment; },Discard)
      .match(~/^\s+(?=\S)/,function(re) {
        return TIndent(re.matchedPos().len);})
      .match(~/^\s+\n/,function (re) { return TWhite; })
      .match(~/^---.*?\n/,function(re) { return TDoc; })
      .match(~/^([a-zA-Z-]+):(?=\s)/,function(re) {
          return TKey(re.matched(1)); })
      .match(~/^([^#]+?)\n/,function(re) {
            return TString(re.matched(1));
        });
     
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

  public function
  parse(f:String) {
    var
      me = this,
      tk = getTokenizer(new ChunkedFile(f)),
      p = new Parser<State,TToks>(SDoc,tk),
      curProp = null,
      Key = TKey(""),
      Str = TString(""),
      Indent = TIndent(0),
      Error = SError("");

    hxp = new Hxp(f);
      
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

  public static function
  process(file:String):Hxp {

    var
      p = new HxpParser(),
      h = p.parse(file);

    Validate.forSection(Config.GLOBAL)
      .add("name",true,Validate.name)
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

    
    Validate.applyAllTo(h);

    return h;
  }
  
  public static function
  getConfig(hbl:Hxp):Config {
    return new ConfigHxp(hbl);
  }

}

class Hxp {

  public var file:String;
  public var hbl:Dynamic;
  var curSection:Dynamic;
  var builds:Array<Build>;
  var tasks:Array<Task>;
  
  public function new(f:String) {
    file = f;
    hbl = {};
    curSection = {};
    builds = new Array<Build>();
    tasks = new Array<Task>();
  }

  public function
  setSection(name) {
    curSection = {};
    if (name == Config.BUILD) {
      if (Reflect.field(hbl,Config.BUILD) == null)
        Reflect.setField(hbl,Config.BUILD,builds);
      builds.push(curSection);
    } else if (name == Config.TASK) {
      if (Reflect.field(hbl,Config.TASK) == null)
        Reflect.setField(hbl,Config.TASK,tasks);
      tasks.push(curSection);
    } else
      Reflect.setField(hbl,Common.camelCase(name),curSection);
  }
  
  public function
  setProperty(name,values) {
    var fld = Common.camelCase(name);
    Reflect.setField(curSection,fld,values);
  }

  function
  syntax(msg,info:Info) {
    neko.Lib.println("At line "+info.line+" col "+info.col+": "+msg);
    neko.Sys.exit(1);
  }
}


class ConfigHxp extends Config  {
  public
  function new(h:Hxp) {
    super();
    data = h.hbl;
    Reflect.setField(data,Config.FILE,Reflect.field(h,Config.FILE));
  }
}

