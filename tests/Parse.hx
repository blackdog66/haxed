package tests;

import tools.haxelib.Os;
import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Config;

import utest.Assert;

class Parse {

  public static var testFile = "./test.hbl";

  var hbl:Habal;
  var conf:Config;

  public function new() {}
  
  public
  function setup() {
    hbl = HblTools.process(testFile);
    conf = HblTools.getConfig(hbl);
  }
  
  public function
  testGlobals() {
    var globals = conf.globals();
    Assert.isFalse(globals == null);
    Assert.equals(globals.synopsis,"freeform");
    Assert.equals(globals.name,"project-name");
    Assert.isTrue(Std.is(globals.tags,Array));

  }

  public function
  testLibrary() {
    var library = conf.library();
    Assert.isFalse(library == null);
    Assert.isTrue(Std.is(library.sourceDirs,Array));
    Assert.equals("/home/blackdog/Projects/haxelib/src",library.sourceDirs[0]);
  }


  public
  function testExecutable() {
    var exe = conf.executable();
    Assert.isFalse(exe == null);
    Assert.equals("filename (required)",exe.mainIs);
    Assert.equals("foo",exe.attrs[0]);
  }

  public
  function testRepo() {
    var repo = conf.repo();
    Assert.isFalse(repo == null);
    Assert.equals("this",repo.attrs[0]);
    Assert.equals("darcs",repo.type);

    //    trace(JSON.encode(conf));
  }
}

class PackageTests  {
  var hbl:Habal;
  var conf:Config;

  public function new() {}
  
  public
  function setup() {
    // initialises package dir, process habal
    Package.initPackDir();
    hbl = HblTools.process(Parse.testFile);
    conf = HblTools.getConfig(hbl);
  }
  
  function testXml() {
    Package.xml(conf);
    Assert.isTrue(Os.exists(Package.packDir+"haxelib.xml"));
  }

  function testPackageSources() {
    Package.sources(conf) ;
    var
      libs = conf.library();
    for (d in libs.sourceDirs) {
        var top = neko.FileSystem.readDirectory(d);
        for (t in top) {
          //if (!StringTools.startsWith(t,"."))
          //continue;
          
          Assert.isTrue(Os.exists(Package.packDir  + t));
        }
    };
  }

   function testJson() {
    Package.json(conf);
    var g = conf.globals();
    Assert.isTrue(Os.exists(Package.packDir+"haxelib.json"));
  }
  
  function testZip() {
    Package.zip(conf);
    var g = conf.globals();
    Assert.isTrue(Os.exists(neko.io.Path.directory(conf.file()) + "/"+g.name+".zip"));
  }

 
}
