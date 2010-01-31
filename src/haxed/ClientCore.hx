
package haxed;

import haxed.Parser;
import haxed.Package;
import haxed.Common;
import haxed.Os;
import haxed.Builder;

using Lambda;

private typedef ClientConf = {
  var repos:Array<String>;
}
  

class RemoteRepos {
  // files can be found in repo + "/"+REPO_URI
  public static var REPO_URI = "files"; 
  static var repos:Array<String>;
  static var client:ClientCore;
  
  public static
  function init(c:ClientCore) {
    client = c;
    var
      conf:ClientConf = hxjson2.JSON.decode(haxe.Resource.getString("clientConfig"));

    repos = conf.repos;    
  }
  
  static
  function doRepo(cmd:String,prms:Dynamic,rps:Array<String>,
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
  
  public static
  function each(cmd:String,prms:Dynamic,fn:String->Dynamic->Bool) {
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

  static var REPNAME = "lib";
  static var repositoryDir;
  
  public function new() { }

  public function request(u:String,prms:Dynamic,fn:Dynamic->Void) { }
  public function url(url:String,command:String) { return ""; }
  public function install(options:Options,prj:String,ver:String) {}
  
  static function
  getConfigFile() {
    var config = neko.Sys.getEnv("HOME")+"/.haxelib";
    if (Os.exists(config))
      return config;

    config = "/etc/.haxelib";
    if (Os.exists(config))
      return config;

    throw "config file not found";
    return null;
  }

  public static function
  getRepos() {
    if (repositoryDir != null)
      return repositoryDir;
  
    var sys = neko.Sys.systemName();
    if( sys == "Windows" ) {
      var haxepath = neko.Sys.getEnv("HAXEPATH");
      if( haxepath == null )
        throw "HAXEPATH environment variable not defined, please run haxesetup.exe first";
      var last = haxepath.charAt(haxepath.length - 1);
      if( last != "/" && last != "\\" )
        haxepath += "/";
      var rep = haxepath+REPNAME;
      try {
        Os.safeDir(rep);
      } catch( e : Dynamic ) {
        throw "The directory defined by HAXEPATH does not exist, please run haxesetup.exe again";
      }
      return rep+"\\";
    }

    var rep = try {
      Os.fileIn(getConfigFile());
    } catch( e : Dynamic ) {
      throw "This is the first time you are runing haxed. Please run haxed setup first";
    }
      
    if( !Os.exists(rep) )
      throw "haxed Repository "+rep+" does not exists. Please run haxed setup again";

    repositoryDir = rep +"/";
    return repositoryDir;
  }

  public function
  getRepository() {
    return getRepos();
  }

  public function getInfo(prj:String,inf:ProjectInfo->Void) {}
  
  static inline function
  projectDir(prj) {
    return Common.slash(getRepos() + Common.safe(prj));
  }

  static inline function
  versionDir(prj,ver) {
    return Common.slash(projectDir(prj) + Common.safe(ver));
  }

  static inline function
  currentVersion(prj) {
    try {
    return Os.fileIn(projectDir(prj) + "/.current");
    } catch(exc:Dynamic) {
      return null;
    }
  }

  static inline function
  devVersion(prj) {
    try {
    return Os.fileIn(projectDir(prj) + "/.dev");
    } catch (exc:Dynamic) {
      return null;
    }
  }

  static function
  configuration(prj:String,?ver:String):Config {
    var
      v = (ver == null) ? currentVersion(prj) : ver,
      f = versionDir(prj,v) + Common.CONFIG_FILE;
    
    if (!Os.exists(f)) throw f+" does not exist!";
    return new ConfigJson(Os.fileIn(f));
  }
  
  public function
  list(options:Options) {
    var rep = getRepository();
    for( p in Os.dir(rep) ) {
      
      if( p.charAt(0) == "." )
        continue;
      if (!Os.isDir(rep+p))
        continue;
      
      var
        versions = new Array(),
        current = currentVersion(p),
        dev = try devVersion(p) catch( e : Dynamic ) null;

      for( v in Os.dir(projectDir(p)) ) {
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
    var pdir = projectDir(prj);

    if( version == null ) {
      if( !Os.exists(pdir) )
        throw "Project "+prj+" is not installed";

      Os.rmdir(pdir);
      Os.print("Project "+prj+" removed");
      return;
    }

    var vdir = versionDir(prj,version);
    

    if( !Os.exists(vdir) )
      throw "Project "+prj+" does not have version "+version+" installed";

    var cur = currentVersion(prj);
    if( cur == version )
      throw "Can't remove current version of project "+prj;

    Os.rmdir(vdir);
    Os.print("Project "+prj+" version "+version+" removed");
  }

  
  function
  checkRec( prj : String, version : String, l : List<{ project : String, version : String }> ) {
    var pdir = projectDir(prj);
    if( !Os.exists(pdir) )
      throw "Dependancy "+prj+" is not installed";

    var version = if( version != null ) version else currentVersion(prj);
    var vdir = versionDir(prj,version);

    if(!Os.exists(vdir))
      throw "Project "+prj+" version "+version+" is not installed";

    for( p in l )
      if( p.project == prj ) {
        if( p.version == version )
          return;
        throw "Project "+prj+" has two version included "+version+" and "+p.version;
      }

    l.add({ project : prj, version : version });

    var
      conf = configuration(prj),
      deps = conf.build().depends;

    if (deps != null) {
      for( d in conf.build().depends )
        checkRec(d.prj,if( d.ver == "" ) null else d.ver,l);
    }
  }
  
  public function
  path(projects:Array<{project:String,version:String}>) {

    var list = new List();
    for (p in projects) {
      checkRec(p.project,p.version,list);
    }
    
    var rep = getRepository();
    for( d in list) {
      var
        pdir = Common.safe(d.project)+"/"+Common.safe(d.version)+"/",
        dir = rep + pdir;
      try {
        dir = devVersion(d.project);
        if( dir.length == 0 || (dir.charAt(dir.length-1) != '/' && dir.charAt(dir.length-1) != '\\') )
          dir += "/";
        pdir = dir;
      } catch( e : Dynamic ) {

      }
      var ndir = dir + "ndll";
      if(Os.exists(ndir) ) {
        var sysdir = ndir+"/"+neko.Sys.systemName();
        if( !Os.exists(sysdir) )
          throw "Project "+d.project+" version "+d.version+" does not have a neko dll for your system";
        Os.print("-L "+pdir+"ndll/");
      }
      Os.print(dir);
    }
  }

  public function
  doInstall(options:Options,repoUrl,prj,ver,license) {
    if (Os.exists(versionDir(prj,ver))) {
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
      filePath = getRepos() + fileName;

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
      pdir = projectDir(prj);
    
    Os.safeDir(pdir);
    var target = versionDir(prj,ver);
    Os.safeDir(target);
    Os.unzip(zip,target);
    setCurrentVersion(prj,ver);
    Os.rm(filePath);

    var deps = conf.build().depends;

    if (deps != null) {
      for(d in conf.build().depends)
        install(new Options(),d.prj,d.ver);
    }
  }
    
  public function
  config(options:Options){
	Os.print(getRepository());
  }

  public function
  dev(prj:String,dir:String) {
	var
      rep = getRepository(),
      devfile = rep + Common.safe(prj)+"/.dev";
    
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
    var pdir = projectDir(prj);
    if (!Os.exists(pdir)) throw "setCurrentVersion: "+pdir+" does not exist";
    Os.fileOut(pdir + ".current",version);
    Os.print("  Current version is now "+version);
  }
  
  public function
  set(prj:String,version:String){
    var
      vdir = versionDir(prj,version);

    if( !Os.exists(vdir) )
      throw "Project "+prj+" version "+version+" is not installed";

    if (currentVersion(prj) == version) {
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
    
    Os.fileOut(getConfigFile(),path) ;
  }

  public function
  upgrade() {
    var
      me = this,
      rep = getRepos(),
      prompt = true,
      update = false;
    
    for(prj in Os.dir(rep) ) {
      if( prj.charAt(0) == "." || !Os.isDir(rep+"/"+prj) )
        continue;
      if (prj == Common.HXP_FILE)
        continue;

      var p = Common.unsafe(prj);
      Os.print("Checking "+p);

      getInfo(p,function(inf) {
          if(!Os.exists(versionDir(p,inf.curversion))) {
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
    
    if( !Os.exists(projectDir(prj)))
      throw "Project "+prj+" is not installed";

    var
      ver = currentVersion(prj),
      devVer = devVersion(prj),
      vdir = (devVer != null) ? versionDir(prj,devVer) : versionDir(prj,ver),
      runcmd = vdir + "/run.n";

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
      hxp = Parser.process(hxpFile),
      conf = Parser.getConfig(hxp);

    return Package.createFrom(conf);
  }
  
  public function
  newHxp(interactive:Global) {
    if (interactive == null) {
      var nf = getRepos() + Common.HXP_FILE;
      if (!Os.exists(nf)) {
        Os.fileOut(nf,haxe.Resource.getString("HxpTemplate"));
      }

      Os.cp(nf,Common.HXP_FILE);
    } else {
      // the inadequacies of haxe template here ...
      Reflect.setField(interactive,"tags",Lambda.map(Reflect.field(interactive,"tags"),function(t) { return {tag:t}; }));
      
      var tmpl = '
---
project:
    name:            ::name::
    website:            ::website::
    version:            ::version::
    comments:           ::comments::
    description:        ::description::
    author:             ::authorName::
    author-email:       ::authorEmail::
    tags:               ::foreach tags::::tag:: ::end::
    license:            ::license::
';
      Os.fileOut(Common.HXP_FILE,tmpl,interactive);
      
    }
  }

  public function
  build(hxpFile:String) {
    var hxp = Parser.process(hxpFile);
    Builder.compile(Parser.getConfig(hxp));
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