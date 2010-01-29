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
    for (l in d) {
      sb.add(" -lib ");
      sb.add(l.prj) ;
    }
    return sb.toString();
  }

  static
  function getCps(classpaths:Array<String>) {
    var f = new StringBuf();
    for (c in classpaths)
      f.add(" -cp " + c);
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
  compile(c:Config) {
    var b = c.build();
    trace(b);
    var ctx = { MAIN:b.mainClass,
                LIBS:getLibs(b.depends),
                CPS:getCps(b.classPath),
                TT:b.target,
                TARGET: b.targetFile ,
                OTHER: (b.options != null) ? b.options.join(" ") : ""};

    
    var o = (Os.shell("haxe ::OTHER:: -main ::MAIN:: ::LIBS:: ::CPS:: -::TT:: ::TARGET::",true,ctx)),
      filtered = o.split("\n")
      .filter(function(l) {return l.trim() != ""; })
      .array()
      .join("\n");
    
  }
  
}
