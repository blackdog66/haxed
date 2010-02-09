package haxed;

import haxed.Common;
import haxed.ClientRestful;
import haxed.ClientCtrl;

class ClientMain {
  public static var VERSION = "0.1";

  private static function
  myTrace( v : Dynamic, ?inf : haxe.PosInfos ) {
    Os.log(v);
  }

  static function
  toJson(obj:Dynamic,url:String) {
    return neko.Lib.println(hxjson2.JSON.encode({repo:url,payload:obj}));
  }

  static function
  handleOptions(options:Options,rurl:String,obj:Dynamic,formatter:Dynamic->String) {

    if (obj != null) {
      if (options.flag("-j")) {
        toJson(obj,rurl);
      } else {
        Os.print(formatRepoUrl(rurl));
        Os.print(formatter(obj));
      }

      if (options.flag("-R"))
        return true; // only checking one repo, so handled
    
      if (options.flag("-a"))
        return false; // not handled, check next repo      
    }
    return false;    
  }

  static function
  handleServerResponse(options:Options,rurl:String,s:Status) {
    return switch(s) {
    case OK_SEARCH(si):
      handleOptions(options,rurl,si,formatProjects);
     case OK_PROJECT(pi):
      handleOptions(options,rurl,pi,formatProjectInfo);
    case OK_USER(ui):
      handleOptions(options,rurl,ui,formatUserInfo);
      true;
    case OK_SUBMIT:
      Os.print("Submission Successful");
      true;
    case OK_REGISTER:
      Os.print("Registration Successful");
      false;
    case OK_LICENSES(licenses):
      handleOptions(options,rurl,licenses,formatLicenses);
    case OK_ACCOUNT:
      Os.print("Account updated successfully");
      return false;
    case OK_PROJECTS(prj):
      handleOptions(options,rurl,prj,formatProjects);
    case OK_SERVERINFO(si):
       handleOptions(options,rurl,si,formatServerInfo);
    case OK_REMINDER:
      Os.print("Email sent");
      return false;
    case OK_TOPTAGS(tt):
      handleOptions(options,rurl,tt,formatTopTags);
    case ERR_REMINDER:
      Os.print("Email not sent");
      return false;
    case ERR_PROJECTNOTFOUND:
      return false;
    case ERR_UNKNOWN:
      false; //not handled check next server if one exists
    case ERR_REGISTERED:
      Os.print("Already registered");
      false;
    case ERR_LICENSE(lics):
      Os.print("Repository does not accept this license :"+lics.given);
      handleOptions(options,rurl,lics.licenses,formatLicenses);
    case ERR_USER(u):
      Os.print("User not known:"+u);
      true;
    case ERR_NOTHANDLED:
      Os.print("Server didn't know that option");
      return false;
    case ERR_PASSWORD(which):
      Os.print("Bad password" + ((which != "") ? "for "+which : ""));
      return false;
    case ERR_EMAIL(which):
      Os.print("Bad email" + ((which != "") ? "for "+which : ""));
      return false;
    case ERR_DEVELOPER:
      Os.print("Given author is not a developer");
      return false;
    case ERR_HAXELIBJSON:
      Os.print(Common.CONFIG_FILE +" is missing");
      return false;
    }
  }
  
  static function
  main() {

    //haxe.Log.trace = myTrace;
    var
      client = new ClientRestful(),
      commandCtx = ClientCtrl.process();

    if (commandCtx == null) neko.Sys.exit(1);
    
    switch(commandCtx) {
    
    case LOCAL(cmd,options):
      switch(cmd) {
      case LIST:
        client.list(options);
      case REMOVE(pkg,ver):
        client.remove(options,pkg,ver);
      case SET(prj,ver):
        client.set(prj,ver);
      case SETUP(path):
        client.setup(path);
      case CONFIG:
        client.config(options);
      case PATH(pkgs):
        client.path(pkgs);
      case RUN(prj,args):
        client.run(prj,args);
      case DEV(prj,dir):
        client.dev(prj,dir);
      case TEST(path):
        client.test(path);
      case PACK(hxpFile):
        client.packit(hxpFile);
      case INSTALL(projectName,version):
        client.install(options,projectName,version);
      case UPGRADE:
        client.upgrade();
      case NEW(interactive):
        client.newHxp(interactive);
      case BUILD(hxpFile,target):
        client.build(hxpFile,target,options);
      case TASK(task,prms):
        var t = new haxed.Tasks(task);
        t.execute(prms,options);
      }
    
    case REMOTE(cmd,options):
      switch(cmd) {
       case SEARCH(query):
        client.search(options,query,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case INFO(project):
        client.info(options,project,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case USER(email):
        client.user(options,email,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case REGISTER(email,password,fullName):
        client.register(options,email,password,fullName,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case SUBMIT(hxpFile):
        Os.print("packing ...");
        var packagePath = client.packit(hxpFile);
        Os.print("submitting ...");
        var password = options.getSwitch("-P");
        client.submit(options,password,packagePath,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case ACCOUNT(cemail,cpass,nemail,npass,nname):
        client.account(options,cemail,cpass,nemail,npass,nname,function(rurl,s:Status) {
            trace(s);
            return true;
          });
      case LICENSE:
        client.licenses(options,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case PROJECTS:
        client.projects(options,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);          
          });
      case SERVERINFO:
        client.serverInfo(options,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);          
          });
      case REMINDER(email):
        client.reminder(email,options,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      case TOPTAGS(nTags):
        client.topTags(nTags,options,function(rurl:String,s:Status) {
            return handleServerResponse(options,rurl,s);
          });
      }
    }
  }

  static function formatRepoUrl(repo:String) {
    return "Repository: "+repo;
  }

  static function
  formatProjectInfo(pi:ProjectInfo) {
    var tmpl='Name: ::name::
Desc: ::desc::
Website: ::website::
License: ::license::
Owner: ::owner::
Version: ::curversion::
::if (tags != null):: Tags: ::foreach tags:: ::tag::::end::::end::

::if (versions != null)::
Releases:
::foreach versions::
[::name::] - ::date::
        ::comments::
::end::
::end::

';
    return Os.template(tmpl,pi);
  }

  static function
  formatUserInfo(ui:UserInfo) {
    var tmpl='Name: ::fullname::
Email: ::email::
Projects:
::foreach projects::
	::name::
::end::

';
    return Os.template(tmpl,ui);
  }

  /*
  static function
  formatSearchInfo(si:SearchInfo) {
    var tmpl='::foreach items::
Project: ::name::
  in context:
::context::
::end::
';
    return Os.template(tmpl,si);
  }
  */

    static function
  formatServerInfo(si:ServerInfo) {
    var tmpl='
ServerName: ::name::
Accepts these licenses:
::foreach licenses::
::name::,  ::url:: ::end::
';
    return Os.template(tmpl,si);
  }


  static function
  formatLicenses(ls:Array<{name:String,url:String}>) {
    var tmpl='Repository accepts these licenses:
::foreach licenses::
::name:: - ::url:: ::end::
';
    return Os.template(tmpl,{licenses:ls});
  }

  static function
  formatTopTags(tt:TopTagInfo) {
    var tmpl='tags:
::foreach tags::
::tag:: - ::count:: ::end::
';
    return Os.template(tmpl,tt);
  }
  
  static function
  formatProjects(prj:Array<ProjectInfo>) {
    return Lambda.fold(prj,function(p,sb:StringBuf) {
        sb.add(formatProjectInfo(p));
        return sb;
      },new StringBuf()).toString();
  }
}
