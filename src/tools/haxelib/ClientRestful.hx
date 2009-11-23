
package tools.haxelib;
import tools.haxelib.ClientCore;

class RestfulClient extends ClientCore {

  public function new(repos:Array<String>) { super(); }

  public
  function install(pkgName:String) {
    
  }

  public
  function submit(packagePath:String) {
    Os.filePost(packagePath,"http://localhost:8200/index.php?method=submit",true); 
  }

  public
  function search(query:String) {
  }
  
  public
  function upgrade() {
  }

  public
  function user() {
  }

  public
  function info(pkg:String) {

  }

  public
  function register(email:String,password:String) {
    
  }

  public
  function capabilities() {}

}