package haxed;

import haxed.Os;
import haxed.Reader;

typedef Info = { line:Int,col:Int};

typedef Converter<T> = String->EReg->T

typedef Token<T> = {
	var recogniser:EReg;
	var converter:Converter<T>;
}

class Tokenizer<T> {
  var reader:Reader;
  var curChar:Int;
  var lineNo:Int;
  var lineStart:Int;
  var reWnd:Bool;
  var curLine:StringBuf;
  var recognisedTokens:Array<Token<T>>;
  var eof:Bool;
  var totalLength:Int;
  
  public function new(rd:Reader) {
    recognisedTokens = new Array();
    reader = rd;
    curChar = 0;
    lineNo = 1;
    reWnd = false;
    lineStart = 0;
    eof = false;
    curLine = new StringBuf();
  }

  public function
  add(rec:EReg,read:Converter<T>) {
    recognisedTokens.push({recogniser:rec,converter:read});
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
  isNL(c:String) {
    return c == "\n";
  }

  public function
  peek() {
    return reader.charAt(curChar);
  }
  
  public inline function
  column() {
    return (curChar-1) - lineStart;
  }

  public inline function
  info():Info {
    return {line:lineNo,col:column()};
  }

  public function atEof() {
    return eof;
  }
  
  public function
  nextChar() {
    var nc = reader.charAt(curChar);    

    if (nc == "EOF") {
      eof = true;
      return "EOF";
    }
 
    if (!reWnd) curLine.add(nc);
    
    if (isNL(nc) && ! reWnd) {
     
#if debug
      Os.print(">>"+":"+lineNo+"("+curChar+"): "+curLine.toString()+"<");
#end
      curLine = new StringBuf();
      lineStart = curChar + 1;
      lineNo++;
    }
    
    curChar++;
    reWnd = false;
    return nc;
  }

  function fillChunk(size=40) {
    var
      sb = new StringBuf(), 
      c,
      i = 0;
    while ((c = nextChar()) != "EOF") {
      sb.add(c);
      if (i++ > size) break;
    }

    return sb.toString();
  }
  
  function withChunks(fn:String->Int) {
    var
      chunk = fillChunk();    
    do {
      var np = fn(chunk);

      if (np == -1) {

        // don't have a match, so extend this chunk looking         

        if (atEof()) {          
          trace("breaking here");
          break;
        }
        
        chunk += fillChunk();
      } else  {         
        chunk = chunk.substr(np);
        //    trace("reusing >"+chunk+"<");
      }
       
    } while (true);
  }
  
  public function
  tokens(fn:T->Void) {
    var me =  this;
    withChunks(function(chunk) {
        var i = 0;
        for (rt in me.recognisedTokens) {
          if (rt.recogniser.match(chunk)) {
            var p = rt.recogniser.matchedPos();
            try {
              fn(rt.converter(rt.recogniser.matched(0),rt.recogniser));
            } catch(ex:Dynamic) {
              trace("converter failed with "+rt.recogniser.matched(0) +" in context "+chunk);
              trace(ex);
              Os.exit(1);
            }
            return p.pos + p.len;
          }
          i++;
        }        
        return -1;
      });
  }
  
  public function
  rewind() {
    reWnd = true;
    curChar--;
  }

  public inline function
  prevChar() {
    return reader.charAt(curChar-1);
  }

  public function
  skipToNL(onFinish:Void->Void) {
    var c;
    while ((c = nextChar()) != "EOF") {
      if (isNL(c)) {
        onFinish();
        break;
      }
    }
  }

  public function
  skipToAlpha(onFinish:Void->Void) {
    var c;
    while ((c = nextChar()) != "EOF") {
      if(isAlpha(c) || isNL(c) || c == "#") {
        onFinish();
        break;
      }
    }
  }

  public function
  readString(tk:Tokenizer<T>,delimeter='"') {
    var
      c,
      sb = new StringBuf();
      
    while ((c = tk.nextChar()) != "EOF" && c != delimeter) {
        sb.add(c);
    }

    return sb.toString();
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

typedef Action:Void->Void;

class Parser<S,E> {
  var funcs:Hash<Void->Void>;
  var curState:S;
  var retState:S;
  var startState:S;
  var tokenizer:Tokenizer;
  var pump:E->Void;
  
  public function new(ss:S,t:Tokenizer<E>) {
    funcs = new Hash<Action>();
    startState = curState = retState = ss;
    tokenizer = t;
  }

  public inline function
  state() {
    return curState;
  }

  public function
  on(s:S,e:E,f:Action) {
    funcs.set(Type.enumConstructor(s)+Type.enumConstructor(e),f);
    return this;
  }

  public
  function execute(event:E) {
    var
      s = Type.enumConstructor(curState),
      e = Type.enumConstructor(event);
    
    var f = funcs.get(s+e);
    if (f != null)
      f(agent);
  }

    
  public function
  parse() {
    tokenizer.tokens(pump);
  }
  
  public function
  nextState(newState:T,?rs:T,rw=false) {
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