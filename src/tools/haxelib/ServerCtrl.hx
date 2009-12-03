
package tools.haxelib;

import tools.haxelib.ServerModel;

#if php
import php.Web;
#elseif neko
import neko.Web;
#end

class ServerCtrl  {

  static function getParam(params:Hash<String>,p:String) {
    if (params.get(p) == null)
      return null;
    return StringTools.urlDecode(params.get(p));
  }

  static function getOptions(params:Hash<String>) {
    var options = new Hash<String>();
    for (o in params.keys()) {
      if (StringTools.startsWith(o,"-"))
        options.set(o,params.get(o));
    }
    return options;
  }
  
  public static
  function dispatch():Command {
    var params = Web.getParams();
    
    if (!params.exists("method"))
      throw "need a method!";
    
    return
      switch(getParam(params,"method")) {
      case "submit":
        var password = getParam(params,"password");
        CMD_SUBMIT(password);
      case "register":
        var
          email = getParam(params,"email"),
          password = getParam(params,"password"),
          fullName = getParam(params,"fullname");

        // if( !Datas.alphanum.match(name) )
    //  throw "Invalid user name, please use alphanumeric characters";
    //if( name.length < 3 )
    //  throw "User name must be at least 3 characters";

        
        CMD_REGISTER(email,password,fullName);
  
      case "info":
        var prj = getParam(params,"prj");
        CMD_INFO(prj);
      case "user":
        var email = getParam(params,"email");
        CMD_USER(email);
      case "dev":
        var
        prj = getParam(params,"prj"),
        dir = getParam(params,"dir");
        CMD_DEV(prj,dir);     
      case "search":
        var
          query = getParam(params,"query");
        CMD_SEARCH(query,getOptions(params));
      }
  }
  
}