

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

    try {
    Os.copyTree(src,dst);
    var cfg = Os.fileIn(vd+"server.json.template");
    Os.fileOut(dst+"/server.json",cfg,{dataDir:dst+"repo/"});
    Os.cp(vd+"start","start");
    Os.command("chmod +x start");
    Os.copyTree(vd+"nginx",dst);
    Os.mkdir("./logs");
    Os.mkdir("./repo");
    } catch(ex:Dynamic) {
      return ex.toString + "tried "+src+" to "+dst;
    }
    return "copied "+src+" to "+dst;
  }

}