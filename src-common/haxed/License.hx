package haxed;

import haxed.Common;

using Lambda;

class License {

  static var licenses:Array<LicenseSpec>;
  static var pubLic = ["GPL","LGPL","BSD","PublicDomain","Apache"];
  public static function
  set(l:Array<LicenseSpec>) {
    licenses = l;
  }
  
  public static function
  getAll() {
    return licenses;
  }

  static function
  find(l:String):LicenseSpec {
    return licenses.filter(function(el) {
        return el.name == l;
      }).first();
  }

  public static function
  isPublic(license:String):Bool {
    /*
    var l = find(license) ;
    if (l != null)
      return l.pub == true;
    */
    for (l in pubLic)
      if (license == l)
        return true;
    return false;
  }
  
  public static function
  getUrl(license:String):String {
    return find(license).url;
  }
}