package haxed.server;

import haxed.Common;
import haxed.Marshall;
import haxed.License;
import bdog.Os;
import bdog.JSON;

#if GITSTORE
import haxed.server.ServerGit;
#else
import haxed.server.ServerCore;
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
      sdir =  untyped __php__('$_SERVER["PWD"]') ,
      config:ServerConf = JSON.decode(Os.fileIn(sdir+"/server.json"));

    License.set(config.licenses);

    #if GITSTORE
    repo = new ServerGit(config.dataDir);
    #else
    repo = new ServerCore(config.dataDir);
    #end
    
    Os.print(Marshall.toJson(
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
