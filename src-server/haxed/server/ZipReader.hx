
package haxed.server;

import bdog.Os;

class ZipReader {

  public static function
  open(s:String):Dynamic {
    return untyped __call__('zip_open',s);
  }
  
  public static function
  readZip( z : Dynamic ) : Dynamic {
    var r:Dynamic = untyped __call__('zip_read',z);
    if (r == false)
      return null
    else
      return r; 
  }

  public static function
  entryName(e:Dynamic):String {
    return untyped __call__('zip_entry_name',e);
  }

  public static function
  readZipEntry( e : Dynamic ) : Dynamic  {
    var l = untyped __call__('zip_entry_filesize',e);
    return untyped __call__('zip_entry_read',e,l);
  }

  public static function
  unzip(zf:String):String {
    var
      z = open(zf),
      c = null,
      e;
    do {
      e = readZip(z);
      if (e != null) {
        c = readZipEntry(e);
        var en = entryName(e);
        Os.mkdir(php.io.Path.directory(en));
        Os.fileOut(en,c);
      }
    } while (e != null);
      
    return c;
  }


  public static function
  content(zf:String,fn:String) {
    var
      z = open(zf),
      c = null,
      e;
    do {
      e = readZip(z);
      if (e != null && entryName(e) == fn) {
        c = readZipEntry(e);
        break;
      }
    } while (e != null);
      
    return c;
  }
}
