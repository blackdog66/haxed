package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ServerRepos;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

class ServerMain {

  public static
  function main() {
    var
      repo,
      cmdCtx = ServerCtrl.dispatch(),
      p = new php.io.Process("/bin/hostname",[]),
      host = StringTools.trim(p.stdout.readAll().toString());

    if(host == "blackdog")
      repo = new ServerRepos("/home/blackdog/Projects/haxelib/");
    else
      repo = new ServerRepos("/home/blackdog/haxelib/");

  Lib.print(
      Marshall.toJson(
        switch(cmdCtx) {
        case REMOTE(cmd,options):
          switch(cmd) {
          case USER(email):
            repo.user(email);
          case REGISTER(email,password,fullName):
            repo.register(email,password,fullName);
          case SUBMIT(password):
            repo.submit(password);
          case INFO(pkg):
            repo.info(pkg);
          case SEARCH(query):
            repo.search(query,options);
          case ACCOUNT(cemail,cpass,nemail,npass,nname):
            repo.account(cemail,cpass,nemail,npass,nname);
          case LICENSE:
            repo.license();
          case PROJECTS:
            repo.projects();
          }
        case LOCAL(cmd,options):
          trace("shouldn't get here");
          ERR_UNKNOWN;
        }
    ));

    repo.cleanup();
  }
} 
