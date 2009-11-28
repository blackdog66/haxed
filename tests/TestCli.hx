
package tests;

import tools.haxelib.Common;
import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCommands;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestCli  {

  var cr:ClientRestful;
  var options:Options;
  var pkg:String;
  var prj:String;
  var email:String;
  var email2:String;

  public function new() {}
  
  public
  function setup() {
    cr = new ClientRestful(["other repo"]);
    options = new Options() ;
    prj = "project-name";
    pkg = prj+"zip";
    email = "blackdog@ipowerhouse.com";
    email2 = "another@w00t.com";
  }

  public function
  testRegister() {
    neko.Sys.command("./recreateDB");
    var
      me = this,
      notRegistered = Assert.createEvent(function(d:Dynamic) {
          trace(d);
          Assert.equals("OK",d.ERR);
        }),
      registered = Assert.createEvent(function(d:Dynamic) {
          Assert.equals("ERR_REGISTERED",d.ERR);
        }),
      anotherRegistered = Assert.createEvent(function(d:Dynamic) {
          Assert.equals("OK",d.ERR);
        });

    cr.register(options,email,"bd1","fullname",notRegistered);
    cr.register(options,email,"bd1","full name",registered);
    cr.register(options,email2,"bd1","woot",anotherRegistered);
  }

  public function
  testUser() {
    var
      me = this,
      as = Assert.createEvent(function(d:Dynamic) {
          trace(d);
          Assert.equals(d.INFO.email,me.email);
          Assert.equals(d.INFO.projects.length,0);
      });
    
    cr.user(options,email,as);
  }

  
}