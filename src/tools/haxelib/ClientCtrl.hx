package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ClientCore;

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
    register :"register yourself with a haxe repository",
    submit : "submit or update a project package",
    setup : "set the haxelib repository path",
    config:"print the repository path",
    run:"run the specified project with parameters",
    test:"install the specified package locally",
    dev:"set the development directory for a given project",
    path:"give paths to libraries",
    pack:"package the project specified by the hbl file",
    account: "update your registered email address,password and name",
  };

  static var curArg = 0;
  static var args = neko.Sys.args();

  public
  static function print(str) {
    neko.Lib.print(str+"\n");
  }
  
  static
  function getOptions() {
    var
      o = new Options();
  
    if (args.length > 0) {
      while (curArg < args.length && StringTools.startsWith(args[curArg],"-")) {
        var flag = (args[curArg].toLowerCase() == args[curArg]) ;
        if (flag) {
          o.addSwitch(args[curArg],"true");
          curArg += 1;
        } else {
          o.addSwitch(args[curArg],args[curArg+1]);
          curArg += 2;
        }
        
      }
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
       fn(args[curArg]);
       curArg++;
    }
  }

  static
  function paramOpt() {
    if( args.length > curArg )
      return args[curArg++];
    return null;
  }

  static function err(fld,msg) {
    neko.Lib.println("! " + ((msg == null) ? " ! bad value for "+ fld : msg));
  }

  static function readLine(hidden:Bool):String {
    if(hidden) {
      var s = new StringBuf();
      var c;
      trace("getting hidffen");
      while( (c = neko.io.File.getChar(false)) != 13 )
        s.addChar(c);
      print("");
      return s.toString();
    }
    return neko.io.File.stdin().readLine();
  }
  
  static
  function param(name:String,?validate:String->String,hidden=false) {
    var
      val = null,
      msg = null;
    
    if( args.length > curArg  ) {
      val = args[curArg++];
      if (validate != null) {
        msg = validate(val);
        if (msg != null) throw err(name,msg);
      }
      return val;
    }
    
    if (validate != null) {      
      do {
        neko.Lib.print(name+" : ");
        val = StringTools.trim(readLine(hidden));
        msg = validate(val);
        if (msg != null) err(name,msg);
      } while (msg != null);
      return val;
    }
       
      
    neko.Lib.print(name+" : ");  
    return StringTools.trim(readLine(hidden));
  }


  static function validPath(v) {
    return (Os.exists(v)) ? null : "directory does not exist"; }

  static function validHbl(v) {
    return (Os.exists(v)) ? null: "hbl file does not exist"; }

  static function validZip(v) {
    return ((StringTools.endsWith(v,".zip") && Os.exists(v)) ? null : "zip doesn't exist"); 
  }
  
  static function getPW(msg="Password",opt=false):String {
    var
      confirm,
      npass = param(msg +((opt) ? " (optional)":""),
                    (opt) ? Common.optionalPW : Common.validPW);
    
    if (npass != "") {
      do {
        confirm = param("Confirm",Common.validPW,false);
        trace("npass="+npass+", confirm = "+confirm);
      } while(npass != confirm);
    }
    return npass;
  }
  
  public static
  function process():CmdContext {
    var
      command = getCommand(),
      options = getOptions();

    return switch (command) {

    case "register":
      var
        email = param("Email",Common.validEmail),
        password = getPW(),
        fullName = param("Full Name");

      REMOTE(REGISTER(email,password,fullName),options);

    case "list":
      LOCAL(LIST,options);

    case "user":
      REMOTE(USER(param("Email",Common.validEmail)),options);

    case "path":
      var projects = new Array<{project:String,version:String}>();
      eachParam(function(p) {
          var
            pv = p.split(":"),
            version = (pv.length == 1) ? null : pv[1];
          projects.push({project:pv[0],version:version});
        });
      LOCAL(PATH(projects),options);

    case "remove":
      var
        prj = param("Project"),
        ver = paramOpt();
      LOCAL(REMOVE(prj,ver),options);

    case "set":
      var
        prj = param("Project"),
        version = param("Version");
      LOCAL(SET(prj,version),options);

    case "upgrade":
      LOCAL(UPGRADE,options);

    case "config":
      LOCAL(CONFIG,options);
      
    case "dev":
      var
        prj = param("Project"),
        dir = paramOpt();
      LOCAL(DEV(prj,dir),options);

    case "setup":
      print("Please enter haxelib repository path with write access");
      //      print("Hit enter for default ("+ClientCore.getRepos()+")");
      var line = param("Path",validPath);
      LOCAL(SETUP(line),options);

    case "test":
      var
        path = param("Zip file",validZip);
      LOCAL(TEST(path),options);
      
    case "pack":
      var hbl = param("Hbl File",validHbl);
      LOCAL(PACK(hbl),options);
      
    case "run":
      var
        prj = param("Project"),
        args = new Array<String>();
      
      eachParam(function(p) {
          args.push(p);
        });

      LOCAL(RUN(prj,args),options);
    case "projects":
      REMOTE(PROJECTS,options);
      
    case "info":
      var prj = param("Project");
      REMOTE(INFO(prj),options);

    case "submit":
      var
        path = param("Zip file",validZip),
        password = param("Password");
      
      options.addSwitch("-P",password);
      REMOTE(SUBMIT(path),options);

    case "install":
      var
        prj = param("Project name"),
        ver = paramOpt();
      LOCAL(INSTALL(prj,ver),options);

    case "search":
      var
        word = param("Word");
      REMOTE(SEARCH(word),options);

    case "account":
      var
        cemail = param("Current email",Common.validEmail),
        cpass = getPW("Current password"),
        nemail = param("New email (optional)",Common.optionalEmail),      
        nName = param("New name (optional)"),
        npass = getPW("New password",true);
      
      REMOTE(ACCOUNT(cemail,cpass,nemail,npass,nName),options);

    case "license":
      REMOTE(LICENSE,options);

    case "serverinfo":
      REMOTE(SERVERINFO,options);
      
    default:
      usage();
      null;
    }	      	
  }

  public static
  function usage() {
    Os.print("Haxe Library Manager "+ClientMain.VERSION+" - (c)2009 ");
    Os.print(" Usage : haxelib [command] [options]");
    Os.print(" Commands :");
    for( c in Reflect.fields(commands))
      Os.print("  "+c+" : "+Reflect.field(commands,c));
    neko.Sys.exit(1);
  }
}