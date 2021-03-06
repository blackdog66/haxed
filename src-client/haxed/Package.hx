package haxed;

import bdog.Os;
import bdog.Zip;
import haxed.Common;
import bdog.JSON;

using StringTools;
using Lambda;

class Package {

  public static var packDir = "/tmp/haxed-pkg/";
  static var defaultExcludes =  [".git",".svn","CVS",".haxed"];
  
  public static function
  confDir(confFile:String) {
    var p  = neko.io.Path.directory(confFile);
    if (p == "") p = Os.cwd();
    return Os.slash(p);
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
    return JSON.encode(conf.data) ;
  }

  public static function
  sources(confDir:String,conf:Config) {

    Os.cd(confDir);
    
    var
      include = Reflect.field(conf.pack(),"include"),
      builds = conf.build();
    
      if (builds != null) {
        for (b in builds) {
          if (Reflect.hasField(b, "classPath") && b.classPath != null){

#if debug
            trace("classpaths for build :"+b.name+" are "+b.classPath);
#end

            Lambda.iter(b.classPath,function(d) {
                if (!Os.exists(d))
                  throw "class-path dir "+d+" does not exist";
                
                // only copy a classpath tree if it's external to the package dir
                if (!d.startsWith("./"))
                  Os.copyTree(Os.slash(d),packDir);
              });
          }
        }
      }
      
      if (include != null) {
        var
          excludes = ((conf.pack().exclude != null) ? conf.pack().exclude : [])
          	.map(function(el) {
              return (el.startsWith("./")) ? el.substr(2) : el ;
            })
          .array().concat(defaultExcludes),
          len = excludes.length,
          excluder = function(s:String) {
          	for (i in 0...len) {
              if (s.startsWith(excludes[i]))
                return true;
            }
            return false;
          }
#if debug        
trace("excludes are "+excludes);
#end
        Lambda.iter(include,function(d) {
            if (!Os.exists(d))
              throw "include dir "+d+" does not exist";
            
            if (Os.isDir(d)) {
              Os.copyTree(Os.slash(d),packDir,excluder);
            } else {
              var norelatives = ~/(\.{1,2}\/)/g.replace(d,"");
              var p = Os.path(norelatives,DIR);
              if (p != null)
                Os.mkdir(packDir+p);
              Os.cp(d,packDir+norelatives);
            }
          });
      }

      // so if nothing was built or included just bring everthing in ...
      // relying on having CD'd to the conf dir already
      
      if (builds == null && include == null) {
        var
          len = defaultExcludes.length,
          excluder = function(s:String) {
          	for (i in 0...len) {
              if (s.startsWith(defaultExcludes[i]))
                return true;
            }
            return false;
          }

        Os.copyTree("./",packDir,excluder); 
      }
  }

  public static function
  xml(conf:Config) {
    var glbs = conf.globals();
    Os.write(toPackDir("haxelib.xml"),packageXml(conf));
  }

  public static function
  json(conf:Config) {
    Os.write(toPackDir(Common.CONFIG_FILE),packageJson(conf));
  }

  public static function
  zip(conf:Config) {
    var name = conf.globals().name+".zip";
    var outf = outFile(".haxed/"+name,conf.file());
    Zip.zip(outf,Os.files(packDir,null),packDir);
    trace("Created "+outf);
    return outf;
  }

  public static function
  createFrom(confDir:String,config:Config) {
    initPackDir();
    sources(confDir,config);
    xml(config);
    json(config);

    var cf = toPackDir(config.file());
    if (!Os.exists(cf)) {
      Os.cp(config.file(),cf);
    }
    
    return zip(config);
  }
}