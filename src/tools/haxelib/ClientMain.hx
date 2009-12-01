package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCtrl;

class ClientMain {
  public static var VERSION = "0.1";

  static
  function dontHandle(cmd:String,s:Status) {
    neko.Lib.println(cmd+" doesn't handle "+s);
  }
  
  static
  function main() {

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
      client.search(options,query);
    case INFO(options,project):
      client.info(options,project,function(j) {
          trace(j);
          return true;
        });
    case USER(options,email):
      client.user(options,email,function(s:Status) {
          return switch(s) {
          case OK_USER(ui):
            trace("its all good");
            trace(ui);
            true;
          case ERR_UNKNOWN:
            neko.Lib.println(".... not found");
            return false; //not handled check next server if one exists
          default:
            throw dontHandle("user",s);
          }
        });
    case REGISTER(options,email,password,fullName):
      client.register(options,email,password,fullName,function(s:Status) {
          switch(s) {
          case OK:
            trace("register ok");
          case ERR_REGISTERED:
            trace("already registered");
          default:
            dontHandle("register",s);
          }
          return true;
        });
    case SUBMIT(options,password,packagePath):
      client.submit(options,password,packagePath);
    }
  }
}