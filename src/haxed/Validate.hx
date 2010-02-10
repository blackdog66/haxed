
package haxed;

import haxed.Parser;
import haxed.Common;

using Lambda;
using StringTools;

// this needs to be in a separate file as i want to 'using Validate'

private typedef Valid = {
  var required:Bool;
  var valid:String->Dynamic;
}

class Validate {
  static var sections = new Hash<Hash<Valid>>();
  static var reSplit = ~/\s/g;
  static var reAlphanum = ~/^[A-Za-z0-9_.-]+$/;
  static var reDir = ~/^[A-Za-z_0-9]/;

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
  toArray(s) {
    return Lambda.map(reSplit.split(s),StringTools.trim).array();
  }

  public static function
  splitOnNewline(s) {
    return Lambda.map(~/\n/g.split(s),StringTools.trim).array();
  }
  
  public static function
  splitOnComma(s) {
    return Lambda.map(~/,/g.split(s),StringTools.trim).array();
  }
  
  public static function directories(s:String):Array<String> {
    var f = function(el:String) {
      var trimmed = el.trim();
      if (reDir.match(el.charAt(0)))
        return "./"+trimmed;
      if (trimmed == ".")
        return "./";
      
      return trimmed;
    };
    return Lambda.map(reSplit.split(s),f).array();

  }
  
  public static function
  name(v:String):String {
    if (reAlphanum.match(v)) return v;
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
    if (z == "swf" || z == "neko" || z == "js" || z == "cpp" || z == "php" || z == "swf9" || z == "as3")
      return z;
    return null;
  }

  public static function
  err(msg,section,fld) {
    neko.Lib.println("Failed validation for "+section+":"+fld+" "+msg);
    neko.Sys.exit(1);
  }

  public static function
  warn(msg:String,section:String,?fld:String) {
    neko.Lib.println("Warning: "+section + ((fld != null) ? ":"+ fld : "") +" "+msg);
  }

  public static function
  optionalEmail(v:String):String {
    if (v.length > 0) return email(v);
    return v;
  }
  
  public static function
  password(v:String):String {
    return (v.length >= 5) ? v : null;
  }

  public static function
  optPassword(v:String):String {
    if (v.length > 0) return password(v);
    return null;
  }

  public static function
  path(v) {
    return (Os.exists(v)) ? v : null;
  }

  public static function
  zip(v) {
    return (StringTools.endsWith(v,".zip") && Os.exists(v)) ? v : null; 
  }
  
  public static function
  applyAllTo(hxp:Hxp) {
    var sectionCopy = Reflect.copy(hxp.hbl);
    for (section in sections.keys()) {
      var
        vds = sections.get(section),
        mf = Reflect.field(hxp.hbl,section),
        ma:Array<Dynamic>;

      if (mf == null) continue; // don't bother checking a section which is not defined


#if debug
      neko.Lib.println("Validating "+section);
#end
      // just make every element an array even if it isn't to make life easier
      if (Std.is(mf,Array))
        ma = mf;
      else
        ma = [mf];

 #if debug
      var i = 0;
#end
      for (s in ma) {

#if debug    
        if (Reflect.field(s,"name") != null)
          neko.Lib.println("    checking "+s.name);
        else
          neko.Lib.println("    checking element "+i++);
#end
        
        var fldCopy = Reflect.copy(s);
      
        for (fld in vds.keys()){
          var
            constraint = vds.get(fld),
            givenVal = Reflect.field(s,fld);
          
          if (constraint.required && givenVal == null)
            err(" is required",section,fld);
          
          if (givenVal == null)
            continue;
          
          if (constraint.valid != null) {
            givenVal = constraint.valid(givenVal);
            if (givenVal == null) err("",section,fld);
          }
          
          // remove validated field from all fields 
          Reflect.deleteField(fldCopy,fld);
          
          // update field with the validated value
          Reflect.setField(s,fld,givenVal);            
        }
      

      // find which fields are left which have not been validated
      for (w in Reflect.fields(fldCopy)) {
        warn("is not a validated key",section,w); 
      }
      // remove validated section from all sections
      Reflect.deleteField(sectionCopy,section);
      }

    }

    // find which sections are left which have not been validated
    for (sw in Reflect.fields(sectionCopy)) {
      warn("is not a validated section",sw); 
    }
   
  }
  
}
