package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ClientCommon;
import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCtrl;

class ClientMain {
  public static var VERSION = "0.1";

  static function
  dontHandle(cmd:String,s:Status) {
    neko.Lib.println(cmd+" doesn't handle "+s);
    return true;
  }

  private static function
  myTrace( v : Dynamic, ?inf : haxe.PosInfos ) {
    Os.log(v);
  }

  static function toJson(obj:Dynamic,url:String) {
    return neko.Lib.println(hxjson2.JSON.encode({repo:url,payload:obj}));
  }

  static function handleOptions(options:Options,rurl:String,obj:Dynamic,formatter:Dynamic->String) {
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

    return false; 
  }
  
  static function
  main() {

    haxe.Log.trace = myTrace;
    var
      client = new ClientRestful(),
      command = ClientCtrl.process();

    switch(command) {
    case NOOP:
      ClientCtrl.usage();
    case LIST(options):
       client.list(options);
    case REMOVE(options,pkg,ver):
      client.remove(options,pkg,ver);
    case SET(options,prj,ver):
      client.set(prj,ver);
    case SETUP(options,path):
      client.setup(path);
    case CONFIG(options):
      client.config(options);
    case PATH(options,pkgs):
      client.path(pkgs);
    case RUN(options,params):
      client.run();
    case DEV(options,prj,dir):
      client.dev(prj,dir);
    case TEST(options,path):
    case PACKAGE(options,hblFile):
      client.packit(hblFile);
      // server
    case INSTALL(options,projectName,version):
      client.install(options,projectName,version);
    case SEARCH(options,query):
      client.search(options,query,function(rurl:String,s:Status) {
          return switch(s) {
          case OK_SEARCH(si):
            handleOptions(options,rurl,si,formatSearchInfo);
          default:
            dontHandle("search",s);
            false;
          }
        });
    case INFO(options,project):
      client.info(options,project,function(rurl:String,s:Status) {
          return switch(s){
          case ERR_PROJECTNOTFOUND:
            return false;
          case OK_PROJECT(pi):
            handleOptions(options,rurl,pi,formatProjectInfo);
          default:
            dontHandle("info",s);
            true;
          }
          
        });
    case USER(options,email):
      client.user(options,email,function(rurl:String,s:Status) {
          return switch(s) {
          case OK_USER(ui):
            handleOptions(options,rurl,ui,formatUserInfo);
            true;
          case ERR_UNKNOWN:
            false; //not handled check next server if one exists
          default:
            throw dontHandle("user",s);
            false;
          }
        });
    case REGISTER(options,email,password,fullName):
      client.register(options,email,password,fullName,function(rurl:String,s:Status) {
          return switch(s) {
          case OK:
            neko.Lib.println("Registration Successful");
            false;
          case ERR_REGISTERED:
            false;
          default:
            dontHandle("register",s);
          }
        });
    case SUBMIT(options,password,packagePath):
      client.submit(options,password,packagePath,function(rurl:String,s:Status) {
          return switch(s) {
          case OK:
            Os.print("Submission Successful");
            true;
          case ERR_LICENSE(lics):
            Os.print("Repository does not accept this license :"+lics.given);
            handleOptions(options,rurl,lics.licenses,formatLicenses);
          case ERR_USER(u):
            Os.print("User not known:"+u);
            return true;
          default:
            dontHandle("submit",s);
          }
        });
    case ACCOUNT(options,cemail,cpass,nemail,npass,nname):
      client.account(options,cemail,cpass,nemail,npass,nname,function(rurl,s:Status) {
          trace(s);
          return true;
        });
    case LICENSE(options):
      client.licenses(options,function(rurl:String,s:Status) {
          return switch(s) {
          case OK_LICENSES(licenses):
            handleOptions(options,rurl,licenses,formatLicenses);
          default:
            dontHandle("license",s);
          }
        });
    case PROJECTS(options):
      client.projects(options,function(rurl:String,s:Status) {
          
          return switch(s) {
          case OK_PROJECTS(prj):
            trace(handleOptions(options,rurl,prj,formatProjects));
            handleOptions(options,rurl,prj,formatProjects);
          default:
            dontHandle("projects",s);
          }
      });

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
Releases:
::foreach versions::
[::name::] - ::date::
        ::comments::
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


  static function
  formatLicenses(ls:Array<{name:String,url:String}>) {
    var tmpl='Repository accepts these licenses:
::foreach licenses::
::name:: - ::url:: ::end::
';
    return Os.template(tmpl,{licenses:ls});
  }

  static function
  formatProjects(prj:Array<ProjectInfo>) {
    return Lambda.fold(prj,function(p,sb:StringBuf) {
        sb.add(formatProjectInfo(p));
        return sb;
      },new StringBuf()).toString();
  }
}
