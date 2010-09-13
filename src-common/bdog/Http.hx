
package bdog;

using StringTools;

#if nodejs
import js.Node;
import bdog.nodejs.HttpClient;
#end


class Http {

  public static function
  parseUrl(url:String) {

    if (url.startsWith("http://"))
      url = url.substr(7);

    var
      colonAt = url.indexOf(":"),
      pathStarts = url.indexOf("/");

    return {
       host: url.substr(0,pathStarts),
       port: (colonAt == -1) ? 80 : Std.parseInt(url.substr(colonAt,pathStarts)),
       path: url.substr(pathStarts)
    }
    
  }
  
  public static function
  get(path:String,?params:Dynamic,fn:String->Void,?err:String->Void) {
#if nodejs
    var u = Node.url.parse(path);
    new HttpClient(u.hostname,Std.parseInt(u.port))
      .get(u.pathname,params)
      .then(fn);
#else
    var qs = "";
    if (params != null) {
      qs = "?";
      var sb = new StringBuf() ;
      for (f in Reflect.fields(params)) {
        sb.add(f + "=" + Reflect.field(params,f) + "&");
      }
      qs += sb.toString();
      qs = qs.substr(0,-1);
    }

    var h = new haxe.Http(path+qs);

	#if js
    h.async = true;
    #end
    
    h.onData = fn;

    if (err != null)
      h.onError = err;
    
    h.request(false);
    
#end
  }

/* http multipart upload */
  public static function
  filePost(filePath:String,dstUrl:String,binary:Bool,
		params:Dynamic,fn:String->Void) {

    #if neko
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

    #end
  }

}