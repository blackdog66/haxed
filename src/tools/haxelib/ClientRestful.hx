
package tools.haxelib;
import tools.haxelib.Common;
import tools.haxelib.ClientCommon;
import tools.haxelib.ClientCore;

class ClientRestful extends ClientCore, implements Client {

  public function new() {
    super();
    RemoteRepos.init(this);
  }

  public
  function url(u:String,c:String) {
    return "http://"+u+"/index.php?method="+c;
  }
  
  public
  function request(r:String,prms:Dynamic,fn:Dynamic->Void){
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

  static
  function getStatus(d):Status {
    var e;
    if (Reflect.field(d,"PAYLOAD"))
      e = Type.createEnum(Status,d.ERR,[d.PAYLOAD]);
    else
      e = Type.createEnum(Status,d.ERR);
    return e;
  }

  /*
    make one request to the given -R repo, or iterate over all repos
  */
  function requestDispatch(options:Options,cmd:String,prms:Dynamic,fn:Status->Bool) {
    if (options.repo != null) {
      request(url(options.repo,cmd),prms,function(d) {
          fn(getStatus(d)) ;
      });
    } else {
      RemoteRepos.each(cmd,prms,function(d:Dynamic) {
          return fn(getStatus(d)) ;
        });
    }
  }
  
  public
  function install(options:Options,prj:String,ver:String) {
    var me = this;
    info(options,prj,function(s:Status) {
        switch(s) {
        case OK_PROJECT(j):
          if (j.curversion == null)
            throw "The project has not yet released a version";

          var found = false;
          for( v in j.versions )
            if( v.name == ver ) {
              found = true;
              break;
            }
        
          if( !found )
			throw "No such version "+ver;

          var localRep = me.getRepository();

          if (Os.exists(localRep + Os.safe(prj) + "/" + Os.safe(ver))) {
            Os.print("You already have "+prj+" version "+ver+" installed");
            //setCurrent(project,version,true);
            return true;
          }
         
          var
            fileName = Os.pkgName(prj,ver),
            filePath = localRep + fileName;

          me.download(options,filePath,fileName);
          //    me.doInstall(j.name,ver,ver == j.curversion);
        default:
        }
        return true;
      });
  }

  public
  function
  submit(options:Options,password:String,packagePath:String,?fn:Dynamic->Void) {
    Os.filePost(packagePath,url(options.repo,"submit"),true,{password:password},function(d) {
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
  function user(options:Options,email:String,fn:Status->Bool) {
    requestDispatch(options,"user",{email:email},fn);
  }

  public
  function info(options:Options,prj:String,fn:Status->Bool) {
    requestDispatch(options,"info",{prj:prj},fn);
  }

  public
  function register(options:Options,email:String,password:String,fullName:String,fn:Status->Bool):Void {
    var prms = {email:email,password:password,fullname:fullName};
    requestDispatch(options,"register",prms,fn);
  }

}


