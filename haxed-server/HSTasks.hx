

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
    var
      vd = ClientTools.versionDir("haxed-server"),
      src = vd +"www",
      dst = Os.cwd();
    
    Os.copyTree(src,dst);
    Os.cp(vd+"server.json.sample","server.json");
    Os.cp(vd+"start","start");
    Os.copyTree(vd+"nginx",dst);
    Os.mkdir("./logs");
    
    return "copied "+src+" to "+dst;
  }

  public function
  makeRepo() {
    Os.mkdir("./repo/__files__/");
    return "made repo dir";
  }
}