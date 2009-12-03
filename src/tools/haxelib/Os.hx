
package tools.haxelib;

#if php
import php.FileSystem;
import php.io.File;
import php.io.Path;
import php.Lib;
#elseif neko
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;
import neko.zip.Reader;
#end

class Os {
  static var alphanum = ~/^[A-Za-z0-9_.-]+$/;

  public static
  function print(s:String) {
    Lib.println(s);
  }


  public static inline
  function slash(d:String) {
    return StringTools.endsWith(d,"/") ? d : (d + "/") ;
  }

  public static
  function safe( name : String ) {
    if( !alphanum.match(name) )
      throw "Invalid parameter : "+name;
    return name.split(".").join(",");
  }

  public static
  function unsafe( name : String ) {
    return name.split(",").join(".");
  }

  public static
  function pkgName( lib : String, ver : String ) {
      return safe(lib)+"-"+safe(ver)+".zip";
  }

  public static
  function safeDir( dir ) {
    if( FileSystem.exists(dir) ) {
     if( !FileSystem.isDirectory(dir) )
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

  
  public static
  function newer(src:String,dst:String) {
    if (!exists(dst)) return true;
    var s = FileSystem.stat(src),
      d = FileSystem.stat(dst);
    return (s.mtime.getTime() > d.mtime.getTime()) ;
  }

  public static
  function mkdir(path:String) {
    if (FileSystem.exists(path)) return;
    
    var p = path.split("/");
    var cur = p.splice(0,2);
    try	{
      while(true) {
        var dir = cur.join("/");
        if (!FileSystem.exists(dir))
          FileSystem.createDirectory(dir);
        if (p.length == 0) break;
        cur.push(p.shift());
      }
    } catch(exc:Dynamic) {
      trace("mkdir: problem with:"+path);
    }
  }

  public static
  function rm(f:String) {
    FileSystem.deleteFile(f);
  } 

  public static function
  rmdir(dir) {
    for( p in FileSystem.readDirectory(dir) ) {
      var path = dir+"/"+p;
      if( FileSystem.isDirectory(path) )
        rmdir(path);
      else
        Os.rm(path);
    }
    FileSystem.deleteDirectory(dir);
  }

  public static
  function mv(file:String,dst:String) {
    FileSystem.rename(file,dst);
  }
  
  public static
  function fileOut(file:String,s:String,?ctx:Dynamic) {
    var f = File.write(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }

  public static
  function fileAppend(file:String,s:String,?ctx:Dynamic) {
    var f = File.append(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }

  public static
  function fileIn(file:String,?ctx:Dynamic) {
    var contents ;
    contents = File.getContent(file);
    return (ctx != null)
      ? template(contents,ctx)
      : contents;
  }
  
  public static
  function template(s:String,ctx:Dynamic) {
    var tmpl = new haxe.Template(s) ;
    return tmpl.execute(ctx);
  }

  public static
  function exists(f:String) {
    return FileSystem.exists(f);
  }

  public static
  function dir(d:String) {
    return FileSystem.readDirectory(d);
  }
  
  private static
  function readTree(dir:String,files:List<String>,?exclude:String->Bool) {
    var dirContent = FileSystem.readDirectory(dir);
    for (f in dirContent) {
      var d = slash(dir) + f;
      if (exclude != null)
        if (exclude(d)) continue;
      try {
        if (FileSystem.isDirectory(d))
          readTree(d,files);
        else
          files.push(slash(dir)+f);
      } catch(e:Dynamic) {
        // it's probably a link, isDirectory throws on a link
        files.push(slash(dir)+f);
      }
    }
    return files;
  }

  public static
  function files(dir:String,?exclude:String->Bool) {
    return readTree(dir,new List<String>(),exclude);
  }
  
  public static
  function copyTree(src:String,dst:String):Void {    
    var stemLen = StringTools.endsWith(src,"/") ? src.length 
      :Path.directory(src).length,
                        
    files = Os.files(src);
    Lambda.iter(files,function(f) {
        var
          dFile = Path.withoutDirectory(f),
          dDir = dst + Path.directory(f.substr(stemLen));
        Os.mkdir(dDir);
        File.copy(f,dDir + "/"+dFile) ;        
      });
  }

  #if neko
  public static
  function zip(fn:String,files:List<String>,root:String) {
    var
      zf = neko.io.File.write(fn,true),
      rootLen = root.length;

    try {
      var fl = new List<{fileTime : Date, fileName : String, data : haxe.io.Bytes}>();
      for (f in files) {
        if (f == "." || f == "..") continue;
        if (f.indexOf(".git") != -1) continue ;
        var dt = FileSystem.stat(f);
        fl.push({fileTime:dt.mtime,fileName:f.substr(rootLen),data:neko.io.File.getBytes(f)});
      }
      neko.zip.Writer.writeZip(zf,fl,1);
    } catch(exc:Dynamic) {
      trace("zip: problem "+exc) ;
    }
    zf.close();
  }

  public static function
  readFromZip( zip : List<ZipEntry>, file:String ) {
    for( entry in zip ) {
      if(entry.fileName == file) {
        return Reader.unzip(entry).toString();
      }
    }
    return null;
  }

  public static function
  unzip(zip:List<ZipEntry>,destination:String) {
    for( zipfile in zip ) {
      var n = zipfile.fileName;
      if( n.charAt(0) == "/" || n.charAt(0) == "\\" || n.split("..").length > 1 )
        throw "Invalid filename : "+n;
      var
        dirs = ~/[\/\\]/g.split(n),
        path = "",
        file = dirs.pop();

      for( d in dirs ) {
        path += d;
        Os.safeDir(destination+path);
        path += "/";
      }

      if( file == "" ) {
        if( path != "" ) print("  Created "+path);
        continue; // was just a directory
      }

      path += file;
      print("  Install "+path);
      var data = neko.zip.Reader.unzip(zipfile);
      var f = neko.io.File.write(destination+path,true);
      f.write(data);
      f.close();
    }
  }
  
  /* http multipart upload */
  public static
	function filePost(filePath:String,dstUrl:String,binary:Bool,
		params:Dynamic,fn:String->Void) {

		if (!neko.FileSystem.exists(filePath))
			throw "file not found";

		trace("filePost: "+filePath+" to "+dstUrl);
		var req = new haxe.Http(dstUrl);

		var path = new neko.io.Path(filePath);
		var stat = neko.FileSystem.stat(filePath);
		req.fileTransfert("file",path.file+"."+path.ext,
			neko.io.File.read(filePath,binary),stat.size);

		if (params != null) {
			var prms = Reflect.fields(params) ;
			for (p in prms)
				req.setParameter(p,Reflect.field(params,p));
		}

		req.onData = function(j:String) {
			if (fn != null)
				fn(j);
			else trace(j);
		}

		req.request(true);
	}

  #end

  public static function
  log(msg) {
    Os.fileAppend("haxelib.log",msg);
  }

}