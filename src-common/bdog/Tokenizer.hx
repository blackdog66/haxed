package bdog;

import bdog.Reader;

typedef Info = { line:Int,col:Int};

typedef Converter<T> = EReg->T;

typedef Token<T> = {
	var recogniser:EReg;
	var converter:Converter<T>;
}

private typedef IToken<T> = {> Token<T> ,
  var pushback:Int;
  var discard:Bool;
}

enum SynOptions {
  Push(i:Int);
  Discard;
}

enum SynStyle {
  LINE;
  CHUNK;
}

class Tokenizer<T> {
  static var EOF = -1;
  static var DEFAULT_CHUNK_SIZE = 512;
  
  var reader:Reader;
  var style:SynStyle;
  var curChar:Int;
  var lineNo:Int;
  var lineStart:Int;
  var lineLen:Int;
  var startCh:Int;
  var curLine:StringBuf;
  var recognisedTokens:Array<IToken<T>>;
  var eof:Bool;
  var totalLength:Int;
  var leftOver:String;
  var chunker:Void->String;
  var charCodeAt:Int->Int;
  var inChunk:Int;
  var tokenGroups:Hash<Array<IToken<T>>>;
  var markBuffer:StringBuf;
  
  public function new(rd:Reader,?s:SynStyle) {
    recognisedTokens = new Array();
    tokenGroups = new Hash();
    tokenGroups.set("default",recognisedTokens);
    reader = rd;
    curChar = 0;
    lineNo = 0;
    lineStart = 0;
    lineLen = 0;
    startCh = 0;
    eof = false;
    curLine = new StringBuf();
    leftOver = "";
    style = (s == null) ? CHUNK : s;

    if (rd.canChunk() && style == CHUNK) {
      chunker = reader.nextChunk;
    } else {
      chunker = lineChunk;
    }
      
    charCodeAt = reader.charCodeAt;
  }

  public function
  match(re:EReg,conv:Converter<T>,?options:Dynamic) {
    var matcher = {recogniser:re,converter:conv,pushback:0,discard:false};
    if (options != null) {
      var opts:Array<SynOptions> = (!Std.is(options,Array)) ? [options] : options;
      for (o in opts) {
        switch(o) {
        case Push(pb): matcher.pushback = pb;
        case Discard: matcher.discard = true;
        }
      }
    
    }
    recognisedTokens.push(matcher);
    return this;
  }

  public function
  group(name:String) {
    var
      rt  = tokenGroups.get(name);
    
    if (rt == null) {
      rt = new Array();
      tokenGroups.set(name,rt);
    }

    recognisedTokens = rt;

    return this;
  }

  public function
  use(name:String) {
    var rt = tokenGroups.get(name);
    if (rt == null)
      throw "Token group :"+name+" does not exist";

    recognisedTokens = rt;
    return this;
  }
  
  public function
  removeGroup(name:String) {
    tokenGroups.remove(name);
    return this;
  }

  public function
  mark() {
    markBuffer = new StringBuf();
  }

  public function
  yank():String {
    var y = markBuffer.toString();
    markBuffer = null;
    return y;
  }
  
  public inline function
  isNL(c) {
    return c == 10;
  }

  public function
  peek() {
    return reader.charCodeAt(curChar);
  }
  
  public inline function
  column() {
    return fromBOL()+inChunk;
  }

  public inline function
  info():Info {
    return {line:lineNo,col:column()};
  }

  public inline function atEof() {
    return reader.atEof();
  }
  
  public function
  nextChar() {
    var nc = charCodeAt(curChar);
    
    if (isNL(nc)) {
        
#if debug
        Os.println(">>"+":"+lineNo+"("+curChar+"): "+curLine.toString()+"<");
        curLine = new StringBuf();
#end
        lineStart = curChar + 1;
        lineNo++;
    } else {      
#if debug
      if (nc != EOF)
        curLine.addChar(nc);
#end
    }
    
    curChar++;
    return nc;
  }
  
  function lineChunk() {
    var
      sb = new StringBuf(), c;
    
    while ((c = nextChar()) != -1) {
      sb.addChar(c);
      if (c == 10) {
        break;
      }
    }

    var s = sb.toString();
    lineLen = s.length;
    return s;
  }

  function withChunks(chunk:String,fn:String->Int) {

    if(chunk == "") {
      chunk = chunker();
    }
    
    do {
      var np = fn(chunk);
      if (np == 0) {
        if (atEof()) {          
          break;
        }
        
        if (markBuffer != null) {
            markBuffer.add(chunk);
        }
        
        if (style == LINE) 
          chunk = chunker(); // no match, get new line
        else
          chunk += chunker(); // no match, extend chunk 
      } else {
        if (np > 0) {
          // discard the beginning of chunk (default)
          startCh = chunk.length;
          if (markBuffer != null) {
            markBuffer.add(chunk.substr(0,np));
          }
          chunk = chunk.substr(np); 
        } else {
            // discard the end of the chunk - only with Discard option
            chunk = chunk.substr(0,-np);
            lineLen = chunk.length;
        }
        
        break;
      }
    } while (true);
    return chunk;
  }

  public function
  fromBOL() {
    return lineLen - startCh;
  }
  
  public function
  nextToken() {
    var me =  this;
    var tok = null;
      
    leftOver = withChunks(leftOver,function(chunk) {
        for (rt in me.recognisedTokens) {
          if (rt.recogniser.match(chunk)) {
            var p = rt.recogniser.matchedPos();            
            tok = rt.converter(rt.recogniser);
            if (tok != null) {
              me.inChunk = p.pos;
              return (rt.discard) ? -p.pos : p.pos + p.len + rt.pushback;
            }
          }
        }
        return 0;
      });
    return tok;
  }

  public function iterator():Iterator<T> {
    var t = null,
      me = this;
    return {
    hasNext: function() {
        t = me.nextToken();
        return t != null;
      },
    next: function() {
        return t;
      }
    }
  }

  public inline function
  prevChar() {
    return reader.charCodeAt(curChar-1);
  }
  
  public inline function
  readAssert(expected:T) {
    var tok = nextToken();
    if (tok != expected) throw "expected:" + expected + " got "+tok;
    return tok;
  }
  
  public function
  syntax(msg:String) {
    Os.println("At line "+lineNo+" col "+column()+": "+msg);
    Os.exit(1);
  }
}


















