
import tools.haxelib.Parser;
import tools.haxelib.Os;

class Quick {

 public static function main() {

    var s = Os.fileIn("myproject.hxp");
    trace(Parser.tokens(s));
  }
 


}