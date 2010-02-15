
package haxed;

import haxed.SyntaxTools;
import haxed.Reader;
  
private enum TType {
  T_LBRACE;
  T_RBRACE;
  T_LBRAK;
  T_RBRAK;
  T_COLON;
  T_COMMA;
  T_STRING(v:String);
  T_NUMBER(v:Float);
  T_BOOL(b:Bool);
  T_NULL;
}

class JSON {

  static var nextToken:Void->TType;
  static var readAssert:TType->TType;
  
  static function
  getTokenizer(r) {
    var
      tk = new Tokenizer<TType>(r);    

    tk.add(~/^\s*([\[\]\{\},:])/,function(re) {
          return switch (re.matched(1)) {
          case "[": T_LBRAK;
          case "]": T_RBRAK;
          case "{": T_LBRACE;
          case "}": T_RBRACE;
          case ",": T_COMMA;
          case ":": T_COLON;
          };
        })
      .add(~/^\s*\"(.*?)(?<!\\)\"/s,function(re) { return T_STRING(re.matched(1));})
      .add(~/^\s*(true|false)/,function(re) { return T_BOOL(re.matched(1) == "true"); })
      .add(~/^\s*([-+]?[0-9]*\.?[0-9]+)[^0-9]/,1,function(re) {
          return T_NUMBER(Std.parseFloat(re.matched(1)));
        })
      .add(~/^\s*null/,function(re) { return T_NULL; });
    return tk; 
  }

  // ~/^\s*([-+]?[0-9]*\.?[0-9]+)(?![0-9])
  
  public static function
  decodeString(hf:String) {
    return decode(new StringReader(hf));
  }
  
  static function
  readValue(t):Dynamic {
    var
      v:Dynamic;
    
    switch (t) {

    case T_LBRAK:		v = readArray();
    case T_LBRACE: 		v = readObject();
    case T_NUMBER(n): 	v = n;
    case T_STRING(s): 	v = s;
    case T_BOOL(b):		v = b;
    case T_NULL:		v = null;

    default:
      throw "Expected a value, got a "+t;
    }
    
    return v;
  }

  static inline function
  expecting(t:TType,g:TType) {
    if (t != g) {
      Os.print("expecting " +t + " got "+g);
      Os.exit(1);
    }
  }
  
  static function
  readArray():Array<Dynamic> {
    var a = [],
      t;
    //    trace("reading array");
    t = nextToken();

    if (t == T_RBRAK) return a;
    
    do {

      a.push(readValue(t));

      t = nextToken();
      
      if (t == T_RBRAK || t == null) break;
      expecting(T_COMMA,t);
      t = nextToken();
      
    } while (true);
    
    return a;
  }

  static function
  readObject() {
    var o = {} ,t;
    //trace("reading object");
    t = nextToken();

    if (t == T_RBRACE) return o;
    
    do {
      var key = readValue(t);
      readAssert(T_COLON);      
      var v = readValue(nextToken());
      //      trace("set "+key+" to "+v);
      Reflect.setField(o,key,v);

      t = nextToken();
      if (t == T_RBRACE || t == null) break;
      expecting(T_COMMA,t);
      t = nextToken();

    } while(true);
    return o;
  }
  
  public static function
  decode(r:Reader) {
    
   var tzer = getTokenizer(r);
    
    nextToken = tzer.nextToken;
    readAssert = tzer.readAssert;
    
   return readValue(nextToken());

  }


  public static function encode() {

  }

}