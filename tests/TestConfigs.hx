
package tests;

import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Config;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestConfigs  {
  static var testFile = "./test.hbl";
  var hbl:Habal;
  var hblConf:Config;
  var jsonConf:Config;

  public function new() {}
  
  public
  function setup() {
    hbl = HblTools.process(testFile);
    hblConf = HblTools.getConfig(hbl);
    jsonConf = new ConfigJson(hxjson2.JSON.encode(hbl));
  }
  
  public function
  testEquality() {
    Assert.isTrue(jsonConf != null); 
    Assert.equals(jsonConf.globals().name,hblConf.globals().name);
    Assert.equals(jsonConf.library().sourceDirs[0],hblConf.library().sourceDirs[0]);
    Assert.equals(jsonConf.library().buildable,hblConf.library().buildable);
    Assert.isTrue(jsonConf.library().buildable);
  }

  
}