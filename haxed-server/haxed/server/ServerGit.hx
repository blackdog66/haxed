package haxed.server;

import bdog.Os;
import bdog.Git;
import haxed.Common;
import haxed.License;

using StringTools;
using Lambda;

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

typedef ProjectTags = {
  var prj:String;
  var val:String;
};


class ServerGit implements ServerStore {
  
  static var TMP_DIR = Os.separator + Os.slash("tmp");
  var repoTop:String;
  var fileDir:String;
  static var rePrj = ~/^__|\./;
  static var reTags = ~/tags:\s+(.+)$/;
  
  public function new(dd) {
    repoTop = Os.slash(dd);
    fileDir = repoTop+"__files__";
    if (!Os.exists(fileDir))
      Os.mkdir(fileDir);
  }

  public function
  cleanup() {} 

  inline function
  projectDir(p:String) {
    return Os.slash(repoTop + p);
  }

  inline function
  getConfig(p:String) {
    return new ConfigJson(Os.fileIn(projectDir(p)+Common.CONFIG_FILE));
  }
  
  function
  prjNames() {
    return Lambda.filter(Os.dir(repoTop),function(f) {
        return ! rePrj.match(f);
      });
  }

  inline function
  ggit(p:String) {
    return new Git(projectDir(p));
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
      email = glbs.authorEmail,    
      lc = checkLicense(glbs.license);

    if (lc != null)
      return lc;

    var
      haxedName =  glbs.name,
      haxedConf = ZipReader.content(tmpFile,haxedName),
      version = glbs.version,
      pkgName = Common.pkgName(glbs.name,version),
      git = ggit(haxedName);
    
    var newZip = git.dir+"__tmp__.zip";

    Os.mv(tmpFile,newZip);

    git.inRepo(function() {
        ZipReader.unzip(newZip);
        Os.rm(newZip);
      });
    
    git.commit(glbs.comments);
    git.tag(version);
    git.archive(pkgName,fileDir,version);
    
    return OK_SUBMIT;
  }

  function
  checkLicense(lic:String):Status {
    var
      licenses= License.getAll(),
      l = Lambda.filter(licenses,function(el) {
        return Reflect.field(el,"name").toUpperCase() == lic.toUpperCase();
      });

    if (l.first() == null) return ERR_LICENSE({licenses:licenses,given:lic});
    return null;
  }

  function
  keySearch(k:String):List<ProjectTags> {
    var find = "find "+repoTop+" -maxdepth 2 -name *haxed -exec grep -H "+k+" {} \\;";
    return
      Os.process(find)
      .split("\n")
      .map(function(l) {
          var re = new EReg("^(\\S+)\\s*"+k+"\\s*(\\S.*)$","");
          if (re.match(l))
            return {
            	prj:Os.path(re.matched(1),NAME),
                val:re.matched(2).trim()
            };
          return null;
        })
      .filter(function(el) { return el != null ; });
  }

  public static function
  countBy<T>(recs:Iterable<T>):Hash<Int> {
    var h = new Hash<Int>();    
    for (r in recs) {
      var f = Std.string(r);
      if (!h.exists(f))
        h.set(f,1);
      else {
        var c = h.get(f);
        h.set(f,c++);
      }
    }
    return h;
  }

  public static function
  unique<T>(recs:Iterable<T>):List<String> {
    var l = new List<String>();
    for (k in countBy(recs).keys())
      l.add(k);
    return l;
  }
  
  function
  mappableHash<T>(h:Hash<T>):List<{k:String,v:T}> {
    var l = new List<{k:String,v:T}>();
    for(i in h.keys()) {
      l.add({k:i,v:h.get(i)});
    }
    return l;
  }

  function
  getProjectInfo(prjNames:List<String>) {
    var me = this;
    return
      prjNames.map(function(p) {
        return me.getInfo(me.getConfig(p));
        });
  }
  
  function
  findTags():Array<String> {
    return
      keySearch("tags:")
      .fold(function(a:ProjectTags,b:Array<String>) {
          for (i in a.val.split(" "))
            if (i.trim() != "")
              b.push(i);
          return b; 
        },new Array<String>());
  }

  function
  findProjectsByTag(tag:String):List<String> {
    return
      keySearch("tags:")
      .map(function(el) { return { prj:el.prj,tags:el.val.split(" ") }; })
      .filter(function(el) {
          return el.tags.exists(function(e) { return e == tag; }) ; })
      .map(function(el) { return el.prj; });
  }

  function findProjectsByFld(f:String,v:String) {
    var prjNames = 
      keySearch(f+":")
      .filter(function(el) {
          return el.val.indexOf(v) != -1;
        })
      .map(function(el) {
          return el.prj;
        });
    return unique(prjNames);
  }
  
  public function
  topTags(n:Int):Status {
    return OK_TOPTAGS({tags:mappableHash(countBy(findTags())).map(function(el) {
        return { count:el.v, tag:el.k };
          }).array()});
  }

  public function
  info(p:String,options:Options):Status {
    var pd = projectDir(p);
    
    if(!Os.exists(pd))
      return ERR_PROJECTNOTFOUND;

    return OK_PROJECT(getInfo(getConfig(pd)));   
  }

  function getTags(t:Array<String>) {
    return
      if (t != null)
        t.map(function(t) { return {tag : t }; }).array()
        else
          [{tag:null}];
  }
  
  public function
  getInfo(p:Project):ProjectInfo {
    var
      g = p.globals(),
      versions = getVersions(g.name);

    return {
     	name: g.name,
        desc:g.description ,
      	website:g.website,
      	owner: g.author,
      	license:g.license,
        curversion:ggit(g.name).describe(),
        tags:getTags(g.tags),
        versions:versions
      };    
  }

  function getVersions(p:String):Array<VersionInfo> {
    return ggit(p).log().map(function(le) {
        return {
        	date: le.date,

            name:le.author,
            comments:le.comment,
            commit:le.commit,
            version:le.version
         };
      }).array();
  }
  
  public function
  search(query:String,opts:Options):Status {
    var found ;
    
    if (opts.getSwitch("-St") != null) {
      return OK_PROJECTS(getProjectInfo(findProjectsByTag(query)).array());
    }

    var fld = opts.getSwitch("-Sf");
    if (fld != null) {
      return OK_PROJECTS(getProjectInfo(findProjectsByFld(fld,query)).array());
    }
    
    return ERR_PROJECTNOTFOUND;
  }

  public function license():Status {
    return OK_LICENSES(License.getAll());
  }

  // user management ...
  
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

  public function
  account(cemail:String,cpass:String,nemail:String,npass:String,
          nName:String):Status {
    
    return OK_ACCOUNT;
  }

  public function
  projects(options) {
    var me = this ;
    return OK_PROJECTS(getProjectInfo(prjNames()).array());
  }

  public function
  reminder(email:String) {
    return OK_REMINDER;
  }
}
