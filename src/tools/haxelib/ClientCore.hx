
package tools.haxelib;

import tools.haxelib.Package;

/*
  Implement all the local functions, remote operations are implemented by
  descendant.
*/

class ClientCore {

  static var REPNAME = "lib";
  
  public function new() { }


  static
  function getConfigFile() {
    var config = neko.Sys.getEnv("HOME")+"/.haxelib";
    if (Os.exists(config))
      return config;

    config = "/etc/.haxelib";
    if (Os.exists(config))
      return config;

    throw "config file not found";
    return null;
  }

  static
  function getRepoDir() {
    return try {
      Os.fileIn(getConfigFile());
    } catch( e : Dynamic ) {
      throw "This is the first time you are runing haxelib. Please run haxelib setup first";
    }
  }
  
  public static
  function getRepository() {
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

  public
  function list() {
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

  function deleteRec(dir) {
    for( p in neko.FileSystem.readDirectory(dir) ) {
      var path = dir+"/"+p;
      if( neko.FileSystem.isDirectory(path) )
        deleteRec(path);
      else
        Os.rm(path);
    }
    neko.FileSystem.deleteDirectory(dir);
  }
  
  public
  function remove(prj:String,version:String) {
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

  function checkRec( prj : String, version : String, l : List<{ project : String, version : String }> ) {
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

  
  public
  function path(projects:Array<{project:String,version:String}>) {

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

  public
  function config(){
	Os.print(getRepository());
  }

  public
  function dev(prj:String,dir:String) {
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

  public
  function set(prj:String,version:String){
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

    Os.fileOut(current,version);
    // var f = neko.io.File.write(current,true); ?? why is this binary??
    Os.print("Project "+prj+" current version is now "+version);
  }
  
  public
  function setup(path){
      if( !Os.exists(path) ) {
        try {
          Os.mkdir(path);
        } catch( e : Dynamic ) {
          Os.print("Failed to create directory '"+path+"' ("+Std.string(e)+"), maybe you need appropriate user rights");
          neko.Sys.exit(1);
        }
      }

      Os.fileOut(getConfigFile(),path) ;  // original has binary true - check!!
  }

  public
  function run() {

  }

  public
  function test() {

  }

  public
  function packit(hblFile:String) {
    Package.createFrom(hblFile);
  }
}