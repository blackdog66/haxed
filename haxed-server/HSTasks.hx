

import haxed.Tasks;
import haxed.ClientTools;

import bdog.Os;

class HSTasks extends TaskRunner {

  public static function
  main() {
    var tasks = new HSTasks();
    tasks.run();
  }

  public function
  copyWWW() {
    var src = ClientTools.versionDir("haxed-server")+"www",
      dst = Os.cwd();
    Os.copyTree(src,dst);
    return "copied "+src+" to "+dst;
  }
}