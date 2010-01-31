package haxed;

import haxed.Os;
import haxed.Common;

class Package {

  public static var packDir = "/tmp/haxed-pkg/";

  public static function
  outFile(name:String,hblFile:String) {
    var p  = neko.io.Path.directory(hblFile);
    if (p != "")
      return Common.slash(p) + name;
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

  /*
  ::foreach mytags::
    <tag v="::tag::"/>
::end::
  */
  static function
  packageXml(conf:Config) {
    var
      glbs = conf.globals(),
      tags = Lambda.map(Reflect.hasField(glbs, "tags") ? glbs.tags : new Array<String>(),function(el) { return { tag : el };}),
      tmpl =  '
<project name="::glbs.name::" url="::glbs.website::" license="::glbs.license::">
    <user name="mylogin"/>

    <description>::glbs.description::</description>
    <version name="::glbs.version::">::glbs.comments::</version>
</project>';

    return new haxe.Template(tmpl).execute({mytags:tags,glbs:glbs});

  }

  public static function
  packageJson(conf:Config) {
    return hxjson2.JSON.encode(conf.data) ;
  }

  public static function
  sources(conf:Config) {
    var
      libs = conf.build(),
      include = Reflect.field(conf.pack(),"include"),
      exclude = if (include != null)
      	function(s:String) {
          return !Lambda.exists(include,function(el)
        	{ return StringTools.startsWith(s,el); });
      	} else null;

    if (Reflect.hasField(libs, "classPath") && libs.classPath != null){
      Lambda.iter(libs.classPath,function(d) {
          if (!Os.exists(d))
            throw "Source dir "+d+" does not exist";
          Os.copyTree(Common.slash(d),packDir,exclude);
        });
    }
  }

  public static function
  xml(conf:Config) {
    var glbs = conf.globals();
    Os.fileOut(toPackDir("haxed.xml"),packageXml(conf));
  }

  public static function
  json(conf:Config) {
    Os.fileOut(toPackDir(Common.CONFIG_FILE),packageJson(conf));
  }

  public static function
  zip(conf:Config) {
    var name = conf.globals().name+".zip";
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
      xml(config);
      json(config);
      return zip(config);
  }
}