package tools.haxelib;

import tools.haxelib.ServerModel;
import tools.haxelib.ServerHxRepo;

class ServerMain {

  public static
  function main() {

    var
      repo:Repository,
      command = ServerCtrl.dispatch();

    repo = new ServerHxRepo("/home/blackdog/Projects/haxelib/");

    switch(command) {
    case SEARCH(query):
    case INFO(project):
    case USER(email):
    case REGISTER(email,password,fullName):
      repo.register(email,password,fullName);
    case SUBMIT(pkg):
      repo.submit();
    case DEV(prj,dir):

    }

    repo.cleanup();
  }
} 
