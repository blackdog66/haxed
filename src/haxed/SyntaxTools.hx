package haxed;

import haxed.Os;
import haxed.Reader;

typedef Info = { line:Int,col:Int};

typedef Converter<T> = EReg->T;

typedef Token<T> = {
	var recogniser:EReg;
	var converter:Converter<T>;
}

typedef IToken<T> = { > Token<T>,
	var pushback:Int;
}

class Tokenizer<T> {
  static var EOF = -1;
  static var DEFAULT_CHUNK_SIZE = 512;
  
  var reader:Reader;
  var curChar:Int;
  var lineNo:Int;
  var lineStart:Int;
  var reWnd:Bool;
  var curLine:StringBuf;
  var recognisedTokens:Array<IToken<T>>;
  var eof:Bool;
  var totalLength:Int;
  var leftOver:String;
  var chunker:Void->String;
  var charCodeAt:Int->Int;
  
  public function new(rd:Reader,useChunker=true) {
    recognisedTokens = new Array();
    reader = rd;
    curChar = 0;
    lineNo = 1;
    reWnd = false;
    lineStart = 0;
    eof = false;
    curLine = new StringBuf();
    leftOver = "";

    if (rd.canChunk() && useChunker)
      chunker = reader.nextChunk;
    else {
      chunker = nextChunk;
    }
      
    charCodeAt = reader.charCodeAt;
  }

  public function
  add(rec:EReg,pb:Int=0,conv:Converter<T>) {
    recognisedTokens.push({recogniser:rec,converter:conv,pushback:pb});
    return this;
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
  isNL(c) {
    return c == 10;
  }

  public function
  peek() {
    return reader.charCodeAt(curChar);
  }
  
  public inline function
  column() {
    return (curChar-1) - lineStart;
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

    if (nc == EOF) {
      return EOF;
    }
 
    //    if (!reWnd) curLine.add(nc);
    
    if (isNL(nc) && ! reWnd) {
     
#if debug
      Os.print(">>"+":"+lineNo+"("+curChar+"): "+curLine.toString()+"<");
#end
      // curLine = new StringBuf();
      lineStart = curChar + 1;
      lineNo++;
    }
    
    curChar++;
    //reWnd = false;
    return nc;
  }

  function nextChunk() {
    var
      sb = new StringBuf(), 
      c,
      i = 0;
    while ((c = nextChar()) != -1) {
      sb.addChar(c);
      if (i++ > DEFAULT_CHUNK_SIZE) break;
    }

    return sb.toString();
  }

  function withChunks(chunk:String,fn:String->Int) {

    if(chunk == "")
      chunk = chunker();
    
    do {
      var np = fn(chunk);
      switch(np) {
      case -1:

        if (atEof()) {          
          break;
        }
        
        chunk += chunker();        

      default:
        chunk = chunk.substr(np);
        break;
      }
    } while (true);
    return chunk;
  }

  public function
  nextToken() {
    var me =  this;
    var tok = null;

    leftOver = withChunks(leftOver,function(chunk) {
        for (rt in me.recognisedTokens) {
          if (rt.recogniser.match(chunk)) {
            var p = rt.recogniser.matchedPos();
            #if debug
            try {
            #end
              tok = rt.converter(rt.recogniser);
            #if debug
            } catch(ex:Dynamic) {
              trace("converter failed with "+rt.recogniser.matched(0) +" in context "+chunk);
              trace(ex);
              Os.exit(1);
            }
            #end
            return p.pos + p.len - rt.pushback;
          }
        }        
        return -1;
      });
    //        trace(tok);    
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
  
  public function
  rewind() {
    reWnd = true;
    curChar--;
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
    if (column() > -1)
      Os.print("At line "+lineNo+" col "+column()+": "+msg);
    else 
      Os.print("At line "+ (lineNo -1) +": "+msg);

    Os.exit(1);
  }
}

typedef Action = Dynamic->Void;

class Parser<S,E> {
  var funcs:Hash<Action>;
  var trans:Hash<S>;
  var curState:S;
  var retState:S;
  var startState:S;
  var tokenizer:Tokenizer<E>;
  
  public function new(ss:S,t:Tokenizer<E>) {
    funcs = new Hash<Action>();
    trans = new Hash<S>();
    startState = curState = retState = ss;
    tokenizer = t;
  }

  public inline function
  state() {
    return curState;
  }

  inline function actionID(s:S,?e:E) {
    var s = Type.enumConstructor(s);
    if (e != null) {
      s += Type.enumConstructor(e);
    }
    return s;
  }

  public function
  on(s:S,f:Action) {
    funcs.set(actionID(s),f);
    return this;
  }

  public function
  tr(s:S,e:E,newState:S) {
    trans.set(actionID(s,e),newState);
    return this;
  }
  
  public function
  parse(context:Dynamic) {
    var t;
    while((t = nextToken()) != null)
      execute(t,context);
    return context;
  }
  
  public
  function execute(event:E,context:Dynamic) {    
    var f = funcs.get(actionID(curState,event));
    if (f != null)
      f(context);    
  }

    
  public inline function
  nextToken() {
    return tokenizer.nextToken();
  }

  public function
  readAssert(expected:E) {
    var tok = nextToken();
    if (tok != expected) throw "expected:" + expected + " got "+tok;
    return tok;
  }

  public function
  nextState(newState:S,?rs:S,rw=false) {
    if (rs != null)
        retState = rs;

    curState = newState;
    //if (rw) rewind();
  }

  public function
  popState() {
    if (retState == null || retState == curState /* guard against infinite loops */)
      curState = startState;
    else 
      curState = retState;
    
    retState = null;
    
  }
}


class SyntaxTools {

}