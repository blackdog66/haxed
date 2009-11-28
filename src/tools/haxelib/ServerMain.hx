package tools.haxelib;

import tools.haxelib.Common;
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

    Lib.print(
      ERR.msg(
        switch(command) {
        case CMD_USER(email):
          repo.user(email);
        case CMD_REGISTER(email,password,fullName):
          repo.register(email,password,fullName);
        case CMD_SUBMIT(password):
          repo.submit(password);
        default:
          ERR_UNKNOWN;
        }));

    repo.cleanup();
  }
} 
