package tests;

import tools.haxelib.Os;
import tools.haxelib.Habal;
import tools.haxelib.Package;

class Parse extends haxe.unit.TestCase{

  static var testFile = "./test.hbl";
  var hbl:Habal;
  
  override public
  function setup() {
    hbl = HblTools.process(testFile);
  }
  
  public function
  testGlobals() {
    var globals = hbl.globals();
    assertFalse(globals == null);
    assertEquals(globals.synopsis,"freeform");
    assertEquals(globals.name,"project-name");

    assertTrue(Std.is(globals.tags,List));

  }

  public function
  testLibrary() {
    var library = hbl.library();
    assertFalse(library == null);
    assertTrue(Std.is(library.sourceDirs,List));
    assertEquals("/home/blackdog/Projects/haxelib/src",library.sourceDirs.first());
  }


  public
  function testExecutable() {
    var exe = hbl.executable();
    assertFalse(exe == null);
    assertEquals("filename (required)",exe.mainIs);
    assertEquals("foo",exe.attrs.first());
  }

  public
  function testRepo() {
    var repo = hbl.repo();
    assertFalse(repo == null);
    assertEquals("this",repo.attrs.first());
    assertEquals("darcs",repo.type);

    //    trace(JSON.encode(hbl));
  }
}

class PackageTests extends haxe.unit.TestCase {
  var hbl:Habal;
  
  override public
  function setup() {
    // initialises package dir, process habal
    Package.initPackDir();
    hbl = HblTools.process(Parse.testFile);
  }
  
  function testXml() {
    Package.xml(hbl);
    assertTrue(Os.exists(Package.packDir+"haxelib.xml"));
  }

  function testPackageSources() {
    Package.sources(hbl) ;
    var
      libs = hbl.library();
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
    Package.json(hbl);
    var g = hbl.globals();
    assertTrue(Os.exists(Package.packDir+"haxelib.json"));
  }
  
  function testZip() {
    Package.zip(hbl);
    var g = hbl.globals();
    assertTrue(Os.exists(neko.io.Path.directory(hbl.file) + "/"+g.name+".zip"));
  }

 
}
