
package tools.haxelib;
import tools.haxelib.Common;
import tools.haxelib.ClientCommon;
import tools.haxelib.ClientCore;

class ClientRestful extends ClientCore {

  public function new() {
    super();
    RemoteRepos.init(this);
  }

  override public function
  url(u:String,c:String) {
    return "http://"+u+"/index.php?method="+c;
  }
  
  override public function
  request(r:String,prms:Dynamic,fn:Dynamic->Void){
    var parameters = "";
    if (prms != null) {
      var
        flds = Reflect.fields(prms),
        sb = new StringBuf();
      
      for (f in flds) {
        var v = Reflect.field(prms,f);
        if (v == null) continue;
        sb.add(f);
        sb.add("=");
        sb.add(StringTools.urlEncode(v));
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

  static function
  getStatus(d:Dynamic):Status {
    var e;
    trace(d);
    if (Reflect.field(d,"PAYLOAD") != null)
      e = Type.createEnum(Status,d.ERR,[d.PAYLOAD]);
    else
      e = Type.createEnum(Status,d.ERR);
    return e;
  }

  /*
    make one request to the given -R repo, or iterate over all repos
  */
  function
  requestDispatch(options:Options,cmd:String,prms:Dynamic,fn:String->Status->Bool) {
    
    if (options.repo != null) {
      request(url(options.repo,cmd),prms,function(d) {
          fn(options.repo,getStatus(d)) ;
      });
    } else {
      RemoteRepos.each(cmd,prms,function(repo:String,d:Dynamic) {
          return fn(repo,getStatus(d)) ;
        });
    }
  }
  
  override public function
  install(options:Options,prj:String,ver:String) {
    var me = this;
    info(options,prj,function(repoUrl:String,s:Status) {
        return switch(s) {
        case OK_PROJECT(j):
          if (j.curversion == null)
            return false;

          var found = true;
          
          if (ver != null) {
            trace("given version is "+ver);
            found = false;
            for( v in j.versions )
              if( v.name == ver ) {
                found = true;
                break;
              }
          } else
            ver = j.curversion;

          if (found) {
            me.doInstall(options,repoUrl,prj,ver);
          }
          
          return found;

        default:
          false;
        }
      });
  }

  public function
  submit(options:Options,password:String,packagePath:String,fn:String->Status->Bool) {
    var u = url(options.repo,"submit");
    Os.filePost(packagePath,u,true,{password:password},function(d) {
        var s = getStatus(d);
        if (fn != null)
          fn(options.repo,s);
      }); 
  }

  public function
  search(options:Options,query:String,fn:String->Status->Bool) {
    var prms = options.addSwitches({query:query});
    requestDispatch(options,"search",prms,fn) ;
  }
  
  public function
  upgrade(options:Options) {
  }
  
  public function
  user(options:Options,email:String,fn:String->Status->Bool) {
    requestDispatch(options,"user",{email:email},fn);
  }
  

  public function
  info(options:Options,prj:String,fn:String->Status->Bool) {
    requestDispatch(options,"info",{prj:prj},fn);
  }

  public function
  register(options:Options,email:String,password:String,fullName:String,
           fn:String->Status->Bool):Void {
    var prms = {email:email,password:password,fullname:fullName};
    requestDispatch(options,"register",prms,fn);
  }

  public function
  account(options:Options,cemail,cpass,nemail,npass,nname,fn:String->Status->Bool) {
    var prms = {cemail:cemail,cpass:cpass,nemail:nemail,npass:npass,nname:nname};
    requestDispatch(options,"account",prms,fn);
  }

  public function
  licenses(options:Options,fn:String->Status->Bool) {
    requestDispatch(options,"license",{},fn);
  }
}


