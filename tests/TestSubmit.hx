

package tests;

import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCommands;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestSubmit  {

  var cr:ClientRestful;
  var options:Options;
  var pkg:String;
  var email:String;
  var email2:String;

  public function new() {}
  
  public
  function setup() {
    cr = new ClientRestful(["other repo"]);
    options = new Options() ;
    pkg = "project-name.zip";
    email = "blackdog@ipowerhouse.com";
    email2 = "another@w00t.com";
  }

  public function
  testSubmit() {
    var
      me = this,
      onSubmission = Assert.createEvent(function(d:Dynamic) {
          Assert.equals(0,d.ERR);
        });
    
    cr.submit(options,"pw",pkg,onSubmission);
  }
}