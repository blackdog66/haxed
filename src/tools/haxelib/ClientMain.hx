package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCtrl;

class ClientMain {
  public static var VERSION = "0.1";

  static function
  dontHandle(cmd:String,s:Status) {
    neko.Lib.println(cmd+" doesn't handle "+s);
  }

  private static function
  myTrace( v : Dynamic, ?inf : haxe.PosInfos ) {
    Os.log(v);
  }

  static function toJson(obj:Dynamic,url:String) {
    return neko.Lib.println(hxjson2.JSON.encode({repo:url,payload:obj}));
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
            if (options.flag("-j")) {
              toJson(si,rurl);
            } else {
              Os.print(formatRepoUrl(rurl));
              Os.print(formatSearchInfo(si));
            }
            false;
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
            if (options.flag("-j")) {
              toJson(pi,rurl);
            } else {
              Os.print(formatRepoUrl(rurl));
              Os.print(formatProjectInfo(pi));
            }            
            if (options.flag("-all")) false else true;
          default:
            dontHandle("info",s);
            true;
          }
          
        });
    case USER(options,email):
      client.user(options,email,function(rurl:String,s:Status) {
          return switch(s) {
          case OK_USER(ui):
            Os.print(formatRepoUrl(rurl));
            Os.print(formatUserInfo(ui));
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
            neko.Lib.println("registered with:"+rurl);
            false;
          case ERR_REGISTERED:
            false;
          default:
            dontHandle("register",s);
            false;
          }
        });
    case SUBMIT(options,password,packagePath):
      client.submit(options,password,packagePath,function(rurl:String,s:Status) {
          switch(s) {
          case OK:
          case ERR_LICENSE(licenses):
            Os.print(formatLicenses(licenses));
          default:
            dontHandle("submit",s);
          }
          return true;
        });
    case ACCOUNT(options,cemail,cpass,nemail,npass,nname):
      client.account(options,cemail,cpass,nemail,npass,nname,function(rurl,s:Status) {
          trace(s);
          return true;
        });
    case LICENSE(options):
      client.licenses(options,function(rurl:String,s:Status) {
          switch(s) {
          case OK_LICENSES(licenses):
            Os.print(formatLicenses(licenses));
          default:
            dontHandle("license",s);
          }
          return true;
        });
    }
  }

  static function formatRepoUrl(repo:String) {
    return "In Repo: "+repo;
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
::foreach licence::
::name:: - ::url::
::end::
';
      return Os.template(tmpl,ls);
  }
}
