package haxed;

import haxed.Common;
import haxed.Os;
using Lambda;
using StringTools;

enum TargetType {
	JS;
	NEKO;
	SWF;
}

class Builder {

  static var libs:String;
  
  static function getLibs(d:Array<PrjVer>) {
    var sb = new StringBuf();
    if (d != null){
      for (l in d) {
        sb.add(" -lib ");
        sb.add(l.prj) ;
      }
    } else
      sb.add("");
    
    return sb.toString();
  }

  static
  function getCps(classpaths:Array<String>) {
    var f = new StringBuf();
    if (classpaths != null) {
      for (c in classpaths)
        f.add(" -cp " + c);
    } else
      f.add("");
    return f.toString();
  }

  static
  function getTargetType(tt:TargetType) {
    return switch (tt) {
    case JS: "js";
    case NEKO: "neko";
    case SWF: "swf";
    };
  }

  public static function
  compile(c:Config,target:String) {
    var builds = c.build();
    for (b in builds) {
      if (b.name == target || b.name == null || target == "all") {
      var ctx = { MAIN:b.mainClass,
                LIBS:getLibs(b.depends),
                CPS:getCps(b.classPath),
                TT:b.target,
                TARGET: b.targetFile ,
                OTHER: (b.options != null) ? b.options.join(" ") : ""};

      neko.Lib.println("Building "+target);
    
      var o = (Os.shell("haxe ::OTHER:: -main ::MAIN:: ::LIBS:: ::CPS:: -::TT:: ::TARGET::",true,ctx)),
        filtered = o.split("\n")
        .filter(function(l) {return l.trim() != ""; })
        .array()
        .join("\n");
      
    }
    }
  }
  
}
