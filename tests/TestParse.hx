package tests;

import tools.haxelib.Os;
import tools.haxelib.Hxp;
import tools.haxelib.Package;
import tools.haxelib.Config;

import utest.Assert;

class TestParse {

  public static var testFile = "./myproject.hxp";

  var hbl:Hxp;
  var conf:Config;

  public function new() {}
  
  public
  function setup() {
    hbl = HxpTools.process(testFile);
    conf = HxpTools.getConfig(hbl);
  }

  public function
  testAGlobals() {
    var globals = conf.globals();
    Assert.notNull(globals);
    Assert.equals("freeform",globals.synopsis);
    Assert.equals("myproject",globals.project);
  
    Assert.isTrue(Std.is(globals.tags,Array));

  }
 
  public function
  testBLibrary() {
    var library = conf.build();
    Assert.notNull(library);
    Assert.isTrue(Std.is(library.classPaths,Array));
    Assert.equals("/home/blackdog/Projects/hxV8/v8",library.classPaths[0]);

    Assert.isTrue(Std.is(library.depends,Array));
    var deps1 = library.depends[0];
    Assert.equals(deps1.prj,"hxJson2");
    Assert.equals(deps1.ver,"1");
    Assert.equals(deps1.op,">");
    Assert.equals(library.target,"js");
  }
}

class TestPackage  {
  var hbl:Hxp;
  var conf:Config;

  public function new() {
    Package.initPackDir();
  }
  
  public
  function setup() {
    // initialises package dir, process habal
    hbl = HxpTools.process(TestParse.testFile);
    conf = HxpTools.getConfig(hbl);
  }
 
  function testAXml() {
    Package.xml(conf);
    Assert.isTrue(Os.exists(Package.packDir+"haxelib.xml"));
  }
  
  function testBPackageSources() {
    Package.sources(conf) ;
    var
      libs = conf.build();
    for (d in libs.classPaths) {
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
  var hbl:Hxp;
  var conf:Config;

  public function new() { }
  
  public
  function setup() {
    // initialises package dir, process habal
    hbl = HxpTools.process(TestParse.testFile);
    conf = HxpTools.getConfig(hbl);
  }
 
  function testDZip() {
    Package.zip(conf);
    var g = conf.globals();
    Assert.isTrue(Os.exists(neko.io.Path.directory(conf.file()) + "/"+g.project+".zip"));
  }
 

}