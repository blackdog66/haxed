package tests;

import haxed.ClientRestful;
import haxed.Common;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

class TestSubmit  {

  var cr:ClientRestful;
  var options:Options;
  var pkg:String;
  var prj:String;
  var email:String;
  var email2:String;

  public function new() {}
  
  public
  function setup() {
    cr = new ClientRestful();
    options = new Options() ;
    prj = "project-name";
    pkg = prj+".zip";
    email = "blackdog@ipowerhouse.com";
    email2 = "another@w00t.com";
    
  }

  public function
  testASubmit() {
    var
      me = this,
      onSubmission = Assert.createEvent(function(d:Dynamic) {
          Assert.equals("OK",d.ERR);
        });
    
    cr.submit(options,"bd1",pkg,onSubmission);
  }  

}


class TestPostSubmit  {

  var cr:ClientRestful;
  var options:Options;
  var pkg:String;
  var prj:String;
  var email:String;
  var email2:String;

  public function new() {}
  
  public
  function setup() {
    cr = new ClientRestful();
    options = new Options() ;
    prj = "project-name";
    pkg = prj+".zip";
    email = "blackdog@ipowerhouse.com";
    email2 = "another@w00t.com";
  }


  public function
  testInfo() {
    var
      me = this,
      as = Assert.createEvent2(function(d:Dynamic) {
          var info:ProjectInfo = d.INFO;
          Assert.equals(d.ERR,"OK_PROJECT");
          Assert.equals(me.prj,info.name);
          return true;
        });
    
    cr.info(options,prj,as);
  }
  
}



