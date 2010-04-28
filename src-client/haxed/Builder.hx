package haxed;

import bdog.Os;
import haxed.Common;
import haxed.ClientTools;

using Lambda;
using StringTools;

class Builder {

  static var libs:String;

  /*
    Convert any library references to classpaths, so that when the haxe compiler is
    called it's not called with -lib which will relies on executing haxelib -path which
    could be the old exectutable
  */
  static function
  getLibs(d:Array<PrjVer>) {
    var
      paths = ClientTools.internalPath(d),
      sb = new StringBuf();

    for (p in paths) {
      sb.add(" -cp ");
      sb.add(p) ;
    }
    
    return sb.toString().trim();
  }

  static function
  getCps(classpaths:Array<String>,libRoot = "") {
    var f = new StringBuf();
    if (classpaths != null) {
      for (c in classpaths) {
        if (libRoot.length > 0)
          f.add(" -cp " + ((c.startsWith("./")) ? libRoot + c.substr(2) : c));
        else
          f.add(" -cp " + c);
      }
    } else
      f.add("");
    return f.toString().trim();
  }

  public static function
  compile(c:Config,target:String,fromLib:Bool) {
    var
      builds = c.build(),
      libRoot =  (fromLib) ? ClientTools.versionDir(c.globals().name) : null;

    compileBuild(builds,target,libRoot,c.getDepends());
   
  }
  
  public static function
  compileBuild(builds:Array<Build>,target:String,?libRoot:String,deps:Array<PrjVer>) {
    for (b in builds) {
      if (b.name == target || b.name == null || target == "all") {

        var haxe_library_path = Os.env("HAXE_LIBRARY_PATH");
        if (haxe_library_path != null)
          b.classPath.push(haxe_library_path);
        
        //b.classPath.push(ClientTools.versionDir("haxed"));
        
        var
          allDeps = (b.depends != null) ? b.depends.concat(deps) : deps,
          ctx = {
        	MAIN:b.mainClass,
            LIBS:getLibs(allDeps),
            CPS:getCps(b.classPath,libRoot),
            TT:b.target,
            TARGET: b.targetFile ,
            OTHER: (b.options != null) ? b.options.join(" ").trim() : ""
        };

      Os.println("Building "+b.name+" with "+b.classPath+" options "+b.options);

      Os.process("haxe -main ::MAIN:: -::TT:: ::TARGET:: ::LIBS:: ::CPS:: ::OTHER::",false,ctx,function(o) {
          Os.println(o.split("\n")
                     .filter(function(l) {return l.trim() != ""; })
                     .array()
                     .join("\n"));
        });
      
      }
      
    }
  }
  
}
