
package haxed;

interface Reader {
  function charAt(i:Int):String;
  function atEof():Bool;
}

class StringReader implements Reader {

  var str:String;
  var cur:Int;
  var len:Int;
  
  public function new(s:String) {
    str = s;
    len = str.length;
  }

  public function charAt(i:Int) {
    cur = i;
    if (atEof()) return "EOF";
    return str.charAt(i);
  }

  public function atEof() {
    return cur + 1 > len;
  }

}
