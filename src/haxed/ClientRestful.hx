
package haxed;

import bdog.JSON;
import bdog.Os;
import haxed.Common;
import haxed.ClientCore;

class ClientRestful extends ClientCore {

  public function new() {
    super();
    RemoteRepos.init(this);
  }

  override public function
  url(u:String,c:String) {
    return "http://"+u+"/repo.php?method="+c;
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
        fn(JSON.decode(d));
      };
    }
    h.onError = function(e:String) {
      Os.print("Error requesting "+ r + "&" + parameters);
      Os.print("Server not available? Checking next repo ...");
      fn(null);
    };
    
    h.request(false);
  }


  /*
    make one request to the given -R repo, or iterate over all repos
  */
  function
  requestDispatch(options:Options,cmd:String,prms:Dynamic,fn:String->Status->Bool) {
    
    if (options.repo != null) {
      request(url(options.repo,cmd),prms,function(d) {
          options.removeSwitch("-R"); // don't want it passed to remote - this needs to be looked at
          if (d != null) {
            fn(options.repo,Marshall.fromJson(d)) ;
          }
            
      });
    } else {
      RemoteRepos.each(cmd,prms,function(repo:String,d:Dynamic) {
          if (d != null) {
            return fn(repo,Marshall.fromJson(d)) ;
          }
          return false ;// take next repo
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
            found = false;
            for( v in j.versions )
              if( v.name == ver ) {
                found = true;
                break;
              }
          } else
            ver = j.curversion;

          if (found) {
            me.doInstall(options,repoUrl,prj,ver,j.license);
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
        trace("submission return is --"+d+"--");
        var s = Marshall.fromJson(JSON.decode(d));
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
  public function
  projects(options:Options,fn:String->Status->Bool) {
    requestDispatch(options,"projects",{},fn);
  }

  public function
  serverInfo(options,fn:String->Status->Bool) {
    requestDispatch(options,"serverInfo",{},fn);
  }

  public function
  reminder(email:String,options:Options,fn:String->Status->Bool) {
    requestDispatch(options,"reminder",{email:email},fn);
  }

  public function
  topTags(nTags:Int,options:Options,fn:String->Status->Bool) {
    requestDispatch(options,"toptags",{ntags:nTags},fn);
  }
}


