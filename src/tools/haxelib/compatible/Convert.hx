
import tools.haxelib.Common;
import tools.haxelib.Os;
import tools.haxelib.Package;
import tools.haxelib.Parser;
import tools.haxelib.ClientRestful;
import tools.haxelib.compatible.Datas;


typedef OldUser = { pw:String,fn:String };

class Convert {

  public static
  function main() {
    
    var
      users = getUsers(),
      client = new ClientRestful(),
      tmpDir = "/tmp/unzip/",
      fs = Os.files("/home/blackdog/OLDHAXLIB"), // the haxelib zip directory
      nnull = 0,
      i = 0;

    for (f in fs) {
      Os.rmdir(tmpDir);
      Os.mkdir(tmpDir);
        
      var
        zf = neko.io.File.read(f,true),
        zip = neko.zip.Reader.readZip(zf);
        
      Os.unzip(zip,tmpDir);

      var
        xmlFile = find(tmpDir,["-name","haxelib.xml"])[0],
        xml = Os.fileIn(xmlFile),
        newPackage;
        
      if (xml == null) {
        trace("null in "+f);
        nnull++;
      }

      var
        data = Datas.readData(xml),
        dev = data.developers.first(),
        user = users.get(dev),
        o = new Options();

      o.addSwitch("-R","lib.ipowerhouse.com");
      
      client.register(o,dev + "@haxe.org",user.pw,user.fn,
                      function(rurl:String,s:Status) {
                        trace("registed "+dev+"@haxe.org");
                        return true;
                      });
      
      Os.fileOut(tmpDir+"/haxelib.json",toHpx(data));
      newPackage = packit(tmpDir+"/haxelib.json");
    
      zf.close();
    
      client.submit(o,"",newPackage,function(rurl:String,s:Status) {
          trace("submitted to "+rurl);
          trace("status "+s);
          return true;
        });
      
      if (i++ == 20) break;    
    }
      
    trace("nnull = "+nnull);
  }

  public static function
  getUsers():Hash<OldUser> {
    var
      sql = "select name,pass,fullname from user",
      rows = Os.shell('cat "'+sql+'" | sqlite3 haxelib.db').split("\n"),
      users = new Hash<OldUser>();

    for (r in rows) {
      var u = r.split("|");
      users.set(u[0],{pw:u[0],fn:u[1]});
    }
    
    return users;
  }
  
  public static function
  toHpx(x:XmlInfos) {
    var tmpl = '
name:			::project::
website:		::website::
version:		::version::
comments:		::versionComments::
description:	::desc::
author-email:	::email::
tags:			::foreach tags::::name::::end::
license:		::license::
author:			::foreach developers::::name::::end::
';
    return Os.template(tmpl,x);
    //build-depends: ::foreach dependencies::::project:: >= ::version:: ::end::

  }

	public static
	function find(root:String,?options:Array<String>):Array<String> {
		//var prms = [root,"-name",spec,"-type","f"];
		var prms = [root,"-type","f"];
		if (options != null)
			prms = prms.concat(options);

		var o = new neko.io.Process("find",prms).stdout;
		return textToArray(o.readAll().toString());
	}
    
	public static
	function textToArray(text:String,delimiter='\n'):Array<String> {
		var ar = text.split(delimiter),
				lastEl = ar.pop();
		if (StringTools.trim(lastEl) == "")
			return ar;
		ar.push(lastEl) ;
		return ar;
	}

    public static function
    packit(hpxFile:String) {
      var
        hpx = Parser.process(hpxFile),
        conf = Parser.getConfig(hpx);
      
      return Package.createFrom(conf);
    }  

}