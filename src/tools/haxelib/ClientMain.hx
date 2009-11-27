package tools.haxelib;

import tools.haxelib.ClientRestful;
import tools.haxelib.ClientCtrl;

class ClientMain {
  public static var VERSION = "0.1";
  static var defaultRepos = new Array<String>();

  static
  function main() {
    defaultRepos.push("http://lib.haxelib.org");
    defaultRepos.push("http://bazarrware");

    var
      client = new ClientRestful(defaultRepos),
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
    case INSTALL(options,projectName):
      client.install(options,projectName);
    case SEARCH(options,query):
      client.search(options,query);
    case INFO(options,project):
      client.info(options,project);
    case USER(options,email):
    case REGISTER(options,email,password,fullName):
      client.register(options,email,password,fullName);
    case SUBMIT(options,password,packagePath):
      client.submit(options,password,packagePath);
    }
  }
}