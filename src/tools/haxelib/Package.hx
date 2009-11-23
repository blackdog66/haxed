package tools.haxelib;

import tools.haxelib.Habal;
import tools.haxelib.Os;


class Package {

  public static var packDir = "/tmp/haxelib-pgk/";
  
  public static
  function outFile(name:String,hblFile:String) {
    var p  = neko.io.Path.directory(hblFile);
    return p + "/" + name;
  }

  public static inline
  function toPackDir(fn) {
    return packDir + fn;
  }

  public static
  function initPackDir() {
    Os.mkdir(packDir);
  }

  static
  function packageXml(hbl:Habal) {
    var
      glbs = hbl.globals(),
      tags = Lambda.map(glbs.tags,function(el) { return { tag : el };}),
      tmpl =  '
<project name="::glbs.name::" url="::glbs.url::" license="::glbs.license::">
    <user name="mylogin"/>
::foreach mytags::
    <tag v="::tag::"/>
::end::
    <description>::glbs.description::</description>
    <version name="::glbs.version::">::glbs.synopsis::</version>
</project>';

    return new haxe.Template(tmpl).execute({mytags:tags,glbs:glbs});
    
  }

  public static
  function packageJson(hbl:Habal) {
    return hxjson2.JSON.encode(hbl) ;
  }
  
  public
  static function sources(hbl:Habal) {
    var
      libs = hbl.library();
      Lambda.iter(libs.sourceDirs,function(d) {
          if (!Os.exists(d))
            throw "Source dir "+d+" does not exist";
          Os.copyTree(Os.slash(d),packDir);
        });
  }

  public static
  function xml(hbl:Habal) {
    var
      glbs = hbl.globals();
    Os.fileOut(toPackDir("haxelib.xml"),packageXml(hbl));
  }

  public static
  function json(hbl:Habal) {
    Os.fileOut(toPackDir("haxelib.json"),packageJson(hbl));
  } 

  public static
  function zip(hbl:Habal) {
    var name = hbl.globals().name+".zip";
    Os.zip(outFile(name,hbl.file),Os.files(packDir),packDir);
  }
  
  public static
  function createFrom(hblFile:String) {
    if (Os.exists(hblFile)) {
      initPackDir();
      var hbl = HblTools.process(hblFile);
      sources(hbl);
      xml(hbl);
      json(hbl);
      zip(hbl);
    } else throw "package: "+hblFile + "does not exist!"; 
  }

  
}