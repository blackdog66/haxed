
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
      //users = getUsers(),
      client = new ClientRestful(),
      tmpDir = "/tmp/unzip/",
      fs = Os.files("/home/daniel/oldhaxe"), // the haxelib zip directory
      nnull = 0,
      i = 0;

    for (f in fs) {
      if (Os.exists(tmpDir)) Os.rmdir(tmpDir);
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
        //user = users.get(dev),
        user = { pw: "12345", fn: dev },
        o = new Options(),
        email = dev+"@haxe.org";

      o.addSwitch("-R","localhost:8200");

      client.register(o,email,user.pw,user.fn,
                      function(rurl:String,s:Status) {
                        trace("registed "+dev+"@haxe.org");
                        return true;
                      });

      Reflect.setField(data,"email",email);
      Os.fileOut(tmpDir+"haxelib.json",toHxp(data));
      newPackage = packit(tmpDir+"haxelib.json");

      zf.close();

      client.submit(o,user.pw,newPackage,function(rurl:String,s:Status) {
          trace("submitted to "+rurl);
          trace("status "+s);
          return true;
        });

      if (i++ == 20) break;     // don't do them all right now
    }

    trace("nnull = "+nnull);
  }
/*
  public static function
  getUsers():Hash<OldUser> {
    var
      sql = "select name,pass,fullname from user",
      users = new Hash<OldUser>(),
      rows;

    cnx = neko.db.Sqlite.open("haxelib.db");
    rows = cnx.execute(sql);

    for (r in rows) {
      users.set(r.name,{pw:r.pass,fn:r.fullname});
    }

    cnx.close();
    return users;
  }
*/
  public static function
  toHxp(x:XmlInfos) {
    var data: Dynamic = {}, d: Dynamic, t: Dynamic;
    for (field in Reflect.fields(x)) {
      t = Reflect.field(x, field);
      if (Std.is(t, List) && (t.length == 0 || Std.is(t.first(), String))) {
        d = t.join(" ");
      } else if (Std.is(t, String) && cast(t, String).indexOf("\n") > -1) {
        d = "";
        var a: Array<String> = StringTools.trim(t).split("\n");
        var f = true;
        for (s in a) {
          if (f) {
            f = false;
            d += s;
          } else {
            d += "\n                " + StringTools.ltrim(s);
          }
        }
      } else {
        d = Std.string(t);
      }
      //if (d.length == 0) d = "null";
      Reflect.setField(data, field, StringTools.trim(d));
    }
    var tmpl = '
project:        ::project::
website:        ::website::
version:        ::version::
comments:       ::versionComments::
description:    ::desc::
author-email:   ::email::
license:        ::license::
author:         ::developers::
';
    if (Reflect.hasField(data, "tags") && data.tags.length > 0) {
      tmpl += 'tags:           ::tags::
';
    }
    return Os.template(tmpl,data);
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
    packit(hxpFile:String) {
      var
        hxp = Parser.process(hxpFile),
        conf = Parser.getConfig(hxp);

      return Package.createFrom(conf);
    }

}