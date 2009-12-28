package tools.haxelib;

import tools.haxelib.Os;
import tools.haxelib.Config;

class Package {

  public static var packDir = "/tmp/haxelib-pkg/";
  
  public static function
  outFile(name:String,hblFile:String) {
    var p  = neko.io.Path.directory(hblFile);
    if (p != "")
      return p + "/"+ name;
    return name;
  }

  public static inline function
  toPackDir(fn) {
    return packDir + fn;
  }

  public static function
  initPackDir() {
    if (Os.exists(packDir))
      Os.rmdir(packDir);
    Os.mkdir(packDir);
  }

  static function
  packageXml(conf:Config) {
    var
      glbs = conf.globals(),
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

  public static function
  packageJson(conf:Config) {
    return hxjson2.JSON.encode(conf.data) ;
  }
  
  public static function
  sources(conf:Config) {
    var libs = conf.build();
    if (libs.classPath != null)
      Lambda.iter(libs.classPath,function(d) {
          if (!Os.exists(d))
            throw "Source dir "+d+" does not exist";
          Os.copyTree(Common.slash(d),packDir);
        });
  }

  public static function
  xml(conf:Config) {
    var glbs = conf.globals();
    Os.fileOut(toPackDir("haxelib.xml"),packageXml(conf));
  }

  public static function
  json(conf:Config) {
    Os.fileOut(toPackDir(Common.HXP_FILE),packageJson(conf));
  } 

  public static function
  zip(conf:Config) {
    var name = conf.globals().project+".zip";
    var outf = outFile(name,conf.file());
    trace("Zipping:"+outf);
    Os.zip(outf,Os.files(packDir),packDir);
    trace("Created "+outf);
    return outf;
  }
  
  public static function
  createFrom(config:Config) {
      initPackDir();
      sources(config);
      //   xml(config);
      json(config);
      return zip(config);
  }  
}