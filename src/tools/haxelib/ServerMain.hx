package tools.haxelib;

import tools.haxelib.ServerModel;
import tools.haxelib.ServerHxRepo;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

class ServerMain {

  public static
  function main() {

    var
      repo:Repository,
      command = ServerCtrl.dispatch();

    repo = new ServerHxRepo("/home/blackdog/Projects/haxelib/");

    var ret:Dynamic = {ERR:1,ERRMSG:"Not implemented"};
    
    switch(command) {
    case SEARCH(query):
    case INFO(project):
    case USER(email):
      ret = repo.user(email);
    case REGISTER(email,password,fullName):
      ret = repo.register(email,password,fullName);
    case SUBMIT(pkg):
      ret = repo.submit();
    case DEV(prj,dir):
    }
    
    Lib.print(hxjson2.JSON.encode(ret));

    repo.cleanup();
  }
} 
