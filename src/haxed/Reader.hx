
package haxed;

interface Reader {
  function charCodeAt(i:Int):Int;
  function atEof():Bool;
  function canChunk():Bool;
  function nextChunk():String;
}


class StringReader implements Reader {

  var str:String;
  var cur:Int;
  var len:Int;
  
  public function new(s:String) {
    str = s;
    len = str.length;
  }

  public function charCodeAt(i:Int) {
    cur = i;
    if (atEof()) return -1;
    return str.charCodeAt(i);
  }

  public function atEof() {
    return cur + 1 > len;
  }

  public function nextChunk():String {
    return "";
  }

  public function canChunk() { return false ;}

}

