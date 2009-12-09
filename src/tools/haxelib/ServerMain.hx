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

    var p = new php.io.Process("/bin/hostname",[]);
    var host = StringTools.trim(p.stdout.readAll().toString());
    if(host == "blackdog")
      repo = new ServerHxRepo("/home/blackdog/Projects/haxelib/");
    else
      repo = new ServerHxRepo("/home/blackdog/haxelib/");

  Lib.print(
      ERR.msg(
        switch(command) {
        case CMD_USER(email):
          repo.user(email);
        case CMD_REGISTER(email,password,fullName):
          repo.register(email,password,fullName);
        case CMD_SUBMIT(password):
          repo.submit(password);
        case CMD_INFO(pkg):
          repo.info(pkg);
        case CMD_SEARCH(query,options):
          repo.search(query,options);
        case CMD_ACCOUNT(cemail,cpass,nemail,npass,nname):
          repo.account(cemail,cpass,nemail,npass,nname);
        case CMD_LICENSE:
          repo.license();
        case CMD_PROJECTS:
          repo.projects();
        default:
          ERR_UNKNOWN;
        }));

    repo.cleanup();
  }
} 
