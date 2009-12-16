
import tools.haxelib.Hxp;
import tools.haxelib.Os;

class Quick {

 public static function main() {

    var s = Os.fileIn("myproject.hxp");
    trace(HxpTools.tokens(s));
  }
 


}