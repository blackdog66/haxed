package haxed;

import haxed.Os;
import haxed.Common;

class Package {

  public static var packDir = "/tmp/haxed-pkg/";

  public static function
  confDir(confFile:String) {
    var p  = neko.io.Path.directory(confFile);
    if (p == "") p = Os.cwd();
    return Common.slash(p);
  }
  
  public static function
  outFile(name:String,confFile:String) {
    return confDir(confFile) + name;
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
      libs = conf.build()[0],
      include = Reflect.field(conf.pack(),"include");

    /*
      exclude = if (include != null)
      	function(s:String) {
          return !Lambda.exists(include,function(el)
        	{ return StringTools.startsWith(s,el); });
      	} else null;
    */

    if (libs == null && include == null) {
      Os.copyTree("./",packDir); // relying on having CD'd to the conf dir already
    } else {
      
      if (Reflect.hasField(libs, "classPath") && libs.classPath != null){
        Lambda.iter(libs.classPath,function(d) {
            if (!Os.exists(d))
              throw "class-path dir "+d+" does not exist";
            Os.copyTree(Common.slash(d),packDir);
          });
      }

      if(include != null) {
        Lambda.iter(include,function(d) {
            if (!Os.exists(d))
              throw "include dir "+d+" does not exist";
            Os.copyTree(Common.slash(d),packDir);
          });
      }
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
  createFrom(confDir:String,config:Config) {
    Os.cd(confDir);
    trace("CD'd to "+confDir);
    initPackDir();
    sources(config);
    xml(config);
    json(config);
    return zip(config);
  }
}