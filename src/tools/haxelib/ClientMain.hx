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
            formatRepoUrl(rurl);
            formatSearchInfo(si);
            true;
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
            formatRepoUrl(rurl);
            formatProjectInfo(pi);
            true;
          default:
            dontHandle("info",s);
            true;
          }
          
        });
    case USER(options,email):
      client.user(options,email,function(rurl:String,s:Status) {
          return switch(s) {
          case OK_USER(ui):
            formatRepoUrl(rurl);
            formatUserInfo(ui);
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
      client.submit(options,password,packagePath,function(d) {
          trace(d);
        });
    }
  }

  static function formatRepoUrl(repo:String) {
    Os.print("In Repo: "+repo);
  }

  static function
  formatProjectInfo(pi:ProjectInfo) {
    var tmpl='
Name: ::name::
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
    Os.print(Os.template(tmpl,pi));
  }

  static function
  formatUserInfo(ui:UserInfo) {
    var tmpl='
Name: ::fullname::
Email: ::email::
Projects:
::foreach projects::
	::name::
::end::

';
    Os.print(Os.template(tmpl,ui));
  }


    static function
  formatSearchInfo(si:SearchInfo) {
    var tmpl='
::foreach items::
	::name::
  in context:
::context::
::end::
';
    Os.print(Os.template(tmpl,si));
  }
}
