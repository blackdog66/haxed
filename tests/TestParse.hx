package tests;

import tools.haxelib.Os;
import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Config;

import utest.Assert;

class TestParse {

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
  testAGlobals() {
    var globals = conf.globals();
    Assert.notNull(globals);
    Assert.equals(globals.synopsis,"freeform");
    Assert.equals(globals.name,"project-name");
    Assert.isTrue(Std.is(globals.tags,Array));

  }
 
  public function
  testBLibrary() {
    var library = conf.library();
    Assert.notNull(library);
    Assert.isTrue(Std.is(library.sourceDirs,Array));
    Assert.equals("/home/blackdog/Projects/hxV8/v8",library.sourceDirs[0]);
  }


  public
  function testCExecutable() {
    var exe = conf.executable();
    Assert.notNull(exe);
    Assert.equals("filename (required)",exe.mainIs);
    Assert.equals("foo",exe.attrs[0]);
  }

  public
  function testDRepo() {
    var repo = conf.repo();
    Assert.notNull(repo);
    Assert.equals("this",repo.attrs[0]);
    Assert.equals("darcs",repo.type);

    //    trace(JSON.encode(conf));
  }
 
}

class TestPackage  {
  var hbl:Habal;
  var conf:Config;

  public function new() {
    Package.initPackDir();
  }
  
  public
  function setup() {
    // initialises package dir, process habal
    hbl = HblTools.process(TestParse.testFile);
    conf = HblTools.getConfig(hbl);
  }
 
  function testAXml() {
    Package.xml(conf);
    Assert.isTrue(Os.exists(Package.packDir+"haxelib.xml"));
  }
  
  function testBPackageSources() {
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
  
  function testCJson() {
    Package.json(conf);
    var g = conf.globals();
    Assert.isTrue(Os.exists(Package.packDir+"haxelib.json"));
  }  
 
}


class TestZip  {
  var hbl:Habal;
  var conf:Config;

  public function new() { }
  
  public
  function setup() {
    // initialises package dir, process habal
    hbl = HblTools.process(TestParse.testFile);
    conf = HblTools.getConfig(hbl);
  }
 
  function testDZip() {
    Package.zip(conf);
    var g = conf.globals();
    Assert.isTrue(Os.exists(neko.io.Path.directory(conf.file()) + "/"+g.name+".zip"));
  }
 

}