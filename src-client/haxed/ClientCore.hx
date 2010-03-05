
package haxed;

import bdog.Os;
import bdog.JSON;
import haxed.Parser;
import haxed.Package;
import haxed.Common;
import haxed.Builder;
import haxed.compatible.Convert;
import haxed.ClientTools;

using Lambda;

private typedef ClientConf = {
  var repos:Array<String>;
}
  

class RemoteRepos {
  // files can be found in repo + "/"+REPO_URI
  public static var REPO_URI = "files"; 
  static var repos:Array<String>;
  static var client:ClientCore;
  
  public static function
  init(c:ClientCore) {
    client = c;
    var
      section = ClientMain.config.section("haxed"),
      conf:ClientConf = { repos : Validate.toArray(section.repos) };

    repos = conf.repos;    
  }
  
  static function
  doRepo(cmd:String,prms:Dynamic,rps:Array<String>,
                  userFn:String->Dynamic->Bool) {
    var next = rps.shift();
    if (next == null)
      return;

    var u = client.url(next,cmd),
      wrapper = function(d) {
      if (!userFn(next,d)) {
          // userFn did not handle repo, pass to next
          doRepo(cmd,prms,rps,userFn);
        }
      }

    // start off the server chain ...
    client.request(u,prms,wrapper);
  }
  
  public static function
  each(cmd:String,prms:Dynamic,fn:String->Dynamic->Bool) {
    if (repos == null) throw "must call RemoteRepos.init() first";
    
    var tmpRepos = repos.copy();
    doRepo(cmd,prms,tmpRepos,fn);
  }  
}


/*
  Implement all the local functions, remote operations are implemented by
  descendant.
*/

class ClientCore {

  public function new() {}
  public function request(u:String,prms:Dynamic,fn:Dynamic->Void) { }
  public function url(url:String,command:String) { return ""; }
  public function install(options:Options,prj:String,ver:String) {}
  public function getInfo(prj:String,inf:ProjectInfo->Void) {}  
  
  public function
  list(options:Options) {
    var rep = ClientTools.getRepository();
    for( p in Os.dir(rep) ) {
      
      if( p.charAt(0) == "." )
        continue;
      if (!Os.isDir(rep+p))
        continue;
      
      var
        versions = new Array(),
        current = ClientTools.currentVersion(p),
        dev = try ClientTools.devVersion(p) catch( e : Dynamic ) null;

      for( v in Os.dir(ClientTools.projectDir(p)) ) {
        if( v.charAt(0) == "." )
          continue;
        
        v = Common.unsafe(v);
        if( dev == null && v == current )
          v = "["+v+"]";
       versions.push(v);
      }
      
      if( dev != null )
        versions.push("[dev:"+dev+"]");

      Os.print(Common.unsafe(p) + ": "+versions.join(" "));
    }
  }
  
  public function
  remove(option:Options,prj:String,version:String) {
    var pdir = ClientTools.projectDir(prj);

    if( version == null ) {
      if( !Os.exists(pdir) )
        throw "Project "+prj+" is not installed";

      Os.rmdir(pdir);
      Os.print("Project "+prj+" removed");
      return;
    }

    var vdir = ClientTools.versionDir(prj,version);

    if( !Os.exists(vdir) )
      throw "Project "+prj+" does not have version "+version+" installed";

    var cur = ClientTools.currentVersion(prj);
    if( cur == version )
      throw "Can't remove current version of project "+prj;

    Os.rmdir(vdir);
    Os.print("Project "+prj+" version "+version+" removed");
  }

  public function
  path(projects:Array<PrjVer>) {
    for (p in ClientTools.internalPath(projects)) {
      Os.print(p);
    }
  }

  public function
  doInstall(options:Options,repoUrl,prj,ver,license) {
    if (Os.exists(ClientTools.versionDir(prj,ver))) {
      Os.print("You already have "+prj+" version "+ver+" installed");
      setCurrentVersion(prj,ver);
      return true;
    }
    
    if(!License.isPublic(license)) {
      var l = License.getUrl(license);
      var resp = haxe.Http.requestUrl(l);
      Os.print(resp) ;
      if (Os.ask("Do you accept the license?") == No) {
        Os.print("Discontinuing install");
        neko.Sys.exit(0);
      }
    }
    
    var
      fileName = Common.pkgName(prj,ver),
      filePath = ClientTools.getRepos() + fileName;

    download(repoUrl,filePath,fileName);
    return true;
  }

  function
  download(repoUrl:String,filePath:String,fileName:String) {
    trace("http://"+repoUrl+"/"+RemoteRepos.REPO_URI+"/"+fileName);
    var
      h = new haxe.Http("http://"+repoUrl+"/"+RemoteRepos.REPO_URI+"/"+fileName),
      out = neko.io.File.write(filePath,true),
      me = this,
      dlFinished = function() {
      	me.unpack(filePath,fileName);
      },
      progress = new Progress(dlFinished,out);

	h.onError = function(e) {
      try {
        neko.FileSystem.deleteFile(filePath);
        progress.close();
      } catch (exc:Dynamic) {}
      throw e;
    };

    Os.print("Downloading "+fileName+"...");
    h.customRequest(false,progress); 
  }

  function
  unpack(filePath:String,fileName:String) {
    var
      f = neko.io.File.read(filePath,true),
      zip = neko.zip.Reader.readZip(f),
      json = Os.readFromZip(zip,Common.CONFIG_FILE);

    f.close();
    
    if (json == null) 
      throw "Package doesn't have "+Common.CONFIG_FILE;
    
    var
      conf = new ConfigJson(json),
      glbs = conf.globals(),    
      prj = glbs.name,
      ver = glbs.version,
      pdir = ClientTools.projectDir(prj);
    
    Os.safeDir(pdir);
    var target = ClientTools.versionDir(prj,ver);
    Os.safeDir(target);
    Os.unzip(zip,target);
    setCurrentVersion(prj,ver);
    Os.rm(filePath);

    var defaultBuild = conf.defaultBuild();
    if (defaultBuild != null) {
      var deps = defaultBuild.depends;
      if (deps != null) {
        for(d in deps)
          install(new Options(),d.prj,d.ver);
      }
    }
  }
    
  public function
  config(options:Options){
	Os.print(ClientTools.getRepository());
  }

  public function
  dev(prj:String,dir:String) {
	var
      rep = ClientTools.getRepository(),
      devfile = rep + Os.slash(Common.safe(prj))+".dev";
    
    if( dir == null ) {
      if(Os.exists(devfile) )
        Os.rm(devfile);
      Os.print("Development directory disabled");
    } else {
      Os.fileOut(devfile,dir);
      Os.print("Development directory set to "+dir);
    }
  }

  static function
  setCurrentVersion(prj:String,version:String) {
    var pdir = ClientTools.projectDir(prj);
    if (!Os.exists(pdir)) throw "setCurrentVersion: "+pdir+" does not exist";
    Os.fileOut(pdir + ".current",version);
    Os.print("  Current version is now "+version);
  }
  
  public function
  set(prj:String,version:String){
    var
      vdir = ClientTools.versionDir(prj,version);

    if( !Os.exists(vdir) )
      throw "Project "+prj+" version "+version+" is not installed";

    if (ClientTools.currentVersion(prj) == version) {
      Os.print("Version is "+version);
      return ;
    }
    
    setCurrentVersion(prj,version);
  }
  
  public function
  setup(path){
    if( !Os.exists(path) ) {
      try {
        Os.mkdir(path);
      } catch( e : Dynamic ) {
        Os.print("Failed to create directory '"+path
                 +"' ("+Std.string(e)+"), maybe you need appropriate user rights");
        neko.Sys.exit(1);
      }
    }

    Os.fileOut(ClientTools.getConfigFile(true),path) ;
  }

  public function
  upgrade() {
    var
      me = this,
      rep = ClientTools.getRepos(),
      prompt = true,
      update = false;
    
    for(prj in Os.dir(rep) ) {
      if( prj.charAt(0) == "." || !Os.isDir(Os.slash(rep)+prj) )
        continue;
      if (prj == Common.HXP_FILE)
        continue;

      var p = Common.unsafe(prj);
      Os.print("Checking "+p);

      getInfo(p,function(inf) {
          if(!Os.exists(ClientTools.versionDir(p,inf.curversion))) {
            /*
          if( prompt )
            switch ask("Upgrade "+p+" to "+inf.curversion) {
              case Yes:
              case Always: prompt = false;
              case No: continue;
              }
          */
            me.install(new Options(),p,inf.curversion);
            update = true;
          } else {
            setCurrentVersion(p,inf.curversion);
          }
        });
    }
    
    if( update )
      Os.print("Done");
    else
      Os.print("All projects are up-to-date");
  }

  public function
  run(prj:String,args:Array<String>) {
    
    if( !Os.exists(ClientTools.projectDir(prj)))
      throw "Project "+prj+" is not installed";

    var
      ver = ClientTools.currentVersion(prj),
      devVer = ClientTools.devVersion(prj),
      vdir = (devVer != null) ? ClientTools.versionDir(prj,devVer) : ClientTools.versionDir(prj,ver),
      runcmd = Os.slash(vdir) + "run.n";

    if(!Os.exists(runcmd) )
      throw "Project " + prj + " version " + ver + " does not have a run script";
    
    neko.Sys.setCwd(vdir);
    var cmd = "neko run.n";
    for( a in args )
      cmd += " " + escapeArg(a);

    neko.Sys.exit(neko.Sys.command(cmd));
	
  }

  function escapeArg( a : String ) {
    if( a.indexOf(" ") == -1 )
      return a;
    return '"'+a+'"';
  }

  public function
  test(filePath:String) {
    var
      file = neko.io.Path.withoutDirectory(filePath);
    unpack(filePath,file);
  }

  public function
  packit(hxpFile:String):String {
    var
      conf = Parser.fromFile(hxpFile),
      confDir = Package.confDir(hxpFile);
    
    return Package.createFrom(confDir,conf);
  }
  
  public function
  newHxp(interactive:Global) {
    if (interactive == null) {
      // then copy the template - if it doesn't exist create it from the resource
      var nf = ClientTools.versionDir("haxed") + Common.HXP_TEMPLATE;
      if (!Os.exists(nf)) {
        Os.fileOut(nf,haxe.Resource.getString("HaxedTemplate"));
      }

      Os.cp(nf,Common.HXP_FILE);
    } else {
      // the inadequacies of haxe template here ...
      Reflect.setField(interactive,"tags",Lambda.map(Reflect.field(interactive,"tags"),function(t) { return {tag:t}; }));
      
      var tmpl = '
---
project:
    name:               ::name::
    website:            ::website::
    version:            ::version::
    comments:           ::comments::
    description:        ::description::
    author:             ::authorName::
    author-email:       ::authorEmail::
    tags:               ::foreach tags::::tag:: ::end::
    license:            ::license::
';
      Os.fileOut(interactive.name+".haxed",tmpl,interactive);
      
    }
  }

  /*
  public static function
  getConfig(hxpFile:String):Config {
    return Parser.getConfig(Parser.process(hxpFile));
    }*/

  
  public function
  build(config:Config,target:String,options:Options) {
    var
      prj = options.getSwitch("-lib"),
      fromLib = prj != null;
    
    if (fromLib) {
      trace("getting lib path for "+prj);
      var p = ClientTools.internalPath([
        {prj:prj,ver:ClientTools.currentVersion(prj),op:null}
       ]),
       path = p.first();

      if (path != null){
        config = Parser.configuration(path+prj+".haxed");
      } else {
        throw "Can't find "+prj +".haxed or installed library "+prj;
      }
    }
   
    doTask(config,target,"pre");
    
    Builder.compile(config,target,fromLib);

    doTask(config,target,"post");
       
  }

  public function
  task(config:Config,task:Task,prms:Array<Dynamic>,options:Options) {
    runTask(config,task,prms,options);
  }

  public static function
  runTask(config:Config,task:Task,prms:Array<Dynamic>,options:Options){    

    if (options.flag("-clean")) {
      Tasks.init();
      Os.print("Cleaning - reinitialised .haxed dir");
    }

    var
      taskID = Os.path(config.file(),NAME)+"-"+task.mainClass,
      t = new haxed.Tasks(task,taskID),
      forceCompile = Os.newer(config.file(),t.outputFile());

    if (forceCompile) {
      Os.print("Recompiling: " + config.file() + " is newer than "+ t.outputFile());
    }
    
    t.execute(prms,options,forceCompile);
  }

  static function
  doTask(c:Config,target,typ:String) {
    for (b in c.build()) {
      if (b.name == target || b.name == null || target == "all") {
        var
          prms =  (typ == "pre") ? b.preTask : b.postTask;

        if (prms != null) {
          var
            name = prms.shift(),
            gotTask = false;

          for (tsk in c.tasks()) {
            if (tsk.name == name) {
              gotTask = true;
              runTask(c,tsk,prms,new Options());
            }
          }

          if (!gotTask) Os.print("Warning: task "+ name + "  does not exist");
        }
      }
    }
  }

}



class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;
  var finishHook:Void->Void;
  
  public function new(hook,o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
        finishHook = hook;
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			neko.Lib.print(cur+" bytes\r");
		else
			neko.Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		neko.Lib.print("Download complete : "+cur+" bytes in "+time+"s ("+speed+"KB/s)\n");
        finishHook();
	}

	public override function prepare(m) {
		max = m;
	}

}