package tools.haxelib;

using Lambda;

class License {
  static var LICFILE = "licenses.json";
  
  static var licenses =  [
    { name:"GPL", url : "http://www.gnu.org/licenses/gpl.html" },
    { name:"LGPL" , url :"http://www.gnu.org/licenses/lgpl-3.0.html"},
    { name: "BSD", url : "http://www.linfo.org/bsdlicense.html"},
    { name: "PublicDomain", url:"http://creativecommons.org/licenses/publicdomain/"}
  ];
  
 public static function
 getFromFile(dataDir:String) {

   if (!Os.exists(dataDir + LICFILE)) {
      // then generate one
     Os.fileOut(dataDir + LICFILE,hxjson2.JSON.encode(licenses));
    }

   return hxjson2.JSON.decode(Os.fileIn(dataDir + LICFILE));
 }

  public static function
  getPublic() {
    return licenses;
  }

  public static function
  getText(license:String) {
    var l = null;
    try {
      l = haxe.Resource.getString(license);
    } catch(exc:Dynamic) {
      trace("license not found");
    }
    return l;
  }

  static function
  find(l:String) {
    return licenses.filter(function(el) {
        return el.name == l;
      }).first();
  }

  public static function
  isPublic(license:String) {
    return find(license) != null;
  }
  
  public static function
  getUrl(license:String) {
    return find(license).url;
  }
}