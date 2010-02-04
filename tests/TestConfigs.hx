
package tests;

import haxed.Hxp;
import haxed.Package;
import haxed.Config;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

import hxjson2.JSON;

class TestConfigs  {
  static var testFile = "./test.hbl";
  var hbl:Hxp;
  var hblConf:Config;
  var jsonConf:Config;

  public function new() {}
  
  public
  function setup() {
    hbl = HblTools.process(testFile);
    hblConf = HblTools.getConfig(hbl);
    jsonConf = new ConfigJson(JSON.encode(hblConf.data));
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