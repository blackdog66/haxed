package tools.haxelib;

import tools.haxelib.Common;
using tools.haxelib.Validate;
using Lambda;
using StringTools;

typedef Info = { line:Int,col:Int };

enum Token {
  PROPERTY(name:String,value:String,info:Info);
  SECTION(name:String,attrs:String,info:Info);
  ENDSECTION(info:Info);
}

private enum State {
  START_KEY;
  CAPTURE_KEY;
  START_VAL;
  CAPTURE_VAL;
  MULTI_LINE;
  SECTION_ATTRS;
  SKIP;
  SKIPPASTNL;
  SKIPTONL;
}

class Parser {

  static var curChar = 0;
  static var lineNo = 1;
  static var state = START_KEY;
  static var retState = START_KEY;
  static var lineStart = 0;
  static var toks:List<Token>;
  
  static inline function isAllWhite(c:String) {
    return c == " " || c == "\t"  || c == "\r" || c == "\n";
  }

  static inline function isWhite(c:String) {
    return c == " " || c == "\t"  || c == "\r" ;
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

  static inline function column() {
    return curChar - lineStart;
  }

  static function nextState(newState:State,?rs:State) {
    if (rs != null) retState = rs;
    state = newState;
  }

  static inline function popState() {
    state = retState;
  }

  static inline function info():Info {
    return {line:lineNo,col:column()};
  }
  
  static function
  syntax(msg:String) {
    if (column() > -1)
      neko.Lib.println("At line "+lineNo+" col "+column()+": "+msg);
    else 
      neko.Lib.println("At line "+ (lineNo -1) +": "+msg);
    neko.Sys.exit(1);
  }

  public static function
  addProperty(ck:StringBuf,cv:StringBuf) {
    var
      k = tidy(ck).substr(0,-1),
      v = tidy(cv);

    if (k.length == 0) syntax("Need a key");
    if (v.length == 0) syntax("Need a value for "+k);
    
    var ps = PROPERTY(k,v,info());
    toks.add(ps);
  }
  
  public static function
  tokens(hf:String) {
    curChar = 0;
    lineNo = 1;
    state = START_KEY;
    retState = START_KEY;
    lineStart = 0;

    var
      len = hf.length,
      curKey = null,
      curVal = null,
      c = "",
      indent = 0,
      keyIndent=0,
      valIndent=0,
      inSection = false;

    toks = new List<Token>();
    
    do {
      c = hf.charAt(curChar);

      if (c == "\t") syntax("I don't like tabs!");
      if (c == "#") nextState(SKIPPASTNL);
      
      if (isNL(c)) {
        lineStart = curChar + 1 ;
        lineNo++;
      }
      
      switch(state) {
      case START_KEY:
        if  (!isAllWhite(c)) {
          curKey = new StringBuf();
          curKey.add(c);
          
          keyIndent = column();
          
          nextState(CAPTURE_KEY);
        } else {
          nextState(SKIP,START_KEY);
        }
      case CAPTURE_KEY:
        if (!isAllWhite(c))
          curKey.add(c);
        else {
          var k = tidy(curKey);

          if (k.endsWith(":")) {
            
            if (keyIndent > 0 && !inSection)
              syntax("A key needs to be at column 0 or within a section");

            if (keyIndent == 0 && inSection == true) {
              inSection = false;
              toks.add(ENDSECTION(info()));
            }

            nextState(SKIPTONL,START_VAL);
          } else {

            if (keyIndent != 0)
              syntax("A section should start on column 0");

            inSection = true;            

            if (isNL(c)) {
              var ss = SECTION(tidy(curKey),"",info());
              toks.add(ss);
         
              nextState(START_KEY);
            } else {
              nextState(SECTION_ATTRS);
              curVal = new StringBuf();
            }
          }
        }
      case START_VAL:
        if (c == "\n") syntax(tidy(curKey) +" is empty");
        valIndent = column();
        curVal = new StringBuf();
        curVal.add(c);
        nextState(CAPTURE_VAL);
      case CAPTURE_VAL:
        if (!isNL(c)) 
          curVal.add(c); 
        else
          nextState(SKIPTONL,MULTI_LINE);
      case MULTI_LINE:
        var col = column();
        if (col == valIndent) {
          curVal.add("\n");
          nextState(CAPTURE_VAL);
        } else {
          if (col == 0 || col == keyIndent || c == "\n" ) {
            addProperty(curKey,curVal);
            nextState(START_KEY);
          } else {
              syntax("expecting a new key at column " + keyIndent +
                     " or a multi-line value at column "+valIndent+", but got "+col);
          }
        }
        curChar--;
      case SECTION_ATTRS:
        if (!isNL(c))
          curVal.add(c);
        else {
          var ss = SECTION(tidy(curKey),tidy(curVal),info());
          toks.add(ss);
          nextState(START_KEY);
        }
      case SKIP:
        if(!isAllWhite(c)) {
          nextState(retState);
          curChar--;
        }
      case SKIPTONL:
        if (!isWhite(c)) {
          popState();
          curChar--;
        }
      case SKIPPASTNL:
        if (isNL(c)) {
          popState();
        }
      }
      
      curChar++;      

    } while (curChar < len);

    checkFinalProperty(curKey,curVal);
        
    return toks;
  }

  /* if we get to the end of file in one of these states it means the final
     prop has not been added */
  static function
  checkFinalProperty(curKey,curVal) {
    if (state == MULTI_LINE || state == CAPTURE_VAL ||
        retState == MULTI_LINE || retState == CAPTURE_VAL)
      addProperty(curKey,curVal);
  }

  static function
  parse(file:String):Hxp {
    var contents = neko.io.File.getContent(file);
    return tokens(contents).fold(function(token,hbl:Hxp) {
        //        trace(token);
        switch(token) {
        case PROPERTY(name,val,info):
          hbl.setProperty(name,val,info);
        case SECTION(name,attrs,info):
          hbl.setSection(name,attrs,info);
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
      .add("project",true,Validate.name)
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

    //    trace(h.hbl);
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
  setSection(name,attrs,info:Info) {
    var
      curSec = Reflect.field(hbl,curSection),
      newSection = {};

    curSection = Common.camelCase(name);
    Reflect.setField(newSection,"attrs",attrs);
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


