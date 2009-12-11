package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ServerRepos;
import tools.haxelib.License;

#if php
import php.Lib;
#elseif neko
import neko.Lib;
#end

private typedef ServerConf =  {
  var serverName:String;
  var dataDir:String;
  var licenses:Array<{pub:Bool,name:String,url:String}>;
}

class ServerMain {

  public static var config:ServerConf;

  public static
  function main() {
    var
      repo,
      cmdCtx = ServerCtrl.dispatch(),
      config:ServerConf = hxjson2.JSON.decode(haxe.Resource.getString("serverConfig"));

    License.set(config.licenses);
    repo = new ServerRepos(config.dataDir);

    Lib.print(Marshall.toJson(
      switch(cmdCtx) {
      case REMOTE(cmd,options):
        switch(cmd) {
        case USER(email):
          repo.user(email);
        case REGISTER(email,password,fullName):
          //if (Common.validEmail(email) != null) ERR_EMAIL("");
          //if (Common.validPW(password) != null) ERR_PASSWORD("");
          repo.register(email,password,fullName);
        case SUBMIT(password):
          repo.submit(password);
        case INFO(pkg):
          repo.info(pkg);
        case SEARCH(query):
          repo.search(query,options);
        case ACCOUNT(cemail,cpass,nemail,npass,nname):
          // if (Common.validEmail(cemail) != null) ERR_EMAIL("current");
          //if (Common.validPW(cpass) != null) ERR_PASSWORD("current");
          //if (Common.validEmail(nemail) != null) ERR_EMAIL("new");
          //if (Common.validPW(npass) != null) ERR_PASSWORD("new");
          
          repo.account(cemail,cpass,nemail,npass,nname);
        case LICENSE:
          repo.license();
        case PROJECTS:
          repo.projects();
        case SERVERINFO:
          OK_SERVERINFO({name:config.serverName,licenses:config.licenses});
        }
      case LOCAL(cmd,options):
        trace("shouldn't get here");
        ERR_UNKNOWN;
      }
    ));
    
    repo.cleanup();
  }
}
