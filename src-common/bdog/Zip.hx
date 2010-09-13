package bdog;

import bdog.Os;

#if neko
import neko.zip.Reader;
#end

class Zip {

    public static function
  zip(fn:String,files:List<String>,root:String) {
#if neko
    var
      zf = neko.io.File.write(fn,true),
      rootLen = root.length;

    try {
      var fl = new List<{fileTime : Date, fileName : String, data : haxe.io.Bytes}>();
      for (f in files) {
        if (f == "." || f == "..") continue;
        var dt = neko.FileSystem.stat(f);
        fl.push({fileTime:dt.mtime,fileName:f.substr(rootLen),data:neko.io.File.getBytes(f)});
      }
      neko.zip.Writer.writeZip(zf,fl,1);
    } catch(exc:Dynamic) {
      trace("zip: problem "+exc) ;
    }
    zf.close();
#end
  }

#if neko
  public static function
  readFromZip(zip : List<ZipEntry>, file:String ) {
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
      if( n.charAt(0) == Os.separator || n.charAt(0) == "\\" || n.split("..").length > 1 )
        throw "Invalid filename : "+n;
      var
        dirs = ~/[\/\\]/g.split(n),
        path = "",
        file = dirs.pop();

      for( d in dirs ) {
        path += d;
        Os.safeDir(destination+path);
        path += Os.separator;
      }

      if( file == "" ) {
        if( path != "" ) Os.println("  Created "+path);
        continue; // was just a directory
      }

      path += file;
      Os.println("  Install "+path);
      var data = neko.zip.Reader.unzip(zipfile);
      var f = neko.io.File.write(destination+path,true);
      f.write(data);
      f.close();
    }
  }
#end
}