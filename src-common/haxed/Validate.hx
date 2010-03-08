
package haxed;

import haxed.Parser;
import haxed.Common;
import bdog.Os;
using Lambda;
using StringTools;

// this needs to be in a separate file as i want to 'using Validate'

private typedef Valid = {
  var required:Bool;
  var valid:String->Dynamic;
}

class Validate {
  static var sections = new Hash<Hash<Valid>>();
  static var reSplit = ~/\s+/g;
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
  
  public static function
  directories(s:String):Array<String> {
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
    Os.println("Failed validation for "+section+":"+fld+" "+msg);
    Os.exit(1);
  }

  public static function
  warn(msg:String,section:String,?fld:String) {
    Os.println("Warning: "+section + ((fld != null) ? ":"+ fld : "") +" "+msg);
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
  
  static function
  getSection(c:Config,type:String,name:String):Dynamic {
    if (name == null) {
      return c.section(type);
    } else {
      if (type == Config.BUILD) {
        for (b in c.build()) {
          if (b.name == name)
            return b;
        }
      }
      if (type == Config.TASK) {
        for (tsk in c.tasks()) {
          if (tsk.name == name)
            return tsk;
        }
      }
    }
      
    return null;
  }
  
  public static function
  applyAllTo(hxp:Hxp) {
    var config = new Config(hxp.hbl);

    #if debug
    trace("section order is "+hxp.sectionOrder);
    #end
    
    var sectionCopy = Reflect.copy(hxp.hbl);
    for (sectionID in hxp.sectionOrder) {
      var
        comp = sectionID.split("___"),
        sectionType,
        sectionName;

      if (comp.length == 1) {
        sectionName = null;
        sectionType = sectionID;
      } else {
        sectionType = comp[0];
        sectionName = comp[1];
      }

      var 
        vds = sections.get(sectionType),
        section:Dynamic = getSection(config,sectionType,sectionName);

      if (section == null) continue; // don't bother checking a section which is not defined


#if debug
      Os.printlnln("Validating "+sectionID);
#end
      
      var fldCopy = Reflect.copy(section);
      
      // for fields with validations attached ...
      if (vds != null) {
        for (fld in vds.keys()){
          var
            constraint = vds.get(fld),
            givenVal:String = Reflect.field(section,fld);
          
          if (constraint.required && givenVal == null)
            err(" is required",sectionID,fld);
          
          if (givenVal == null)
            continue;
          
          //          givenVal = script(givenVal,sectionID);
          
          if (constraint.valid != null) {
            givenVal = constraint.valid(givenVal);
            if (givenVal == null) err("",sectionID,fld);
          }
          
          // remove validated field from all fields 
          Reflect.deleteField(fldCopy,fld);
          
          // update field with the validated value

          //trace("validated update: "+fld + " with "+givenVal);
          Reflect.setField(section,fld,givenVal);
          
        }
      }
      
      // find which fields are left which have not been validated
      for (w in Reflect.fields(fldCopy)) {
        //var f = Reflect.field(section,w);
        //var newVal = script(f,sectionID);
        //Reflect.setField(section,w,newVal);
        //                trace("unValidated update: "+f + " with "+newVal);
        //warn("is not a validated key",section,w); 
      }
      
      // remove validated section from all sections
      Reflect.deleteField(sectionCopy,sectionID);
      
    }
    
    // find which sections are left which have not been validated
    //    for (sw in Reflect.fields(sectionCopy)) {
    //  warn("is not a validated section",sw); 
    //}
    
  }
  
}
