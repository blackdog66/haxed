
package haxed;

import haxed.Common;
import haxed.Os;

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

  var task:Task;
  
  public function new(t:Task) {
    task = t;
  }

  public function
  execute(prms:Array<Dynamic>,cliOptions:Options) {
    var build:Build = {
    	name:task.name,
    	classPath:(task.classPath != null) ? task.classPath : ["."],
    	target:(task.target == null) ? "neko" : task.target,
    	targetFile:(task.targetFile == null) ? ".haxed.n" : task.targetFile,
    	mainClass:(task.mainClass == null) ? "Tasks" : task.mainClass,
    	depends:task.depends,
    	options:task.options
    };

    Builder.compileBuild([build],"all");
    
    var sb = new StringBuf();
    for (p in prms) sb.add(p +" ");
    
    trace(Os.shell("neko .haxed.n "+ task.name + " "+sb.toString().trim()));
    
  }
    
}