package tools.haxelib;

import tools.haxelib.ClientCore;


enum Answer {
  Yes;
  No;
  Always;
}

enum Command {
  NOOP;
  LIST;
  REMOVE(pkg:String,ver:String);
  SET(prj:String,ver:String);
  SETUP(path:String);
  CONFIG;
  PATH(paths:Array<{project:String,version:String}>);
  RUN(param:String);
  TEST(pkg:String);
  INSTALL(pkg:String);
  SEARCH(query:String);
  INFO(project:String);
  USER(email:String);
  REGISTER(email:String,password:String);
  SUBMIT(pkgPath:String);
  DEV(prj:String,dir:String);
  CAPABILITIES;
  PACKAGE(hblFile:String);
}


class ClientCtrl {
  static var commands = {
    install: "install a given project",
    list: "list all installed projects",
    upgrade : "upgrade all installed projects",
    remove : "remove a given project/version",
    set : "set the current version for a project",
    search : "list projects matching a word" ,
    info : "list informations on a given project",
    user : "list informations on a given user",
    register :"register a new user",
    submit : "submit or update a project package",
    setup : "set the haxelib repository path",
    config:"print the repository path",
    run:"run the specified project with parameters",
    test:"install the specified package locally",
    dev:"set the development directory for a given project",
    path:"give paths to libraries",
    packit:"package the project specified by the hbl file"
  };

  static var curArg = 0;
  static var args = neko.Sys.args();

  public
  static function print(str) {
    neko.Lib.print(str+"\n");
  }
  
  static
  function getSwitches() {
    if (args.length > 0) {
      while (StringTools.startsWith(args[curArg],"-"))
        curArg+=2;
    }
  }

  static inline
  function getCommand() {
    return args[curArg++];
  }

  static
  function eachParam(fn:String->Void) {
    while (curArg < args.length) {
      trace("Processing:" + args[curArg]);
       fn(args[curArg]);
       curArg++;
    }
  }

  static
  function paramOpt() {
    var args = neko.Sys.args();
    if( args.length > curArg )
      return args[curArg++];
    return null;
  }

  static
  function param( name, ?passwd ) {
    if( args.length > curArg )
      return args[curArg++];
    neko.Lib.print(name+" : ");
    if( passwd ) {
      var s = new StringBuf();
      var c;
      while( (c = neko.io.File.getChar(false)) != 13 )
        s.addChar(c);
      print("");
      return s.toString();
    }
    return neko.io.File.stdin().readLine();
  }

  
  public static
  function process():Command {
    getSwitches();
    return switch (getCommand()) {
    case "list":
      LIST;
    case "path":
      var projects = new Array<{project:String,version:String}>();
      eachParam(function(p) {
          var
            pv = p.split(":"),
            version = (pv.length == 1) ? null : pv[1];
          projects.push({project:pv[0],version:version});
        });
      PATH(projects);
    case "remove":
      var prj = param("Project");
      var ver = paramOpt();
      REMOVE(prj,ver);
    case "set":
      var
        prj = param("Project"),
        version = param("Version");
       SET(prj,version);
    case "dev":
      var
        prj = param("Project"),
        dir = paramOpt();
      DEV(prj,dir);
    case "setup":
      print("Please enter haxelib repository path with write access");
      print("Hit enter for default ("+ClientCore.getRepository()+")");
      var line = param("Path");
      if( line != "")
        SETUP(line);
      else throw "Need a path";
    case "package":
      print("Enter the path to the hbl file");
      var hbl = param("Hbl File");
      PACKAGE(hbl);
    case "submit":
      print("Enter the path to the package zip file");
      var path = param("Zip file");
      SUBMIT(path);
    default:
      NOOP;
    }	      	
  }

  static
  function ask( question ) {
    while( true ) {
      neko.Lib.print(question+" [y/n/a] ? ");
      switch( neko.io.File.stdin().readLine() ) {
      case "n": return No;
      case "y": return Yes;
      case "a": return Always;
      }
    }
    return null;
  }

  public static
  function usage() {
    Os.print("Haxe Library Manager "+ClientMain.VERSION+" - (c)2009 ");
    Os.print(" Usage : haxelib [switches] [command] [options]");
    Os.print(" Commands :");
    for( c in Reflect.fields(commands))
      Os.print("  "+c+" : "+Reflect.field(commands,c));
    neko.Sys.exit(1);
  }
}