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
    register :"register yourself with a haxe repository",
    submit : "submit or update a project package",
    setup : "set the haxelib repository path",
    config:"print the repository path",
    run:"run the specified project with parameters",
    test:"install the specified package locally",
    dev:"set the development directory for a given project",
    path:"give paths to libraries",
    pack_age:"package the project specified by the hbl file",
    account: "update your registered email address,password and name",
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

  static function validEmail(v:String) {
    return (emailRe.match(v)) ? null : "must be a valid email address"; }

  static function optionalEmail(v:String) {
    if (v.length > 0) return validEmail(v);
    return null; }
  
  static function validPW(v) {
    return (v.length >= 5) ? null : "must be >= 5 characters"; }

  static function optionalPW(v) {
    if (v.length > 0) return validPW(v);
    return null; }

  static function validPath(v) {
    return (Os.exists(v)) ? null : "directory does not exist"; }

  static function validHbl(v) {
    return (Os.exists(v)) ? null: "hbl file does not exist"; }

  static function validZip(v) {
    return ((StringTools.endsWith(v,".zip") && Os.exists(v)) ? null : "zip doesn't exist"); 
  }

  static function validUrl(v) {
    var r = ~/^(http:\/\/)?([^:\/]+)(:[0-9]+)?\/?(.*)$/;
    return (r.match(v)) ? null : "invalid http url";
  }

  static function getPW(msg="Password",opt=false):String {
    var
      confirm,
      npass = param(msg +((opt) ? " (optional)":""),
                    (opt) ? optionalPW : validPW);
    
    if (npass != "") {
      do {
        confirm = param("Confirm",validPW,false);
        trace("npass="+npass+", confirm = "+confirm);
      } while(npass != confirm);
    }
    return npass;
  }
  
  public static
  function process():Command {
    var
      command = getCommand(),
      options = getOptions();

    return switch (command) {

    case "register":
      var
        email = param("Email",validEmail),
        password = getPW(),
        fullName = param("Full Name");

      REGISTER(options,email,password,fullName);

    case "list":
      LIST(options);

    case "user":
      USER(options,param("Email",validEmail));

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
      //      print("Hit enter for default ("+ClientCore.getRepos()+")");
      var line = param("Path",validPath);
      SETUP(options,line);

    case "package":
      var hbl = param("Hbl File",validHbl);
      PACKAGE(options,hbl);

    case "info":
      var prj = param("Project");
      INFO(options,prj);

    case "submit":
      var
        path = param("Zip file",validZip),
        password = param("Password");
      SUBMIT(options,password,path);

    case "install":
      var
        prj = param("Project name"),
        ver = paramOpt();
      INSTALL(options,prj,ver);

    case "search":
      var
        word = param("Word");
      SEARCH(options,word);

    case "account":
      var
        cemail = param("Current email",validEmail),
        cpass = getPW("Current password"),
        nemail = param("New email (optional)",optionalEmail),      
        nName = param("New name (optional)"),
        npass = getPW("New password",true);
      
      ACCOUNT(options,cemail,cpass,nemail,npass,nName);

    case "license":
      LICENSE(options);
      
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
    Os.print(" Usage : haxelib [command] [options]");
    Os.print(" Commands :");
    for( c in Reflect.fields(commands))
      Os.print("  "+c+" : "+Reflect.field(commands,c));
    neko.Sys.exit(1);
  }
}