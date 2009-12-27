
package tools.haxelib;
import tools.haxelib.Config;
import tools.haxelib.Parser;
import tools.haxelib.Common;

using Lambda;

// this needs to be in a separate file as i want to 'using Validate'

private typedef Valid = {
  var required:Bool;
  var valid:String->Dynamic;
}

class Validate {
  static var sections = new Hash<Hash<Valid>>();
  static var reSplit = ~/\s/;

  public static function
  forSection(s:String):Hash<Valid> {
    if (!sections.exists(s)) {
      sections.set(s,new Hash<Valid>());
    }          
    return sections.get(s);
  }

  public static function
  add(sv:Hash<Valid>,n:String,required:Bool,?valid:String->Dynamic) {
    sv.set(Common.camelCase(n),{required:required,valid:valid}); 
    return sv;
  }

  public static function
  url(v) {
    var r = ~/^(http:\/\/)([^:\/]+)(:[0-9]+)?\/?(.*)$/;
    if (r.match(v)) return v;
    return null;
  }

  public static function
  email(v:String) {
    var emailRe = ~/[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z][A-Z][A-Z]?/i;
    if (emailRe.match(v)) return v;
    return null;
  }

  public static function
  spaceSeparated(s) {
    return Lambda.map(reSplit.split(s),function(el)
                      { return StringTools.trim(el); }).array();
  }

  public static function
  name(v:String):String {
    var alphanum = ~/^[A-Za-z0-9_.-]+$/;
    if (alphanum.match(v)) return v;
    return null;
  }

  public static function
  depends(str:String):Array<PrjVer> {
    return str.split(",")
      .map(function(el) {
          var
            t = StringTools.trim(el),
            parts = t.split(" "),
            lp = parts.length;
          
          if (lp == 2) return { prj:parts[0],ver:parts[1],op:null };
          if (lp == 3) return { prj:parts[0],ver:parts[2],op:parts[1] };
          return { prj:parts[0],ver:null,op:null };
          
        }).array();
  }

  public static function
  target(v:String) {
    var z = v.toLowerCase();
    if (z == "swf" || z == "neko" || z == "js" || z == "cpp")
      return z;
    return null;
  }

  public static function
  err(msg,section,fld) {
    neko.Lib.println("Failed validation for "+section+":"+fld+" "+msg);
    neko.Sys.exit(1);
  }
 
  public static function
  applyToAll(hxp:Hxp) {
    for (section in sections.keys()) {
      var
        vds = sections.get(section),
        s = Reflect.field(hxp.hbl,section);
      for (fld in vds.keys()){
        var
          constraint = vds.get(fld),
          givenVal = Reflect.field(s,fld);
        
        if (constraint.required && givenVal == null)
          err(" is required",section,fld);
        
        if (constraint.valid != null) {
          givenVal = constraint.valid(givenVal);
          if (givenVal == null) err("",section,fld);
        }
        
        Reflect.setField(s,fld,givenVal);            
      }
    }
  }
  
}
