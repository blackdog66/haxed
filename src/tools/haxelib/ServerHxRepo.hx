
package tools.haxelib;

import tools.haxelib.ServerData;
import tools.haxelib.ServerModel;
import tools.haxelib.ZipReader;
import tools.haxelib.Config;

#if php
import php.io.File;
import php.Web;
import php.Lib;
#elseif neko
import neko.io.File;
import neko.Web;
import neko.Lib;
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
    
    var db = php.db.Sqlite.open(dataDir + DB);
    php.db.Manager.cnx = db;
	php.db.Manager.initialize();
  }

  public
  function cleanup() {
    try {
    php.db.Manager.cnx.close();
    php.db.Manager.cnx = null;
    } catch(exc:Dynamic) {
      trace("problem closing db");
    }
  } 

  public
  function submit() {
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
      Lib.print("File # accepted : "+bytes+" bytes written");
      processUploaded(TMP_DIR+"/"+sid+".tmp");
      return;
    }
  
  }

  private
  function processUploaded(tmpFile:String) {
    // File.copy(TMP_DIR+"/"+sid+".tmp",repo + sid) ;        
    // Unzip to get the json descriptor
    
    var json = ZipReader.content(tmpFile,"haxelib.json"),
      conf;
    
    if (json != null)
      conf = new ConfigJson(json);
    else
      throw "need a haxelib.json config";

    var glbs = conf.globals();
    
    trace("globals "+conf.globals());

    var u = user(glbs.authorEmail);
    if (u == null)
      throw "User "+glbs.authorEmail+" is not registered";

    
    
  }
  
  public 
  function register(email:String,pass:String,fullName:String):Dynamic {
 
    if (user(email) != null)
      return {ERR:1,ERRMSG:"user registered"};
    
    var u = new User();
    //u.name = name;
    u.pass = pass;
    u.email = email;
    u.fullname = fullName;
    u.insert();
    return {ERR:0};
  }

  public function checkPassword( email : String, pass : String ) : Bool {
    var u = User.manager.search({ email : email }).first();
    return u != null && u.pass == pass;
  }

  public function user(email:String):UserInfo {
    var u = User.manager.search({ email : email }).first();
    if( u == null )
      return null;
    var
      pl = Project.manager.search({ owner : u.id }),
      projects = new Array();

    for( p in pl )
      projects.push(p.name);

    return {
        fullname : u.fullname,
        email : u.email,
        projects : projects,
		};
  }
}