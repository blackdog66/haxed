package tools.haxelib;

import tools.haxelib.ClientCommon;
import tools.haxelib.ClientCore;


enum Answer {
  Yes;
  No;
  Always;
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
  static var emailRe = ~/[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z][A-Z][A-Z]?/i;

  public
  static function print(str) {
    neko.Lib.print(str+"\n");
  }
  
  static
  function getOptions() {
    var o = new Options();
    if (args.length > 0) {
      while (curArg < args.length && StringTools.startsWith(args[curArg],"-")) {
        o.addSwitch(args[curArg],args[curArg+1]);
        neko.Lib.println("adding "+args[curArg]+":"+args[curArg+1]);
        curArg += 2;
      }
      neko.Lib.println("curArg="+curArg);
    }
    return o;
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
    var
      command = getCommand(),
      options = getOptions();

    trace("command is "+command);
    return switch (command) {
    case "register":
      var
        email = param("Email"),
        password = param("Password"),
        fullName = param("Full Name");

      if (!emailRe.match(email)) throw "need a valid email address";
      if (password.length < 5 ) throw "need a password of 5 chars or more";
      
      REGISTER(options,email,password,fullName);
    case "list":
      LIST(options);
    case "user":
      USER(options,param("Email"));
    case "path":
      var projects = new Array<{project:String,version:String}>();
      eachParam(function(p) {
          var
            pv = p.split(":"),
            version = (pv.length == 1) ? null : pv[1];
          projects.push({project:pv[0],version:version});
        });
      PATH(options,projects);
    case "remove":
      var prj = param("Project");
      var ver = paramOpt();
      REMOVE(options,prj,ver);
    case "set":
      var
        prj = param("Project"),
        version = param("Version");
      SET(options,prj,version);
    case "dev":
      var
        prj = param("Project"),
        dir = paramOpt();
      DEV(options,prj,dir);
    case "setup":
      print("Please enter haxelib repository path with write access");
      print("Hit enter for default ("+ClientCore.getRepos()+")");
      var line = param("Path");
      if( line != "")
        SETUP(options,line);
      else throw "Need a path";
    case "package":
      print("Enter the path to the hbl file");
      var hbl = param("Hbl File");
      PACKAGE(options,hbl);
    case "info":
      print("Enter the project name");
      var prj = param("Project");
      INFO(options,prj);
    case "submit":
      var
        path = param("Zip file"),
        password = param("Password");

      SUBMIT(options,password,path);

    case "install":
      var
        prj = param("Project name"),
        ver = paramOpt();
      INSTALL(options,prj,ver);
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