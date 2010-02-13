package haxed;

import haxed.Common;
using haxed.Validate;
using Lambda;
using StringTools;
import haxed.Tokenizer;
import haxed.ChunkedFile;

enum Token {
  PROPERTY(name:String,value:String,info:Info);
  SECTION(name:String,info:Info);
  //  ENDSECTION(info:Info);
}

private enum State {
  START_KEY_OR_DOCUMENT;
  START_DOCUMENT;
  START_KEY;
  CAPTURE_KEY;
  START_VAL;
  CAPTURE_VAL;
  MULTI_LINE;
}


class Parser {

  static inline function sectionTidy(sb:StringBuf) {
    return sb.toString().substr(0,-1).trim();
  }

  static inline function tidy(sb:StringBuf) {
    return sb.toString().trim();
  }
  
  public static function
  makeProperty(tk,ck:StringBuf,cv:StringBuf) {
    var
      k = tidy(ck),
      v = tidy(cv);

    if (k.length == 0) tk.syntax("Need a key");
    if (v.length == 0) tk.syntax("Need a value for "+k);
    
    return PROPERTY(k.substr(0,k.length-1),v,tk.info());
  }
  
  public static function
  tokens(hf:Reader) {
    var
      tk = new Tokenizer<State>(hf,START_KEY_OR_DOCUMENT),
      context = new Array<State>(),
      curKey = null,
      curVal = null,
      c = "",
      indent = 0,
      keyIndent=0,
      valIndent=0,
      capturingVal = false,
      docCount = 0,
      toks = new List<Token>();
    
    while ((c = tk.nextChar()) != "EOF") {

      if (c == "\t") tk.syntax("I don't like tabs!");
      
      if (c == "#") {
        tk.skipToNL(tk.state());
        continue;
      }
      
      switch(tk.state()) {
        
      case START_KEY_OR_DOCUMENT:
        if (tk.isAlpha(c)) {
          if (c == "-") {
            docCount++;
            tk.nextState(START_DOCUMENT);
          } else {
            tk.nextState(START_KEY,true);
          }
        }
                   
      case START_DOCUMENT:
        if (c == "-") {
          docCount++;
          if (docCount == 3) {
            docCount = 0;
            context.push(START_DOCUMENT);
            tk.nextState(START_KEY);
          }
        } else
          tk.syntax("expecting 3 - tokens");

      case START_KEY:
        if (tk.isAlpha(c)) {
          curKey = new StringBuf();
          curKey.add(c);
          
          keyIndent = tk.column();
          tk.nextState(CAPTURE_KEY);
        }

      case CAPTURE_KEY:
        if (tk.isAlpha(c))
          curKey.add(c);
        else {
          var k = tidy(curKey);
          if (k.endsWith(":")) {
            var ctx = context.pop();
            if (ctx == START_DOCUMENT) {
              if (keyIndent != 0)
                tk.syntax("A section should start on column 0, is "+keyIndent);

              var ss = SECTION(sectionTidy(curKey),tk.info());
              toks.add(ss);
         
              tk.nextState(START_KEY);
            } else {
              if (keyIndent == 0) tk.syntax("A section key should be indented, maybe you forgot the --- to start a new section:");
              tk.skipToAlpha(START_VAL);
            }
        
          } else {
            tk.syntax("Key "+k+" should end with :");
          }
        }
        
      case START_VAL:
        if (tk.prevChar() == "\n") tk.syntax(tidy(curKey) +"key's value is empty");
        valIndent = tk.column();
        curVal = new StringBuf();
        curVal.add(c);
        tk.nextState(CAPTURE_VAL);
        
      case CAPTURE_VAL:
        capturingVal = true;
        if (!tk.isNL(c)) {
          curVal.add(c); 
        } else 
          tk.skipToAlpha(MULTI_LINE);

      case MULTI_LINE:
        var col = tk.column();
        if (col == valIndent) {
          curVal.add("\n");
          curVal.add(c);
          tk.nextState(CAPTURE_VAL);
        } else {
          if (col == 0 || col == keyIndent || c == "\n") {
            capturingVal = false;
            toks.add(makeProperty(tk,curKey,curVal));
            tk.nextState(START_KEY_OR_DOCUMENT,true);
          } else
            tk.syntax("expecting a new key at column " + keyIndent +
                   " or a multi-line value at column "+valIndent);
        }
      }
    }

    if (capturingVal) toks.add(makeProperty(tk,curKey,curVal));
    
    return toks;
  }

  static function
  parse(file:String):Hxp {
    //    var contents = neko.io.File.getContent(file);
    return tokens(new ChunkedFile(file)).fold(function(token,hbl:Hxp) {
        #if debug
        trace(token);
        #end
        switch(token) {
        case PROPERTY(name,val,info):
          hbl.setProperty(name,val,info);
        case SECTION(name,info):
          hbl.setSection(name,info);
          //case ENDSECTION(info):
          //hbl.endSection(info);
        }
        return hbl;
      },new Hxp(file));    
  }
  
  public static function
  process(file:String):Hxp {

    var h = parse(file);

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
  setSection(name,info:Info) {
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
  endSection(info:Info) {
    curSection = Config.GLOBAL;
  }
  
  public function
  setProperty(name,values,info:Info) {
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


