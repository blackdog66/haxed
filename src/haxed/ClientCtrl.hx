package haxed;

import haxed.Os;
import haxed.Common;
import haxed.ClientCore;

using StringTools;

class ClientCtrl {
  
  static var commands = new Hash<String>();

  static function commandHelp() {
    commands.set("install", "install a given project");
    commands.set("list","list all installed projects");
    commands.set("upgrade","upgrade all installed projects");
    commands.set("remove","remove a given project/version");
    commands.set("set","set the current version for a project");
    commands.set("search","list projects matching a word");
    commands.set("info","list information about a given project");
    commands.set("user","list information about a given user");
    commands.set("register","register yourself with a haxe repository");
    commands.set("submit","submit or update a project package");
    commands.set("setup","set the haxed repository path");
    commands.set("config","print the repository path");
    commands.set("run","run the specified project with parameters");
    commands.set("test","install the specified package locally");
    commands.set("dev","set the development directory for a given project");
    commands.set("path","give paths to libraries");
    commands.set("pack","package the project");
    commands.set("projects","list all projects");
    commands.set("account","update your registered email address,password and name");
    commands.set("reminder","send password to your registered email address");
    commands.set("new","create a new project.haxed in the current directory");
    commands.set("build","build your project");
    commands.set("toptags","most used tags");
    commands.set("task","execute a task");
  }

  static var curArg = 0;
  static var args = neko.Sys.args();

  public
  static function println(str:String) {
    neko.Lib.println(str);
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

  static inline function
  getCommand() {
    return args[curArg++];
  }

  static function
  eachParam(fn:String->Void) {
    while (curArg < args.length) {
       fn(args[curArg]);
       curArg++;
    }
  }

  static function
  paramOpt() {
    if( args.length > curArg )
      return args[curArg++];
    return null;
  }

  static function
  err(fld,msg) {
    neko.Lib.println(((msg == null) ? " ! bad value for "+ fld : msg));
  }

  static function
  readLine(hidden:Bool):String {
    if(hidden) {
      var
        s = new StringBuf(),
        c;
      while( (c = neko.io.File.getChar(false)) != 13 )
        s.addChar(c);
      println("");
      return s.toString();
    }
    return neko.io.File.stdin().readLine();
  }
  
  static function
  param(name:String,?validate:String->String,?errMsg:String,?hidden:Bool) {
    var
      val = null,
      msg = null;
    
    if( args.length > curArg  ) {
      val = args[curArg++];
      if (validate != null) {
        if (validate(val) == null) {
          err(name,errMsg);
          neko.Sys.exit(1);
        }
        
      }
      return val;
    }
    
    if (validate != null) {      
      do {
        neko.Lib.print(name+" : ");
        val = validate(StringTools.trim(readLine(hidden))) ;
        if (val == null) {
          err(name,errMsg);
        }
      } while (val == null);
      return val;
    }
       
    neko.Lib.print(name+" : ");  
    return StringTools.trim(readLine(hidden));
  }

  static function checkHaxedExt(s:String) {
    var file = (s.endsWith(Common.HXP_EXT) ? s : s + "."+Common.HXP_EXT);
    
    if (!Os.exists(file)) {
        Os.print(file +" does not exist");
        neko.Sys.exit(0);
      }
    
    return file; 
  }

  static function check(file:String,t:String,searchFor:String):Dynamic {
    var
      conf = ClientCore.getConfig(file),
      items:Array<Dynamic> ;
      if (t == "task")
        items = conf.tasks();
      else
        items = conf.build();

      var found:Dynamic = null;

      for (i in items) {
        if (i.name == searchFor)
          found = i;
      }
        
      if (found != null) {
     
        return found;
      
      } else {
        Os.print("Can't find "+t+" "+searchFor);
        neko.Sys.exit(0);
      }
      
      return null;
  }
  
  static function getPW(prompt="Password",opt=false):String {
    var
      confirm,
      optionalValidation = (opt) ? Validate.optPassword : Validate.password, 
      prmpt = prompt +((opt) ? " (optional)":""),
      npass = param(prmpt,optionalValidation,null,true);
    
    if (npass != "") {
      do {
        confirm = param("Confirm",Validate.password,true);
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
        email = param("Email",Validate.email),
        password = getPW(),
        fullName = param("Full Name");

      REMOTE(REGISTER(email,password,fullName),options);

    case "list":
      LOCAL(LIST,options);

    case "user":
      REMOTE(USER(param("Email",Validate.email)),options);

    case "path":
      var projects = new Array<PrjVer>();
      eachParam(function(p) {
          var
            pv = p.split(":"),
            version = (pv.length == 1) ? null : pv[1];
          projects.push({prj:pv[0],ver:version,op:null});
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
      println("Please enter haxed repository path with write access");
      //      print("Hit enter for default ("+ClientCore.getRepos()+")");
      var line = param("Path",Validate.path);
      LOCAL(SETUP(line),options);

    case "test":
      var
        path = param("Zip file",Validate.zip);
      LOCAL(TEST(path),options);
      
    case "pack":
      var hxp = checkHaxedExt(param("Project"));
      LOCAL(PACK(hxp),options);
      
    case "run":
      var
        prj = param("Project"),
        args = new Array<String>();
      
      eachParam(function(p) {
          args.push(p);
        });

      LOCAL(RUN(prj,args),options);

    case "new":
      var vals = null;
      
      if (Os.ask("Interactive?") == Yes ) {
        vals=askAboutHxp();
        if (Os.exists(vals.name))
          if (Os.ask(vals.name+" exists, overwrite?") == No)
            neko.Sys.exit(0);
      }

      LOCAL(NEW(vals),options);

    case "build":
      var
        file = checkHaxedExt(param("Project")),
        target = param("Target (all)");
      
      if (target == "")
        target = "all";
      else 
        check(file,"build",target);
      
      LOCAL(BUILD(file,target),options);

    case "task":
      var
        file = checkHaxedExt(param("Project")),
        taskName = param("Task"),
        userPrms = [],
        task:Task = check(file,"task",taskName);
    
      if (task != null) {
          if (task.params != null) {      
            for (prm in task.params) {
              var p = prm.split("=");
              var a = param("Param:"+p[0] +" (" + p[1] +")");
              userPrms.push((a == "") ? p[1] : a);
            }
          }
      } else {
        Os.print("Can't find task "+taskName +" in file "+file);
        neko.Sys.exit(0);
      }
          
      LOCAL(TASK(task,userPrms),options);
      
    case "projects":
      REMOTE(PROJECTS,options);
      
    case "info":
      var prj = param("Project");
      REMOTE(INFO(prj),options);

    case "submit":
      var
        path = param("Zip file"),
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
        cemail = param("Current email",Validate.email),
        cpass = getPW("Current password",false),
        nemail = param("New email (optional)",Validate.optionalEmail),      
        nName = param("New name (optional)"),
        npass = getPW("New password",true);
      
      REMOTE(ACCOUNT(cemail,cpass,nemail,npass,nName),options);

    case "license":
      REMOTE(LICENSE,options);

    case "serverinfo":
      REMOTE(SERVERINFO,options);

    case "reminder":
      var email = param("Email",Validate.email);
      REMOTE(REMINDER(email),options);

    case "toptags":
      var nTags = param("Top N (provide an int)");
      REMOTE(TOPTAGS(Std.parseInt(nTags)),options);
    default:
      usage();
      null;
    }	      	
  }

  public static
  function usage() {
    commandHelp();
    Os.print("Haxe Library Manager "+ClientMain.VERSION+" - (c) 2010 ");
    Os.print(" Usage : haxed [command] [options]");
    Os.print(" ---------------------------------------------");
    Os.print(" by blackdog (http://blackdog66.wordpress.com)");
    Os.print(" financial inspiration John De Goes");
    Os.print(" ---------------------------------------------");
    Os.print(" Commands :");
    for(c in commands.keys())
      Os.print("  "+c+" : "+commands.get(c));
    neko.Sys.exit(1);
  }

  public static function
  askAboutHxp():Global {
    return {
    	name:param("Project name"),
        authorName:param("Author name"),
        authorEmail:param("Author email",Validate.email),
        version:param("Version"),
        comments:param("Version comments"),
        description:param("Descripion"),
        tags:Validate.toArray(param("Tags")),
        website:param("Website",Validate.url),
        license:param("License"),
        derivesFrom:null
        };
    }
}
