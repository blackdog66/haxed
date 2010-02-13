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
  
  public function new(rd:Reader) {
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
      Os.print(">>"+state()+":"+lineNo+"("+curChar+"): "+curLine.toString()+"<");
#end
      curLine = new StringBuf();
      lineStart = curChar + 1;
      lineNo++;
    }
    
    curChar++;
    reWnd = false;
    return nc;
  }

  function getChunk(sb:StringBuf,size=20) {
    var
      i = 0,
      c;
    
    while ((c = nextChar()) != "EOF" && i < size) {
      sb.add(c);
    }
    
    return sb.toString();
  }
  
  public function
  nextToken():T {
    var
      sb = new StringBuf(),
      startPoint = curChar;
    while(!atEof()) {
      var chunk = getChunk(sb);
      for (rt in recognisedTokens) {
        if (rt.recogniser.match(chunk)) {
          var p = rt.recogniser.matchedPos();
          curChar = startPoint + p.pos + p.len;
          try {
            return rt.converter(rt.recogniser.matched(0),rt.recogniser);
          } catch(ex:Dynamic) {
            trace("converter failed with "+rt.recogniser.matched(0) +" in context "+chunk);
          }
        }
      }
    }
    return null;
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
  skipToAlpha() {
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
    #if debug
    Os.print("State:" + state()+"  > ");
    #end
    if (column() > -1)
      Os.print("At line "+lineNo+" col "+column()+": "+msg);
    else 
      Os.print("At line "+ (lineNo -1) +": "+msg);

    Os.exit(1);
  }
}


class Parser<T> {

  var curState:T;
  var retState:T;
  var startState:T;
  
  public function new(ss:T) {
    startState = curState = retState = ss;
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
}