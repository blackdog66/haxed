
package bdog;

#if php
import php.Sys;
import php.FileSystem;
import php.io.File;
import php.io.Path;
import php.Lib;
import php.io.Process;
import bdog.JSON;
#elseif neko
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import neko.io.Process;
import neko.io.Path;
import neko.Lib;
import bdog.JSON;
#elseif nodejs
// this has to be used with the bdog-stdjs project
import js.Sys;
import js.FileSystem;
import js.io.File;
import js.Lib;
import js.Node;
#end

using StringTools;

enum Answer {
  Yes;
  No;
  Always;
}

enum PathPart {
  EXT;
  NAME;
  FILE;
  DIR;
  PARENT;
}

class Os  {

  public static function
  template(s:String,ctx:Dynamic) {
    var tmpl = new haxe.Template(s) ;
    return tmpl.execute(ctx);
  }


#if (js && !nodejs)
  // any javascript not associated with node ...

#else

  // any server platform
  
  public static var separator:String;

  public static inline function
  print(s:String) {
    Lib.print(s);
  }

  public static inline function
  println(s:String) {
    Lib.println(s);
  }
  
  // File system tools ...
  
  public static function __init__() {
	#if (neko || php || nodejs)
    separator = (Sys.systemName() == "Windows" ) ? "\\" : "/";
    #else
    separator = "\\";
    #end
  }

  public static inline function
  slash(d:String) {
    return StringTools.endsWith(d,separator) ? d : (d + separator) ;
  }
      
  public static function
  safeDir(dir:String) {
    if(FileSystem.exists(dir) ) {
     if(!FileSystem.isDirectory(dir) )
        throw ("A file is preventing "+dir+" to be created");
      return false;
    }
    try {
      FileSystem.createDirectory(dir);
    } catch( e : Dynamic ) {
      throw "You don't have enough user rights to create the directory "+dir;
    }
    return true;
  }

  public static function
  newer(src:String,dst:String) {
    if (!exists(dst)) return true;
    var
      s = FileSystem.stat(src),
      d = FileSystem.stat(dst);
    return (s.mtime.getTime() > d.mtime.getTime()) ;
  }
  
  public static function
  mkdir(path:String) {
    if (FileSystem.exists(path)) return;

    #if php
    untyped __php__('@mkdir($path, 0777,true);');
    #else
    
    var
      p = path.split(separator),
      cur = p.splice(0,2),
      mydir = null;
    
    try	{
      while(true) {
        mydir = cur.join(separator) + separator;
        if (!FileSystem.exists(mydir))
          FileSystem.createDirectory(mydir);
        if (p.length == 0) break;
        cur.push(p.shift());
      }
    } catch(exc:Dynamic) {
      trace(exc);
      trace("MKDIR: problem with:"+mydir);
    }
    #end
  }

  public static inline function
  rm(f:String) {
    FileSystem.deleteFile(f);
  } 

  public static function
  cp(src,dst,ifNewer=false) {
    if (ifNewer && ! newer(src,dst)) return;
    File.copy(src,dst) ;
  }
  
  public static function
  rmdir(dir) {
    for( p in FileSystem.readDirectory(dir) ) {
      var path = slash(dir)+p;
      if( FileSystem.isDirectory(path) )
        rmdir(path);
      else
        rm(path);
    }
    FileSystem.deleteDirectory(dir);
  }

  public static inline function
  mv(file:String,dst:String) {
    try {
      FileSystem.rename(file,dst);
    } catch(ex:Dynamic) {
      trace("error copying "+file+" to "+dst);
      throw ex;
    }
  }

  public static function
  read(file:String,?ctx:Dynamic) {
    var contents ;
    contents = File.getContent(file);
    return (ctx != null)
      ? template(contents,ctx)
      : contents;
  }

  public static function
  write(file:String,s:String,?ctx:Dynamic) {
    var f = File.write(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }

  public static function
  append(file:String,s:String,?ctx:Dynamic) {
    var f = File.append(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }
  
  public static function
  path(dir:String,part:PathPart) {
#if !nodejs
    var p = new Path(dir);
    return switch(part) {
    case EXT: p.ext;
    case NAME: p.file;
    case DIR: p.dir;
    case FILE: p.file + "." + p.ext;
    case PARENT: path(p.dir,DIR);
    }
#else
    var p = Node.path;
    return switch(part) {
    case EXT: p.extname(dir);
    case FILE: p.basename(dir);
    case DIR: p.dirname(dir);
    case NAME: p.basename(dir,p.extname(dir));
    case PARENT: path(p.dirname(dir),DIR);
    }
#end
  }
  
  public static function
  cd(path:String) {
    Sys.setCwd(path);
  }

  public static inline function
  cwd() {
    return Sys.getCwd();
  }

  public static inline function
  exists(f:String) {
    return FileSystem.exists(f);
  }

  public static inline function
  dir(d:String) {
    return FileSystem.readDirectory(d);
  }

  public static function
  isDir(d:String) {
    if (!exists(d)) return false;
    return FileSystem.isDirectory(d);
  }
  
  private static function
  readTree(dir:String,files:List<String>,?exclude:String->Bool) {
    var dirContent = null;

    if (!FileSystem.isDirectory(dir)) throw dir + " is not a directory";
    
    try {
     dirContent = FileSystem.readDirectory(dir);
    }catch(ex:Dynamic) {
      trace("Exception reading directory "+dir);
    }
    
    if (dirContent == null) new List() ;
      
    for (f in dirContent) {
      if (exclude != null) {
        if (exclude(f)) {
          #if debug
          trace("excluding:"+slash(dir)+f);
          #end
          continue;
        }
      }
      var d = slash(dir) + f;
      try {
        if (FileSystem.isDirectory(d))
          readTree(d,files,exclude);
        else
          files.push(d);
      } catch(e:Dynamic) {
        // it's probably a link, isDirectory throws on a link
        //files.push(d);
        #if debug
        trace("ok got a link "+d);
        #end
        readTree(d,files,exclude);
      }
    }
    return files;
  }

  public static function
  files(dir:String,?exclude:String->Bool) {
    return readTree(dir,new List<String>(),exclude);
  }
  
  public static function
  copyTree(src:String,dst:String,?exclude:String->Bool):Void {
    var
      stemLen = StringTools.endsWith(src,separator) ? src.length : path(src,DIR).length, 
      fls = files(src,exclude);
    
    Lambda.iter(fls,function(f) {
        var
          dFile = path(f,FILE),
          dDir = dst + path(f.substr(stemLen),DIR);
        mkdir(dDir);
        File.copy(f,slash(dDir) +dFile) ;        
      });
  }

  // Process tools ...

  public static function
  env(n:String) {
    return Sys.environment().get(n.trim());
  }
  
  public static function
  exit(c:Int) {
    #if !php
    Sys.exit(c);
    #end
  }

  public static inline
  function args(p:Int):String {
    return Sys.args()[p];
  }
  
  public static function
  process(command:String,throwOnError=true,?ctx:Dynamic,fn:String->Void) {    
#if (!nodejs)
    var
      a = ~/\s+/g.split((ctx != null) ? template(command,ctx) : command),
      cmd = a.shift().trim();
   
    if (a[a.length-1] == "") a.pop();
 
    var  p = new Process(cmd,a);

    if( p.exitCode() != 0) {
      if (throwOnError)
        throw p.stderr.readAll().toString();
      else
        fn(p.stderr.readAll().toString());
    } else {
      fn(p.stdout.readAll().toString());
    }
#else
    Node.exec(command,null,function(err,stdout,stderr) {
        if( err.code != 0) {
          if (throwOnError)
            throw stderr;
          else
            fn(stderr);
        }
        fn(stdout);
      });
#end
 }

  // for backwards compat
#if (neko || php) 
  public static function
  processSync(command:String,throwOnError=true,?ctx:Dynamic) {
    var
      a = ~/\s+/g.split((ctx != null) ? template(command,ctx) : command),
      cmd = a.shift().trim();
    
    var  p = new Process(cmd,a);

    if( p.exitCode() != 0) {
      if (throwOnError)
        throw p.stderr.readAll().toString();
      else
        return p.stderr.readAll().toString();
    } else {
      return p.stdout.readAll().toString();
    }
 }
#end
  
  public static function
  command(command:String,?ctx:Dynamic,fn:Int->Void) {
    var
      a = ~/\s+/g.split((ctx != null) ? template(command,ctx) : command),
      cmd = a.shift().trim();
    
#if !nodejs
    var s = Sys.command(cmd,a);
    fn(s);
#else
    Node.exec(cmd,null,function(err,stdout,stderr) {
        if (err == null)
          fn(0);
        else
          fn(err.code);
      });
#end
  }
  
  public static function
  log(msg,f="log.log") {
    if (!exists(f)) write(f,"date:"+Date.now().toString());
    append(f,msg+"\n");
  }

  #if neko

  public static function
  ask( question,always=false ) {
    while( true ) {
      if(always)
        Os.print(question+" [y/n/a] ? ");
      else
        Os.print(question+" [y/n] ? ");

      var a = switch( neko.io.File.stdin().readLine() ) {
      case "n":  No;
      case "y":  Yes;
      case "a":  Always;
      }

      if (a == Always && !always) continue;
      if (a == Yes || a == No || a == Always) return a;
     
    }
    return null;
  }

  #end
    
#end
  
   // Other ...
  
  public static function
  escapeArgument( arg : String ) : String {    
    var ok = true;
    for( i in 0...arg.length )
      switch( arg.charCodeAt(i) ) {
      case 32, 34: // [space] 
        ok = false;
      case 0, 13, 10: // [eof] [cr] [lf]
        arg = arg.substr(0,i);
      }
    if( ok )
      return arg;
    return '"'+arg.split('"').join('\\"')+'"';
  }
  
}


