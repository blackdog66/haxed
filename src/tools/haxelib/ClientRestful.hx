
package tools.haxelib;
import tools.haxelib.ClientCore;
import tools.haxelib.ClientCommands;

class ClientRestful extends ClientCore {

  var repos:Array<String>;
  
  public function new(repos:Array<String>) {
    super();
    this.repos = repos;
  }

  static function request(r:String,?prms:Dynamic,fn:Dynamic->Void){
    var parameters = "";
    if (prms != null) {
      var
        flds = Reflect.fields(prms),
        sb = new StringBuf();
      
      for (f in flds) {
        sb.add(f);
        sb.add("=");
        sb.add(StringTools.urlEncode(Reflect.field(prms,f)));
        sb.add("&");
      }
      parameters = sb.toString().substr(0,-1);
    }

    trace("request is "+r+"&"+parameters);
    var h = new haxe.Http(r+"&"+parameters);
    if (fn != null) {
      h.onData = function(d) {
        fn(hxjson2.JSON.decode(d));
      };
    }
    h.request(false);
  }
  
  function url(options:Options,c:String) {
    var r = options.repo ;
    return "http://"+r+"/index.php?method="+c;
  }
  
  public
  function install(options:Options,pkgName:String) {
    
  }

  public
  function
  submit(options:Options,password:String,packagePath:String,?fn:Dynamic->Void) {
    Os.filePost(packagePath,url(options,"submit"),true,{password:password},function(d) {
        fn(hxjson2.JSON.decode(d));
      }); 
  }

  public
  function search(options:Options,query:String) {
  }
  
  public
  function upgrade(options:Options) {
  }

  public
  function user(options:Options,email:String,?fn:Dynamic->Void) {
    var u = url(options,"user");
    request(u,{email:email},fn);
  }

  public
  function info(options:Options,prj:String,?fn:Dynamic->Void) {
    var u = url(options,"info");
    request(u,{prj:prj},fn);
  }

  public
  function register(options:Options,email:String,password:String,fullName:String,?fn:Dynamic->Void):Void {
    var u = url(options,"register");
    request(u,{email:email,password:password,fullname:fullName},fn);
  }

}