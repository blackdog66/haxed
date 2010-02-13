
package haxed;

import haxed.SyntaxTools;
import haxed.Reader;

private enum State {
  DOCUMENT;
  ARRAY(a:Array<State>);
  OBJECT;
  STRING;
  NUMBER;
  TRUE;
  FALSE;
  NULL;
}

  
private enum TTypes {
  T_LBRACE;
  T_RBRACE;
  T_LBRAK;
  T_RBRAK;
  T_COLON;
  T_COMMA;
  T_STRING(v:String);
  T_NUMBER(v:Float);
  T_TRUE;
  T_FALSE;
  T_NULL;
  T_WHITE;
}


class JSON {
  
  static function
  getTokeniser(r) {
    var
      tk = new Tokenizer<TTypes>(r);    
    tk.add(~/^\s+/,function(m,re) {
        return T_WHITE;
      })
      .add(~/^[\[\]\{\},:]/,function(m,re) {
          return switch (m) {
          case "[": T_LBRAK;
          case "]": T_RBRAK;
          case "{": T_LBRACE;
          case "}": T_RBRACE;
          case ",": T_COMMA;
          case ":": T_COLON;
          };
        })
      .add(~/^null/,function(m,re) { return T_NULL; })
      .add(~/^true/,function(m,re) { return T_TRUE; })
      .add(~/^false/,function(m,re) { return T_FALSE; })
      .add(~/^\"(.*?)\"/,function(m,re) { return T_STRING(re.matched(1));})
      .add(~/^[-+]?[0-9]*\.?[0-9]+/,function(m,re) {
          return T_NUMBER(Std.parseFloat(m));
        });
    return tk; 
  }
  
  public static function
  decodeString(hf:String) {
    return decode(new StringReader(hf));
  }

  function readArray() {
    while(token != T_RBRAK) {
    readValue();
    readComma();
    }
  }

  public static function
  decode(r:Reader) {
    var
      p = Parser<State,TTypes>(DOCUMENT),
      tk = getTokeniser(r),
      token:TTypes,
      context = new Array<State>(),
      c,
      count = 0;


    p.parse();
    
    p.on(DOCUMENT,T_LBRACE,function() {
        readArray();
      })
      .on(ARRAY,T_RBRAK,function() {
          n.next(DOCUMENT);
        }


          p.start(tk);
          
    
      //if (count++ > 20) Os.exit(1);
      });
       
  }

}