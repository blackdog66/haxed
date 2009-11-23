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
      client = new RestfulClient(defaultRepos),
      command = ClientCtrl.process();

    switch(command) {
    case NOOP:
      ClientCtrl.usage();
    case LIST:
       client.list();
    case REMOVE(pkg,ver):
      client.remove(pkg,ver);
    case SET(prj,ver):
      client.set(prj,ver);
    case SETUP(path):
      client.setup(path);
    case CONFIG:
      client.config();
    case PATH(pkgs):
      client.path(pkgs);
    case RUN(params):
      client.run();
    case DEV(prj,dir):
      client.dev(prj,dir);
    case TEST(path):
    case PACKAGE(hblFile):
      client.packit(hblFile);
      // server
    case INSTALL(projectName):
      client.install(projectName);
    case SEARCH(query):
      client.search(query);
    case INFO(project):
      client.info(project);
    case USER(email):
    case REGISTER(email,password):
      client.register(email,password);
    case SUBMIT(packagePath):
      client.submit(packagePath);
    case CAPABILITIES:
      client.capabilities();
    }
  }
}