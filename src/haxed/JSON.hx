
package haxed;

import haxed.SyntaxTools;

#if neko
import neko.Utf8;
#elseif php
import php.Utf8;
#end


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

    tk.match(~/^\s*([\[\]\{\},:])/,function(re) {
          return switch (re.matched(1)) {
          case "[": T_LBRAK;
          case "]": T_RBRAK;
          case "{": T_LBRACE;
          case "}": T_RBRACE;
          case ",": T_COMMA;
          case ":": T_COLON;
          };
        })

      .match(~/^\s*\"(.*?)(?<!\\)\"/s,function(re) { return T_STRING(re.matched(1));})
      .match(~/^\s*(true|false)/,function(re) { return T_BOOL(re.matched(1) == "true"); })
      .match(~/^\s*([-+]?[0-9]*\.?[0-9]+)[^0-9]/,function(re) {
          return T_NUMBER(Std.parseFloat(re.matched(1)));
        },Push(-1))
      .match(~/^\s*null/,function(re) { return T_NULL; });

    return tk; 
  }

  public static function
  decode(hf:String) {
    return parse(new StringReader(hf));
  }

  public static function
  decodeFile(file:String) {
    return parse(new ChunkedFile(file));
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
    t = nextToken();

    if (t == T_RBRACE) return o;
    
    do {
      var key = readValue(t);
      readAssert(T_COLON);      
      var v = readValue(nextToken());
      Reflect.setField(o,key,v);
      t = nextToken();
      if (t == T_RBRACE || t == null) break;
      expecting(T_COMMA,t);
      t = nextToken();

    } while(true);
    return o;
  }
  
  static function
  parse(r:Reader) {
    
    var tz = getTokenizer(r);
    
    nextToken = tz.nextToken;
    readAssert = tz.readAssert;
    
    return readValue(nextToken());
  }
  
  public static function
  encode(d:Dynamic) {
    return convertToString(d);	
  }
	
  private static function
  convertToString(value:Dynamic):String {
    if (value == null) return null;
    
    var t = Type.typeof(value) ;
    return switch(t) {
    case TUnknown,TFunction,TNull:
      throw "Don't convert :"+value;
    case TFloat:
      Math.isFinite(value) ? Std.string(value) : "null";
    case TInt:
      Std.string(value);
    case TBool:
       value ? "true" : "false";
    case TObject:
      objectToString(value);
    case TEnum(e):
      Type.enumConstructor(value);
    case TClass(c):      
      switch( #if neko Type.getClassName(c) #else c #end ) {
      case #if neko "String" #else cast String #end:
        "\""+value+"\"";
      case #if neko "Array" #else cast Array #end:
        arrayToString(value);
      case #if neko "List" #else cast List #end,#if neko "IntHash" #else cast IntHash #end:
        arrayToString(Lambda.array(value));

      case #if neko "Hash" #else cast Hash #end:
        objectToString(mapHash(value));
      default:
        throw "Don't convert class:"+c+" of value:"+value;
      }
    }
  }
	
  private static function
  mapHash(value:Hash<Dynamic>):Dynamic{
    var ret:Dynamic = { };
    for (i in value.keys())
      Reflect.setField(ret, i, value.get(i));
    return ret;
  }

  // escapeString simplified from hxJson2
  private static function
  escapeString( str:String ):String {
    var
      s = new StringBuf(),
      ch:String,
      len = str.length,
      utf8len = Utf8.length(str),
      utf8mode = utf8len != len;
    
    if (utf8mode)
      len = utf8len;

    for (i in 0...len) {
      var ch = (utf8mode) ? Utf8.sub(str,i,1) : ch = str.charAt( i );
          
      switch ( ch ) {			
      case '"':	// quotation mark
        s.add("\\\"");					
      case '\\':	// reverse solidus
        s.add("\\\\");
      case '\n':	// newline
        s.add("\\n");
      case '\r':	// carriage return
        s.add("\\r");
      case '\t':	// horizontal tab
        s.add("\\t");						
      default:

        // check for a control character and escape as unicode
        var code = (utf8mode) ? Utf8.charCodeAt(str,i) : ch.charCodeAt(0);

        if ( ch < ' ' || code > 127) {
#if (neko || php)
        var hexCode:String = StringTools.hex(Utf8.charCodeAt(str,i));
#else
        var hexCode:String = StringTools.hex(ch.charCodeAt( 0 ));
#end
        // ensure that there are 4 digits by adjusting
        // the # of zeros accordingly.
        var zeroPad:String = "";
        for (j in 0...4 - hexCode.length) {
          zeroPad += "0" ;
        }
        //var zeroPad:String = hexCode.length == 2 ? "00" : "000";						
        // create the unicode escape sequence with 4 hex digits
        s.add( "\\u" + zeroPad + hexCode);
            } else {					
        // no need to do any special encoding, just pass-through
        s.add(ch);						
      }
    }	
  }
  return "\"" + s.toString() + "\"";
}

  private static function
  arrayToString( a:Array < Dynamic > ):String {
    var s = new Array<String>();
    for (i in 0...a.length) {
      s.push(convertToString(a[i]));	
    }
    return "[" + s.join(",") + "]";
  }
  
  private static function
  objectToString(o:Dynamic):String {
    var s = new Array<String>();		
    for ( key in Reflect.fields(o) ) {
      var value = Reflect.field(o,key);			
      if (!Reflect.isFunction(value))	{
        s.push(escapeString(key) + ":" + convertToString(value));
      }			
    }		
    return "{" + s.join(",") + "}";
  }
}
