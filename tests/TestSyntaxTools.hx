
package tests;

import haxed.Os;
import haxed.ChunkedFile;
import haxed.SyntaxTools;
import haxed.JSON;
import haxed.Reader;
import haxed.Parser;

class TestSyntaxTools {

  public static function
  main() {
    var hxp = HxpParser.process("/home/blackdog/Projects/fairplay/lbb.haxed");
    var obj = hxp.hbl;

   
    var j = JSON.encode(obj);
    trace(JSON.decode(j));
    
    //testJson();
  }


  public static function
  testJson() {
    var v  = JSON.decode(Os.fileIn("client.json"));
    trace(v);
    
    trace(JSON.encode(v));
    //JSON.decodeFile("/home/blackdog/Projects/hxClosure/woot");
  }

}