package haxed;

import haxed.Common;
import haxed.Os;
import haxed.ClientCore;

using Lambda;
using StringTools;

enum TargetType {
  JS;
  NEKO;
  SWF;
  PHP;
  CPP;
}

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
      paths = ClientCore.internalPath(d),
      sb = new StringBuf();

    for (p in paths) {
      sb.add(" -cp ");
      sb.add(p) ;
    }
    
    return sb.toString();
  }

  static function
  getCps(classpaths:Array<String>) {
    var f = new StringBuf();
    if (classpaths != null) {
      for (c in classpaths)
        f.add(" -cp " + c);
    } else
      f.add("");
    return f.toString();
  }

  static function
  getTargetType(tt:TargetType) {
    return switch (tt) {
    case JS: "js";
    case NEKO: "neko";
    case SWF: "swf";
    case PHP: "php";
    case CPP: "cpp";
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
