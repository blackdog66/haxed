
package tests;

import tools.haxelib.ZipReader;

class Submit extends haxe.unit.TestCase {

  public function
  testOpenZip() {
    var e = ZipReader.open("project-name.zip");
  }
  
  public function
  testUnzip() {

    var s = ZipReader.content("project-name.zip","haxelib.json");
    
    assertTrue(s != null);
  }
}