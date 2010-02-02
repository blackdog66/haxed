package haxed;

import haxed.Common;
using haxed.Validate;
using Lambda;
using StringTools;

typedef Info = { line:Int,col:Int};

enum Token {
  PROPERTY(name:String,value:String,info:Info);
  SECTION(name:String,info:Info);
  ENDSECTION(info:Info);
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

class Tokenizer<T> {
  var parseText:String;
  var textLength:Int;
  var curChar:Int;
  var lineNo:Int;
  var curState:T;
  var retState:T;
  var startState:T;
  var lineStart:Int;
  var reWnd:Bool;
  
  public function new(pt:String,ss:T) {
    startState = curState = retState = ss;
    parseText = pt;
    textLength = parseText.length;
    curChar = 0;
    lineNo = 1;
    reWnd = false;
    lineStart = 0;
  }
  
  public inline function
  isAlpha(c:String) {
    return ~/\S/.match(c);
  }

  public inline function
  isWhite(c:String) {
    return ~/\s/.match(c) ;
  }

  public inline function
  isNL(c:String) {
    return c == "\n";
  }

  public function
  peek() {
    if (curChar > textLength) {
      return "EOF";
    }
    return parseText.charAt(curChar);
  }
  
  public inline function
  column() {
    return (curChar-1) - lineStart;
  }

  public inline function
  state() {
    return curState;
  }
  
  public function
  nextState(newState:T,?rs:T,rw=false) {
    if (rs != null)
        retState = rs;

    curState = newState;
    if (rw) rewind();
  }

  public function
  popState() {
    if (retState == null || retState == curState /* guard against infinite loops */)
      curState = startState;
    else 
      curState = retState;
    
    retState = null;
    
  }

  public inline function
  info():Info {
    return {line:lineNo,col:column()};
  }

  public function
  nextChar() {
    if (curChar > textLength)
      return "EOF";
  
    var nc = parseText.charAt(curChar);    
  
    if (nc == "\t") syntax("I don't like tabs!");

    if (isNL(nc) && ! reWnd) {
#if debug
      neko.Lib.println(">>"+state()+":"+lineNo+"("+curChar+"): "+parseText.substr(lineStart,curChar-lineStart)+"<");
#end
      lineStart = curChar + 1;
      lineNo++;
    }
    
    curChar++;
    reWnd = false;
    return nc;
  }

  public function
  rewind() {
    reWnd = true;
    curChar--;
  }

  public inline function
  prevChar() {
    return parseText.charAt(curChar-1);
  }

  public function
  skipToNL(retState:T) {
    var c;
    while ((c = nextChar()) != "EOF") {
      if (isNL(c)) {
        nextState(retState,true);
        break;
      }
    }
  }

  public function
  skipToAlpha(retState:T) {
    var c;
    while ((c = nextChar()) != "EOF") {
      if(isAlpha(c) || isNL(c) || c == "#") {
        if (c == "#") {
          skipToNL(retState);
          nextState(retState,false);
        } else {
          nextState(retState,true);
        }
        break;
      }
    }
  }
  
  public function
  syntax(msg:String) {
    #if debug
    neko.Lib.print("State:" + state()+"  > ");
    #end
    if (column() > -1)
      neko.Lib.println("At line "+lineNo+" col "+column()+": "+msg);
    else 
      neko.Lib.println("At line "+ (lineNo -1) +": "+msg);
    neko.Sys.exit(1);
  }
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
  tokens(hf:String) {
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
    var contents = neko.io.File.getContent(file);
    return tokens(contents).fold(function(token,hbl:Hxp) {
        #if debug
        trace(token);
        #end
        switch(token) {
        case PROPERTY(name,val,info):
          hbl.setProperty(name,val,info);
        case SECTION(name,info):
          hbl.setSection(name,info);
        case ENDSECTION(info):
          hbl.endSection(info);
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
      .add("depends",false,Validate.depends)
      .add("class-path",true,Validate.toArray)
      .add("main-class",true)
      .add("target",true,Validate.target)
      .add("target-file",true);

    Validate.forSection(Config.PACK)
      .add("include",false,Validate.toArray);
    
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
  var curSection:String;
  
  public function new(f:String) {
    file = f;
    hbl = {};
    curSection = Config.GLOBAL;
    Reflect.setField(hbl,curSection,{});    
  }

  public function
  setSection(name,info:Info) {
    var
      curSec = Reflect.field(hbl,curSection),
      newSection = {};

    curSection = Common.camelCase(name);
    Reflect.setField(hbl,curSection,newSection);
  }

  public function
  endSection(info:Info) {
    curSection = Config.GLOBAL;
  }
  
  public function
  setProperty(name,values,info:Info) {
    var
      curSec = Reflect.field(hbl,curSection),
      fld = Common.camelCase(name);

    Reflect.setField(curSec,fld,values);
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


