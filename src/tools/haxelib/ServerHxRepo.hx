
package tools.haxelib;

import tools.haxelib.Common;
import tools.haxelib.ServerData;
import tools.haxelib.ServerModel;
import tools.haxelib.ZipReader;
import tools.haxelib.Config;

#if php
import php.io.File;
import php.Web;
import php.Lib;
import php.db.Manager;
import php.db.Sqlite;
#elseif neko
import neko.io.File;
import neko.Web;
import neko.Lib;
import neko.db.Manager;
import neko.db.Sqlite;
#end

/*
  A haxe backend, either neko or php, to haxelib.
*/
class ServerHxRepo implements Repository {
  static var DB = "haxelib.db";
  
  var dataDir:String;
  var repo:String;
  
  public function new(dd) {
    dataDir = Os.slash(dd);
    if (Os.exists(dataDir)) {
      if (!Os.exists(dataDir + DB))
        throw "haxelib.db does not exist in data dir";

      repo = dataDir + "repo/";
      Os.mkdir(repo);
      
    }
    
    var db = Sqlite.open(dataDir + DB);
    Manager.cnx = db;
	Manager.initialize();
  }

  public
  function cleanup() {
    try {
      Manager.cnx.close();
      Manager.cnx = null;
    } catch(exc:Dynamic) {
      trace("problem closing db");
    }
  } 

  public
  function submit(password:String):Status {
    var
      TMP_DIR = "/tmp",
      file = null,
	  sid = null,
      bytes = 0;
    
    Web.parseMultipart(function(p,filename) {
        if( p == "file" ) {
          sid = filename;
          file = File.write(TMP_DIR+"/"+filename+".tmp",true);
        } else
          throw p+" not accepted";
      },function(data,pos,len) {
        bytes += len;
        file.writeFullBytes(haxe.io.Bytes.ofString(data),pos,len);
      });
    if( file != null ) {
      file.close();
      //Lib.print("File # accepted : "+bytes+" bytes written");
      return processUploaded(password,TMP_DIR+"/"+sid+".tmp");
    }
    return ERR_UNKNOWN;
  }

  private
  function processUploaded(password:String,tmpFile:String):Status {
    var
      json = ZipReader.content(tmpFile,"haxelib.json") ;
    
    if (json == null)
      return ERR_HAXELIBJSON;
        
    var
      conf = new ConfigJson(json),
      glbs = conf.globals(),
      email = glbs.authorEmail,  
      user = User.manager.search({ email : email }).first();
    
    if (user == null)
      return ERR_USER(email);

    if (user.pass != password)
      return ERR_PASSWORD;
    
    var prj = Project.manager.search({ name : glbs.name }).first();
    if (prj == null)
      prj = createProject(user,glbs) ;

    if(!developer(user,prj))
      return ERR_DEVELOPER;

    return OK;
  }
  
  public 
  function register(email:String,pass:String,fullName:String):Status {
    if (user(email) != ERR_UNKNOWN)
      return ERR_REGISTERED;

    var u = new User();
    u.pass = pass;
    u.email = email;
    u.fullname = fullName;
    u.insert();
    return OK;
  }

  public
  function user(email:String):Status {
    var u = User.manager.search({ email : email }).first();

    if( u == null )
      return ERR_UNKNOWN;

    var
      pl = Project.manager.search({ owner : u.id }),
      projects = new Array();

    for( p in pl )
      projects.push(p.name);

    return OK_USER({
        fullname : u.fullname,
        email : u.email,
        projects : projects
    });
  }

  function createProject(u:User,g:Global):Project {
    var p = new Project();

    p.name = g.name;
    p.description = g.description;
    p.website = g.projectUrl;
    p.license = g.license;
    p.owner = u;
    p.downloads = 0;
    p.insert();

    // TODO
    var devs = new List<User>();
    devs.push(u);
      
    for( u in devs ) {
      var d = new Developer();
      d.user = u;
      d.project = p;
      d.insert();
    }
      
    for( tag in g.tags ) {
      var t = new Tag();
      t.tag = tag;
      t.project = p;
      t.insert();
    }

    return p;
  }

  function developer(u:User,p:Project) {
    var
      pdevs = Developer.manager.search({ project : p.id }),
      isdev = false;

    for( d in pdevs ) {
      if( d.user.id == u.id ) {
        isdev = true;
        break;
      }
    }

    return isdev;
  }
  
}