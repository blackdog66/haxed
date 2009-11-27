
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
          fullName = params.get("fullname");

        // if( !Datas.alphanum.match(name) )
    //  throw "Invalid user name, please use alphanumeric characters";
    //if( name.length < 3 )
    //  throw "User name must be at least 3 characters";

        
        REGISTER(email,password,fullName);
  
      case "info":
        var prj = params.get("prj");
        trace("info");
        INFO(prj);
      case "user":
        var email = params.get("email");
        USER(email);
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