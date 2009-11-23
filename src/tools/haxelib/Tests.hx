
package tools.haxelib;

//import hxjson2.JSON;

import tools.haxelib.Habal;
import tools.haxelib.Package;

class ParseTests extends haxe.unit.TestCase{

  var hbl:Habal;
  
  override public
  function setup() {
    hbl = HblTools.process("doc/habal.txt");
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
    hbl = HblTools.process("doc/habal.txt");
  }
  
  function testXml() {
    Package.xml(hbl);
    assertTrue(Os.exists(Package.packDir+hbl.globals().name+".xml"));
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

  function testZip() {
    Package.zip(hbl);
    var g = hbl.globals();
    assertTrue(Os.exists(neko.io.Path.directory(hbl.file) + "/"+g.name+".zip"));
  }
}


class Tests {
    
  static function main(){
    var r = new haxe.unit.TestRunner();
    r.add(new ParseTests());
    r.add(new PackageTests());
 
    r.run();
  }
}
