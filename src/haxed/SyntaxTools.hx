package haxed;

import Type;
import haxed.Os;
import haxed.Reader;

using StringTools;

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
  Pushback(i:Int);
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
  
  public function new(rd:Reader,?s:SynStyle) {
    recognisedTokens = new Array();
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

    if (rd.canChunk() && style == CHUNK)
      chunker = reader.nextChunk;
    else {
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
        case Pushback(pb): matcher.pushback = pb;
        case Discard: matcher.discard = true;
        }
      }
    
    }
    recognisedTokens.push(matcher);
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
        Os.print(">>"+":"+lineNo+"("+curChar+"): "+curLine.toString()+"<");
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
      switch(np) {
      case -1:

        if (atEof()) {          
          break;
        }

        if (style == LINE) {
          chunk = chunker(); // no match, get new line
        } else
          chunk += chunker(); // extend chunk until match

      default:
        startCh = chunk.length;
        chunk = chunk.substr(np);
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
              return (rt.discard) ? chunk.length : p.pos + p.len - rt.pushback;
            }
          }
        }
        return -1;
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
    Os.print("At line "+lineNo+" col "+column()+": "+msg);
    Os.exit(1);
  }
}

enum CallType {
  ByName;
  ByArray;
  ByEnum;
}

enum ActionDef<S> {
  ONTRAN(s:S,e:Dynamic,f:Dynamic);
  ONSTATE(e:Dynamic,f:Dynamic);
}

typedef Action = {fn:Dynamic,type:CallType};

class Parser<S,E> {
  var actions:Hash<Action>;
  var trans:Hash<S>;
  var curState:S;
  var startState:S;
  var tokenizer:Tokenizer<E>;
  var allowed:Hash<Bool>;
  var eventStr:E->String;
  var stack:Array<E>;
  
  public function new(ss:S,t:Tokenizer<E>) {
    actions = new Hash<Action>();
    trans = new Hash<S>();
    allowed = new Hash<Bool>();
    startState = curState = ss;
    tokenizer = t;
    stack = new Array<E>();
  }

  public inline function
  state() {
    return curState;
  }

  inline function
  getArray(e:Dynamic):Array<E> {
    return (!Std.is(e,Array)) ? [e] : e;
  }

  inline function
  stateID(s:S) {
    return Type.enumConstructor(s);
  }
  
  inline function
  eventID(e:E) {
    return Type.enumConstructor(e);
  }

  inline function
  transID(s:S,e:Dynamic):String {
    return stateID(s) + "-" + eventID(e);
  }

  public inline function
  syntax(m) {
    tokenizer.syntax(m);
  }

  public inline function
  push(e:E) {
    stack.push(e);
  }

  public inline function
  pop():E {
    return stack.pop();
  }
                             
  public function
  nextToken():E {
    if (stack.length > 0) return stack.pop();
    return tokenizer.nextToken();
  }
  
  function
  onTransition(s:S,e:Dynamic,f:Dynamic) {
    if (!Reflect.isFunction(f))
      throw "3rd param should be a function";

    for (ev in getArray(e)) {
      var tID = transID(s,ev);
      if (actions.exists(tID)) Os.print("Warning: Overwriting "+tID);
      actions.set(tID,{fn:f,type:(Std.is(e,Array)) ? ByEnum : ByName});
    }
    
    return this;
  }

  function
  onEvent(e:Dynamic,f:Dynamic) {
    if (!Reflect.isFunction(f))
      throw "2nd param should be a function";

    for (ev in getArray(e)) {
      var sID = stateID(e);
      if (actions.exists(sID)) Os.print("Warning: Overwriting event "+sID);
      actions.set(sID,{fn:f,type:(Std.is(e,Array)) ? ByEnum : ByName});
    }
    
    return this;
  }
  

  public function
  define(trans:Array<ActionDef<S>>) {
    for (t in trans) {
      switch(t) {
      case ONTRAN(s,e,f): onTransition(s,e,f);
      case ONSTATE(e,f): onEvent(e,f);
      }
    }
    return this;
  }

  function callFn(call:Action,event:Dynamic):S {
    return switch(call.type) {
    case ByEnum:
      call.fn(event);
    case ByName:
      Reflect.callMethod(this,call.fn,Type.enumParameters(event));
    case ByArray:
      call.fn(Type.enumParameters(event));
    }
  }
  
  public function
  parse() {
    var
      event:E,
      sID = stateID(curState);
    while((event = nextToken()) != null) {

      var
        eID = eventID(event),
        action = actions.get(sID+"-"+eID); // a transition
      
	  #if TRACESTATES
      var lastState = curState;
      #end
      
      if (action != null) {
        curState = callFn(action,event);
        sID = stateID(curState);

        #if TRACESTATES
        trace(">> "+stateID(lastState)+" --> "+event+" --> "+curState);
        #end
        
        action = actions.get(sID) ; // a state event
        if (action != null) {

          #if TRACESTATE
          trace(">> executing event "+curState);
          #end
          
          curState = callFn(action,curState);
          sID = stateID(curState);
          
        }
        
      } else {
        if (allowed.exists(eID)) {
          #if TRACESTATES
          trace(">> skipping:"+transID(curState,event)+", state remains:"+curState);
          #end
        } else  {
          var expected = [];
          
          for (k in actions.keys()){
            if (k.startsWith(sID)) {
              expected.push(k.substr(k.indexOf("-")+1));
            }
          }

          var unexpected = (eventStr != null) ? eventStr(event) : eID;
          syntax("!! Unexpected "+unexpected+", expected "+expected.join(","));
        }
      }
    }
  }

  public function
  allow(e:Dynamic) {
    for (flt in getArray(e))
      allowed.set(Type.enumConstructor(flt),true);
    return this;
  }
  
  public function
  readAssert(expected:E) {
    var tok = nextToken();
    if (tok != expected) throw "expected:" + expected + " got "+tok;
    return tok;
  }

  public function
  tokenString(f:E->String) {
    eventStr = f;
  }

}


class SyntaxTools {

}