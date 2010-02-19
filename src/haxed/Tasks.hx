
package haxed;

import haxed.Common;
import haxed.Os;
import haxed.Builder;

using StringTools;

class TaskRunner {
  
  public function new() {}
  
  public function run() {
    var args = neko.Sys.args() ;
    var task:String;
    
    if (args.length > 0)
      task = args[0];
    else
      task = "default";
    
    var prms = new Array<String>();
    if (args.length > 1)
      prms = args.slice(1);
    else
      prms = [];

    var fn = Reflect.field(this,task);
    if (fn == null) throw("Task "+task+" does not exist");

    //  throw("call is "+task+", prms are "+prms);
    if (Reflect.isFunction(fn)) {
      neko.Lib.println(Reflect.callMethod(this,fn,prms));
    }
       
  }
}

class Tasks {

  static var HAXED_DIR = "./.haxed/";
  static var TASK_DIR = HAXED_DIR+"tasks/";
  static var CP_DIR = HAXED_DIR+"src/";
  
  var task:Task;
  var exeName:String;

  public static function init() {
     if (!Os.exists(TASK_DIR))
      Os.mkdir(TASK_DIR);

     if (!Os.exists(CP_DIR+"haxed"))
       Os.mkdir(CP_DIR+"haxed");

     var tasksFile = CP_DIR+"haxed/Tasks.hx"; 
     if(!Os.exists(tasksFile)) {
       Os.fileOut(tasksFile,haxe.Resource.getString("tasks_hx"));
       // if we need Tasks.hx need these too ...
       Os.fileOut(CP_DIR+"haxed/Os.hx",haxe.Resource.getString("os_hx"));
       Os.fileOut(CP_DIR+"haxed/Common.hx",haxe.Resource.getString("common_hx"));
       Os.fileOut(CP_DIR+"haxed/Builder.hx",haxe.Resource.getString("builder_hx"));
       Os.fileOut(CP_DIR+"haxed/ClientTools.hx",haxe.Resource.getString("tools_hx"));
       Os.fileOut(CP_DIR+"haxed/SyntaxTools.hx",haxe.Resource.getString("syntax_hx"));
       Os.fileOut(CP_DIR+"haxed/JSON.hx",haxe.Resource.getString("json_hx"));
     }
  }
  
  public static function
  run(task:Task,?prms:Array<Dynamic>) {
    var t = new haxed.Tasks(task);
    t.execute(prms);
  }
  
  public function new(t:Task,?taskID:String) {

    task = t;
    
    if (taskID == null)
      exeName = TASK_DIR+task.name+".n";
    else
      exeName = TASK_DIR+taskID+".n";
  }

  public function
  outputFile() {
    return exeName;
  }
  
  public function
  execute(?prms:Array<Dynamic>,?cliOptions:Options,forceBuild=false) {    
    var
      doBuild = forceBuild;

    if (cliOptions != null) {
      if (cliOptions.flag("-compile") && Os.exists(TASK_DIR)) {
        Os.rm(exeName);
      }
    }

    if (Os.exists(exeName)) {
      if (Os.newer(task.mainClass+".hx",exeName)) {
        Os.print("Recompiling: " + task.mainClass+ ".hx is newer than "+ exeName);
        doBuild = true;
      }
    }

    var
      cp = task.classPath,
      defaultClasspaths = [".",CP_DIR];

    if (cp == null)
      cp = defaultClasspaths;
    else
      cp = cp.concat(defaultClasspaths);
    
    trace("classpaths are "+cp);
    
    if (doBuild) {
      var build:Build = {
      name:task.name,
      classPath:cp,
      target:(task.target == null) ? "neko" : task.target,
      targetFile:(task.targetFile == null) ? exeName : task.targetFile,
      mainClass:(task.mainClass == null) ? "Tasks" : task.mainClass,
      depends:task.depends,
      options:task.options,
      preTask:null, // a task doesn't have a pre and post, but add for compiler
      postTask:null
      };

      Builder.compileBuild([build],"all");
    }
    
    var sb = new StringBuf();
    if (prms != null)
      for (p in prms) sb.add(p +" ");
    
    trace(Os.shell("neko "+exeName + " "+task.name+" "+sb.toString().trim()));
    
  }
    
}