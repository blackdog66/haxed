package tools.haxelib;

import tools.haxelib.Os;
import tools.haxelib.Config;


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
  function packageXml(conf:Config) {
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

  public static
  function packageJson(conf:Config) {
    return hxjson2.JSON.encode(conf) ;
  }
  
  public
  static function sources(conf:Config) {
    var
      libs = conf.library();
      Lambda.iter(libs.sourceDirs,function(d) {
          if (!Os.exists(d))
            throw "Source dir "+d+" does not exist";
          Os.copyTree(Os.slash(d),packDir);
        });
  }

  public static
  function xml(conf:Config) {
    var
      glbs = conf.globals();
    Os.fileOut(toPackDir("haxelib.xml"),packageXml(conf));
  }

  public static
  function json(conf:Config) {
    Os.fileOut(toPackDir("haxelib.json"),packageJson(conf));
  } 

  public static
  function zip(conf:Config) {
    var name = conf.globals().name+".zip";
    Os.zip(outFile(name,conf.file()),Os.files(packDir),packDir);
  }
  
  public static
  function createFrom(config:Config) {
      initPackDir();
      sources(config);
      xml(config);
      json(config);
      zip(config);
  }

  
}