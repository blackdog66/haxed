package tests;
import haxe.Timer;

class NekoTest {
  public static
  function main() {
    var done = false;
    haxe.Timer.delay(function() {
        trace("woot");
        done = true;
      }, 10000);

    while(!done) {
      neko.Sys.sleep(1);
    }
  }
}



