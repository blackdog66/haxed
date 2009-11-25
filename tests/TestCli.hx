
package tests;

import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCommands;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestCli  {

  var cr:ClientRestful;

  public function new() {}
  
  public
  function setup() {
    cr = new ClientRestful(["other repo"]);
  }
  
  public function
  testRegister() {
    var me = this;
    var options = new Options() ;  
    cr.register(options,"blackdog@ipowerhouse.com","bd","full name");
    
   
  }

  
}