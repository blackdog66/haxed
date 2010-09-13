package bdog;

#if neko
import neko.io.FileOutput;
import neko.io.File;
#elseif php
import php.io.FileOutput;
import php.io.File;
#end

class Log {

  public static var logOn = true;
  public static var traceOn = false;
  static var logs:Hash<FileOutput> = new Hash();
  static var logFile = "default";
  static var logDir ;

  public function new(dir:String,lf:String) {
    if (!Os.exists(dir))
      bdog.Os.mkdir(dir);
    logDir = dir;
    logFile = lf;
  }

  public static function
  tr(s:String,f="errs") {
    new Log("./",f).p(s);
  }
  
  public
  function p(s:String,?indent:Int=0) {
    var sb = new StringBuf();
    for (i in 0...indent) sb.add("\t");
    var f = sb.toString()+s;

    if (logDir != null && Os.exists(logDir)) {

      var log:FileOutput,
        lf = logDir + "/" + logFile + ".log";

      if (!Os.exists(lf)) {
        var f = File.write(lf,false) ;
        f.writeString("");
        f.flush();
        f.close();
      }

      if (!logs.exists(logFile)) {
        log = File.append(lf,false);
        logs.set(logFile,log);
      } else
        log = logs.get(logFile);

      log.writeString(f+"\n");
    } else {
      //if (traceOn)
      Os.println(f);
    }
  }


  public
  function print(msg:String,level=1) {
    if (msg == null) return;
      
    var m = switch(level) {
    case 0:
    msg;
    case 1:
    "["+msg+"]";
    case 2:
    "[["+msg+"]]";
    case 3:
    "[[["+msg+"]]]";
    }
      
    if (msg.length>0)
      Os.println(m);
  }

}
