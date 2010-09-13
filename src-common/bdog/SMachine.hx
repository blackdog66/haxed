package bdog;

using StringTools;

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

class SMachine<S,E> {
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
      if (actions.exists(tID)) Os.println("Warning: Overwriting "+tID);
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
      if (actions.exists(sID)) Os.println("Warning: Overwriting event "+sID);
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
          syntax("From "+curState +" unexpected "+unexpected+", expected "+expected.join(","));
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






