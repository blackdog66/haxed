
package haxed;

import bdog.Os;
import haxed.Common;
import haxed.Parser;

class ClientTools {

  public static var REPNAME = "lib";
  public static var repositoryDir;

  public static function
  configuration(prj:String,?ver:String):Config {
    var
      v = (ver == null) ? currentVersion(prj) : ver,
      vd = versionDir(prj,v) ,
      haxedf =  vd + prj+".haxed";
    
    if (Os.exists(haxedf)) {
      return Parser.configuration(haxedf);
    }

    /*
    var haxelib = vd + "haxelib.xml";
    if (Os.exists(haxelib)) {
      Convert.toHaxed(haxelib,haxedf);
      neko.Lib.println("Warning: Creating new haxed.json file for old haxelib package");
      return new ConfigJson(Os.fileIn(haxedf));
    }

    */
    throw "neither " + haxedf + " or haxelib.xml exists!";

  }
  
  public static function
  getConfigFile(create=false) {
    var home = Os.env("HOME");
    if (home == null)
      home = Os.env("HOMEPATH");
    
    var config = Os.slash(home)+".haxelib";
    if (create || Os.exists(config)) {
      return config;
    }

    config = "/etc/.haxelib";
    if (Os.exists(config))
      return config;

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
        haxepath += Os.separator;
      var rep = haxepath+REPNAME;
      try {
        Os.safeDir(rep);
      } catch( e : Dynamic ) {
        throw "The directory defined by HAXEPATH does not exist, please run haxesetup.exe again";
      }
      return Os.slash(rep);
    }

    var rep = try {
      Os.read(getConfigFile());
    } catch( e : Dynamic ) {
      throw "This is the first time you are running haxed. Please run haxed setup first";
    }
      
    if( !Os.exists(rep) )
      throw "haxed Repository "+rep+" does not exists. Please run haxed setup again";

    repositoryDir = Os.slash(rep);
    return repositoryDir;
  }

  public static inline function
  getRepository() {
    return getRepos();
  }

  public static inline function
  projectDir(prj) {
    return Os.slash(getRepos() + Common.safe(prj));
  }

  public static function
  versionDir(prj,?ver) {
    if (ver == null) ver = currentVersion(prj);
    return Os.slash(projectDir(prj) + Common.safe(ver));
  }

  public static function
  currentVersion(prj) {
    try {
      return Os.read(projectDir(prj) + ".current");
    } catch(exc:Dynamic) {
      return null;
    }
  }

  public static function
  devVersion(prj) {
    try {
      return Os.read(projectDir(prj) + ".dev");
    } catch (exc:Dynamic) {
      return null;
    }
  }

  public static function
  checkRec( prj : String, version : String, l : List<PrjVer> ) {
    var pdir = projectDir(prj);
    if( !Os.exists(pdir) )
      throw "Dependancy "+prj+" is not installed";

    var version = ( version != null ) ? version : currentVersion(prj);
    var vdir = versionDir(prj,version);

    if(!Os.exists(vdir))
      throw "Project "+prj+" version "+version+" is not installed";

    for( p in l )
      if( p.prj == prj ) {
        if( p.ver == version )
          return;
        throw "Project "+prj+" has two version included "+version+" and "+p.ver;
      }

    l.add({ prj : prj, ver : version, op:null });

    for( d in configuration(prj).getDepends()) {
      checkRec(d.prj,( d.ver == "" ) ? null : d.ver,l);
    }
  }
  
  public static function
  internalPath(projects:Array<PrjVer>) {
    var out = new List();

    if (projects == null) return out;

    var list = new List();

    for (p in projects) {
      checkRec(p.prj,p.ver,list);
    }
    
    for( d in list) {
      var
        pdir = versionDir(d.prj,d.ver);
      
      try {
        var dir = devVersion(d.prj);

        if( dir.length == 0 ||
            (dir.charAt(dir.length-1) != '/' &&
             dir.charAt(dir.length-1) != '\\'))
          dir += Os.separator;
        
        pdir = dir;
      } catch( e : Dynamic ) {
      }
      
      var ndir = Os.slash(Os.slash(pdir) + "ndll");

      if(Os.exists(ndir) ) {
        var sysdir = Os.slash(ndir) + neko.Sys.systemName();
        if( !Os.exists(sysdir) )
          throw "Project "+d.prj+" version "+d.ver+" does not have a neko dll for your system";
        out.add("-L "+ndir);
      }
      
      out.add(pdir);
    }
    return out;
  }


}