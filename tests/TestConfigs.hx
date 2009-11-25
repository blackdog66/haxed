
package tests;

import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Config;

class TestConfigs extends haxe.unit.TestCase {
  static var testFile = "./test.hbl";
  var hbl:Habal;
  var hblConf:Config;
  var jsonConf:Config;
  
  override public
  function setup() {
    hbl = HblTools.process(testFile);
    hblConf = HblTools.getConfig(hbl);
    jsonConf = new ConfigJson(hxjson2.JSON.encode(hbl));
  }
  
  public function
  testEquality() {
    assertEquals(jsonConf.globals().name,hblConf.globals().name);
    assertEquals(jsonConf.library().sourceDirs[0],hblConf.library().sourceDirs[0]);
    assertEquals(jsonConf.library().buildable,hblConf.library().buildable);
    assertTrue(jsonConf.library().buildable);
  }

  
}