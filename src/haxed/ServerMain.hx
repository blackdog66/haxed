package haxed;

import haxed.Common;
import haxed.License;
import bdog.JSON;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

#if GITSTORE
import haxed.ServerGit;
#else
import haxed.ServerCore;
#end

private typedef ServerConf =  {
  var serverName:String;
  var dataDir:String;
  var adminEmail:String;
  var licenses:Array<{pub:Bool,name:String,url:String}>;
}

class ServerMain {

  public static var config:ServerConf;

  public static
  function main() {
    var
      repo:ServerStore,
      dinfo = ServerCtrl.dispatch(),
      config:ServerConf = JSON.decode(haxe.Resource.getString("serverConfig"));

    License.set(config.licenses);

    #if GITSTORE
    repo = new ServerGit(config.dataDir);
    #else
    repo = new ServerCore(config.dataDir);
    #end
    
    Lib.print(Marshall.toJson(
      switch(dinfo.cmdCtx) {
      case REMOTE(cmd,options):
        switch(cmd) {
        case USER(email):
          repo.user(email);
        case REGISTER(email,password,fullName):
          repo.register(email,password,fullName);
        case SUBMIT(password):
          repo.submit(password);
        case INFO(pkg):
          repo.info(pkg,options);
        case SEARCH(query):
          repo.search(query,options);
        case ACCOUNT(cemail,cpass,nemail,npass,nname):
          repo.account(cemail,cpass,nemail,npass,nname);
        case LICENSE:
          repo.license();
        case PROJECTS:
          repo.projects(options);
        case SERVERINFO:
          OK_SERVERINFO({name:config.serverName,licenses:config.licenses});
        case REMINDER(email):
          repo.reminder(email);
        case TOPTAGS(n):
          repo.topTags(n);
        }
      case LOCAL(cmd,options):
        trace("shouldn't get here");
        ERR_UNKNOWN;
      }
      ,dinfo.jsonp));
    
    repo.cleanup();
  }
}
