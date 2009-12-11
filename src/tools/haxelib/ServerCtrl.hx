
package tools.haxelib;

import tools.haxelib.Common;

#if php
import php.Web;
#elseif neko
import neko.Web;
#end

class ServerCtrl  {

  static function getParam(params:Hash<String>,p:String) {
    if (params.get(p) == null)
      return null;
    if (StringTools.trim(params.get(p)) == "")
      return null;
    
    return StringTools.urlDecode(params.get(p));
  }
  
  public static
  function dispatch():CmdContext {
    var params = Web.getParams(),
      options = new Options();

    if (!params.exists("method"))
      throw "need a method!";

    options.parseSwitches(params);
    
    return
      switch(getParam(params,"method")) {
      case "submit":
        var password = getParam(params,"password");
        REMOTE(SUBMIT(password),options);
      case "register":
        var
          email = getParam(params,"email"),
          password = getParam(params,"password"),
          fullName = getParam(params,"fullname");

       REMOTE(REGISTER(email,password,fullName),options);
  
      case "info":
        var prj = getParam(params,"prj");
        REMOTE(INFO(prj),options);
      case "user":
        var email = getParam(params,"email");
        REMOTE(USER(email),options);
       case "search":
        var
          query = getParam(params,"query");
        REMOTE(SEARCH(query),options);
      case "account":
        var
          cemail= getParam(params,"cemail"),
          cpass  = getParam(params,"cpass"),
          nemail = getParam(params,"nemail"),
          npass = getParam(params,"npass"),
          nname = getParam(params,"nname");

        REMOTE(ACCOUNT(cemail,cpass,nemail,npass,nname),options);

      case "license":
        REMOTE(LICENSE,options);
      case "projects":
        REMOTE(PROJECTS,options);
        
        
      }
  }
  
}