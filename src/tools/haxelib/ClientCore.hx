
package tools.haxelib;

import tools.haxelib.Config;
import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.Common;
import tools.haxelib.Os;

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
      throw "This is the first time you are runing haxelib. Please run haxelib setup first";
    }
      
    if( !Os.exists(rep) )
      throw "haxelib Repository "+rep+" does not exists. Please run haxelib setup again";

    repositoryDir = rep +"/";
    return repositoryDir;
  }

  public function
  getRepository() {
    return getRepos();
  }
  
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
    return Os.fileIn(projectDir(prj) + "/.current");
  }

  static inline function
  devVersion(prj) {
    return Os.fileIn(projectDir(prj) + "/.dev");
  }

  static function
  configuration(prj:String,?ver:String):Config {
    var
      v = (ver == null) ? currentVersion(prj) : ver,
      f = versionDir(prj,v) + "haxelib.json";
    
    if (!Os.exists(f)) throw "haxelib.json does not exist!";
    return new ConfigJson(Os.fileIn(f));
  }
  
  public function
  list(options:Options) {
    var rep = getRepository();
    for( p in Os.dir(rep) ) {
      if( p.charAt(0) == "." )
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
      deps = conf.library().depends;

    if (deps != null) {
      for( d in conf.library().depends )
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
      var pdir = Common.safe(d.project)+"/"+Common.safe(d.version)+"/";
      var dir = rep + pdir;
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
      progress.close();
      neko.FileSystem.deleteFile(filePath);
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
      json = Os.readFromZip(zip,"haxelib.json");

    f.close();
    
    if (json == null) 
      throw "Package doesn't have haxelib.json";
    
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

    var deps = conf.library().depends;

    if (deps != null) {
      for(d in conf.library().depends)
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
  run() {

  }

  public function
  test() {

  }

  public function
  packit(hblFile:String) {
    var
      hbl = HblTools.process(hblFile),
      conf = HblTools.getConfig(hbl);
    
    Package.createFrom(conf);
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