
package tools.haxelib;

import tools.haxelib.ServerModel;

#if php
import php.Web;
#elseif neko
import neko.Web;
#end

class ServerCtrl  {

  public static
  function dispatch():Command {
    var params = Web.getParams();
    if (!params.exists("method"))
      throw "need a method!";
    
    return
      switch(params.get("method")) {
      case "submit":
        SUBMIT("");
      case "register":
        var
          email = params.get("email"),
          password = params.get("password"),
          name = params.get("name"),
          fullName = params.get("fullName");
        
        REGISTER(email,password,fullName);
        
      case "info":
        var prj = params.get("prj");
        trace("info");
        INFO(prj);
      case "user":
        var user = params.get("user");
        USER(user);
        
      case "dev":
        var
        prj = params.get("prj"),
        dir = params.get("dir");
      DEV(prj,dir);
      
      case "search":
        var query = params.get("query");
        SEARCH(query);
      }
  }
  
}