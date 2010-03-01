package haxed;

import bdog.Os;
import bdog.Git;
import haxed.Common;

#if php
import php.io.File;
import php.Web;
import php.Lib;
#elseif neko
import neko.io.File;
import neko.Web;
import neko.Lib;
#end

typedef Project = Config;


class ServerGit implements ServerStore {
  
  static var TMP_DIR = Os.separator + Os.slash("tmp");
  var repoTop:String;
  
  public function new(dd) {
    repoTop = dd;
  }

  public function
  cleanup() {
  } 

  function projectDir(p:String) {
    return Os.slash(repoTop + p);
  }
  
  public function
  submit(password:String):Status {
    var
      file = null,
	  sid = null,
      bytes = 0;
    
    Web.parseMultipart(function(p,filename) {
        if( p == "file" ) {
          sid = filename;
          file = File.write(TMP_DIR+filename+".tmp",true);
        } else
          throw p+" not accepted";
      },function(data,pos,len) {
        bytes += len;
        file.writeFullBytes(haxe.io.Bytes.ofString(data),pos,len);
      });
    if( file != null ) {
      file.close();
      return processUploaded(password,sid);
    }
    return ERR_UNKNOWN;
  }

  private function
  processUploaded(password:String,fileName:String):Status {
    var
      tmpFile = TMP_DIR + fileName + ".tmp",
      json = ZipReader.content(tmpFile,Common.CONFIG_FILE) ;
    
    if (json == null)
      return ERR_HAXELIBJSON;
        
    var
      conf = new ConfigJson(json),
      glbs = conf.globals(),
      email = glbs.authorEmail;
    
    var lc = checkLicense(glbs.license);
    if (lc != null)
      return lc;

    var
      haxedName =  glbs.name,
      haxedConf = ZipReader.content(tmpFile,haxedName),
      pkgName = Common.pkgName(glbs.name,glbs.version),
      git = new Git(projectDir(haxedName));
    
    var newZip = git.dir+"tmp.zip";

    Os.mv(tmpFile,newZip);

    git.inRepo(function() {
        ZipReader.unzip(newZip);
        Os.rm(newZip);
      });
    
        
    git.commit(glbs.comments);
    //Git.tag(Common.pkgName(glbs.name,glbs.version));
    
    return OK_SUBMIT;
  }
  
  public function
  register(email:String,pass:String,fullName:String):Status {
    if (user(email) != ERR_UNKNOWN)
      return ERR_REGISTERED;

    return OK_REGISTER;
  }

  public function
  user(email:String):Status {
    return OK_USER({
        fullname : "blah",
        email : "blach",
        projects : null
    });
  }

  function checkLicense(lic:String):Status {
    var
      licenses= License.getAll(),
      l = Lambda.filter(licenses,function(el) {
        return Reflect.field(el,"name").toUpperCase() == lic.toUpperCase();
      });

    if (l.first() == null) return ERR_LICENSE({licenses:licenses,given:lic});
    return null;
  }
                                    
  public function
  topTags(n:Int):Status {
    return OK_TOPTAGS({tags: null });
  }

  static function
  getInfo(p:Project):ProjectInfo {
    var g = p.globals();
     return {
     	name: g.name,
        desc:g.description ,
      	website:g.website,
      	owner: g.authorName,
      	license:g.license,
        curversion:g.version,
         tags:[{tag:"dummy"}],
         versions:null
      };    
  }

  static function getVersions(p:Project) {
        
  }
  
  public function
  info(p:String):Status {
    var pd = projectDir(p);
    if(!Os.exists(pd))
      return ERR_PROJECTNOTFOUND;
   
    return OK_PROJECT(getInfo(new ConfigJson(Os.fileIn(pd+Common.CONFIG_FILE))));   
  }

  public function
  search(query:String,opts:Options):Status {
    var found ;

     return ERR_PROJECTNOTFOUND;
  }

  public function license():Status {
    return OK_LICENSES(License.getAll());
  }
  
  public function
  account(cemail:String,cpass:String,nemail:String,npass:String,
          nName:String):Status {

    
    return OK_ACCOUNT;
  }

  public function
  projects(options) {
    
    return OK_PROJECTS(null);
  }

  public function
  reminder(email:String) {
    return OK_REMINDER;
  }
}