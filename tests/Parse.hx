package tests;

import tools.haxelib.Os;
import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Config;

class Parse extends haxe.unit.TestCase{

  static var testFile = "./test.hbl";

  var hbl:Habal;
  var conf:Config;  
  
  override public
  function setup() {
    hbl = HblTools.process(testFile);
    conf = HblTools.getConfig(hbl);
  }
  
  public function
  testGlobals() {
    var globals = conf.globals();
    assertFalse(globals == null);
    assertEquals(globals.synopsis,"freeform");
    assertEquals(globals.name,"project-name");

    assertTrue(Std.is(globals.tags,Array));

  }

  public function
  testLibrary() {
    var library = conf.library();
    assertFalse(library == null);
    assertTrue(Std.is(library.sourceDirs,Array));
    assertEquals("/home/blackdog/Projects/haxelib/src",library.sourceDirs[0]);
  }


  public
  function testExecutable() {
    var exe = conf.executable();
    assertFalse(exe == null);
    assertEquals("filename (required)",exe.mainIs);
    assertEquals("foo",exe.attrs[0]);
  }

  public
  function testRepo() {
    var repo = conf.repo();
    assertFalse(repo == null);
    assertEquals("this",repo.attrs[0]);
    assertEquals("darcs",repo.type);

    //    trace(JSON.encode(conf));
  }
}

class PackageTests extends haxe.unit.TestCase {
  var hbl:Habal;
  var conf:Config;
  
  override public
  function setup() {
    // initialises package dir, process habal
    Package.initPackDir();
    hbl = HblTools.process(Parse.testFile);
    conf = HblTools.getConfig(hbl);
  }
  
  function testXml() {
    Package.xml(conf);
    assertTrue(Os.exists(Package.packDir+"haxelib.xml"));
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
          
          assertTrue(Os.exists(Package.packDir  + t));
        }
    };
  }

   function testJson() {
    Package.json(conf);
    var g = conf.globals();
    assertTrue(Os.exists(Package.packDir+"haxelib.json"));
  }
  
  function testZip() {
    Package.zip(conf);
    var g = conf.globals();
    assertTrue(Os.exists(neko.io.Path.directory(conf.file()) + "/"+g.name+".zip"));
  }

 
}
