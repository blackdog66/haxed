

import tools.haxelib.SiteDb;

class Mkdb {

  public static
  function main() {
    var cnx = neko.db.Mysql.connect({ 
            host : "localhost",
            port : 3306,
            user : "blackdog",
            pass : "woot",
            socket : null,
            database : "haxelib"
        });

    SiteDb.create(cnx);
  }
}