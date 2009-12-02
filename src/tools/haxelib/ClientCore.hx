
package tools.haxelib;

import tools.haxelib.Config;
import tools.haxelib.Habal;
import tools.haxelib.Package;
import tools.haxelib.ClientCommon;

/*
  Implement all the local functions, remote operations are implemented by
  descendant.
*/

class ClientCore {

  static var REPNAME = "lib";
  
  public function new() { }

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

  static function
  getRepoDir() {
    return try {
      Os.fileIn(getConfigFile());
    } catch( e : Dynamic ) {
      throw "This is the first time you are runing haxelib. Please run haxelib setup first";
    }
  }

  public function
  getRepository() {
    return getRepos();
  }
  
  public static function
  getRepos() {
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

    var rep = getRepoDir();
      
    if( !Os.exists(rep) )
      throw "haxelib Repository "+rep+" does not exists. Please run haxelib setup again";
    return rep+"/";
  }

  public function
  list(options:Options) {
    var rep = getRepository();
    for( p in Os.dir(rep) ) {
      if( p.charAt(0) == "." )
        continue;
      var versions = new Array();
      var current = Os.fileIn(rep+p+"/.current");
      var dev = try Os.fileIn(rep+p+"/.dev") catch( e : Dynamic ) null;
      for( v in Os.dir(rep+p) ) {
        if( v.charAt(0) == "." )
          continue;
        v = Os.unsafe(v);
        if( dev == null && v == current )
          v = "["+v+"]";
       versions.push(v);
      }
      if( dev != null )
        versions.push("[dev:"+dev+"]");
      Os.print(Os.unsafe(p) + ": "+versions.join(" "));
    }
  }

  function
  deleteRec(dir) {
    for( p in neko.FileSystem.readDirectory(dir) ) {
      var path = dir+"/"+p;
      if( neko.FileSystem.isDirectory(path) )
        deleteRec(path);
      else
        Os.rm(path);
    }
    neko.FileSystem.deleteDirectory(dir);
  }
  
  public function
  remove(option:Options,prj:String,version:String) {
    var rep = getRepository();
    var pdir = rep + Os.safe(prj);

    if( version == null ) {
      if( !Os.exists(pdir) )
        throw "Project "+prj+" is not installed";
      deleteRec(pdir);
      Os.print("Project "+prj+" removed");
      return;
    }

    var vdir = pdir + "/" + Os.safe(version);
    if( !Os.exists(vdir) )
      throw "Project "+prj+" does not have version "+version+" installed";

    var cur = Os.fileIn(pdir+"/.current");
    if( cur == version )
      throw "Can't remove current version of project "+prj;
    deleteRec(vdir);
    Os.print("Project "+prj+" version "+version+" removed");
  }

  function
  checkRec( prj : String, version : String, l : List<{ project : String, version : String }> ) {
    var pdir = getRepository() + Os.safe(prj);
    if( !Os.exists(pdir) )
      throw "Project "+prj+" is not installed";
    var version = if( version != null ) version else neko.io.File.getContent(pdir+"/.current");
    var vdir = pdir + "/" + Os.safe(version);
    if( !neko.FileSystem.exists(vdir) )
      throw "Project "+prj+" version "+version+" is not installed";
    for( p in l )
      if( p.project == prj ) {
        if( p.version == version )
          return;
        throw "Project "+prj+" has two version included "+version+" and "+p.version;
      }
    l.add({ project : prj, version : version });
    /*
    var xml = neko.io.File.getContent(vdir+"/haxelib.xml");
    var inf = Datas.readData(xml);
    for( d in inf.dependencies )
      checkRec(d.project,if( d.version == "" ) null else d.version,l);
    */
  }

  
  public function
  path(projects:Array<{project:String,version:String}>) {

    var list = new List();
    for (p in projects) {
      checkRec(p.project,p.version,list);
    }
    
    var rep = getRepository();
    for( d in list) {
      var pdir = Os.safe(d.project)+"/"+Os.safe(d.version)+"/";
      var dir = rep + pdir;
      try {
        dir = Os.fileIn(rep+Os.safe(d.project)+"/.dev");
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
  doInstall(options:Options,repoUrl,prj,ver) {
    var
      localRep = getRepository(),
      pdir = localRep + Os.safe(prj);

    if (Os.exists(pdir + "/" + Os.safe(ver))) {
      Os.print("You already have "+prj+" version "+ver+" installed");
      setCurrentVersion(pdir,ver);
      return true;
    }
         
    var
      fileName = Os.pkgName(prj,ver),
      filePath = localRep + fileName;

    download(repoUrl,filePath,fileName);
    return true;
  }

  static function
  download(repoUrl:String,filePath:String,fileName:String) {
    trace("http://"+repoUrl+"/"+RemoteRepos.REPO_URI+"/"+fileName);
    var
      h = new haxe.Http("http://"+repoUrl+"/"+RemoteRepos.REPO_URI+"/"+fileName),
      out = neko.io.File.write(filePath,true),
      dlFinished = function() {
      	unpack(filePath,fileName);
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

  static function
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
      glbs = conf.globals();
    
    // create directories
    var pdir = getRepos() + Os.safe(glbs.name);
    Os.safeDir(pdir);
    pdir += "/";
    var target = pdir + Os.safe(glbs.version);
    Os.safeDir(target);
    target += "/";

    Os.unzip(zip,target);

    setCurrentVersion(pdir,glbs.version);

    Os.rm(filePath);

  }
    
  public function
  config(options:Options){
	Os.print(getRepository());
  }

  public function
  dev(prj:String,dir:String) {
	var
      rep = getRepository(),
      devfile = rep + Os.safe(prj)+"/.dev";
    
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
  setCurrentVersion(pdir:String,version:String) {
    var cd = pdir + ".current";
    if (!Os.exists(pdir)) throw "setCurrentVersion: "+pdir+" does not exist";
    Os.fileOut(cd,version);
    Os.print("  Current version is now "+version);
  }
  
  public function
  set(prj:String,version:String){
    var
      pdir = getRepository() + Os.safe(prj),
      vdir = pdir + "/" + Os.safe(version);

    if( !Os.exists(vdir) )
      throw "Project "+prj+" version "+version+" is not installed";

    var current = pdir+"/.current";
    if(Os.fileIn(current) == version ) {
      Os.print("Version is "+version);
      return;
    }

    setCurrentVersion(pdir,version);
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

      Os.fileOut(getConfigFile(),path) ;  // original has binary true - check!!
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