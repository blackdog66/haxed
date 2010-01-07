package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ServerCore;
import tools.haxelib.License;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
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
      repo,
      dinfo = ServerCtrl.dispatch(),
      config:ServerConf = hxjson2.JSON.decode(haxe.Resource.getString("serverConfig"));

    License.set(config.licenses);
    repo = new ServerCore(config.dataDir);

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
          repo.info(pkg);
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
