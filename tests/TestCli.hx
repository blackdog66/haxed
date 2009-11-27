
package tests;

import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCommands;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestCli  {

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
  testRegister() {
    neko.Sys.command("./recreateDB");
    var
      me = this,
      notRegistered = Assert.createEvent(function(d:Dynamic) {
          Assert.equals(d.ERR,0);
        }),
      registered = Assert.createEvent(function(d:Dynamic) {
          Assert.equals(d.ERR,1);
        }),
      anotherRegistered = Assert.createEvent(function(d:Dynamic) {
          Assert.equals(d.ERR,0);
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
          Assert.equals(d.email,me.email);
          Assert.equals(d.projects.length,0);
      });
    
    cr.user(options,email,as);
  }

  
}