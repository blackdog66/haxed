package tools.haxelib;

class Options {
  private var repos:List<String>;
  
  public function new() {
    repos = new List<String>();
    repos.add("localhost:8200");
    repos.add("lib.haxelib.org");
    repos.add("www.bazarrware.com");
  }

  public var repo(getRepo,setRepo) : String;

  private function getRepo() {
    return repos.first();
  }
  private function setRepo( r : String ) {
    repos.push(r);
    return r;
  }

}

enum Command {
  NOOP;
  LIST(options:Options);
  REMOVE(options:Options,pkg:String,ver:String);
  SET(options:Options,prj:String,ver:String);
  SETUP(options:Options,path:String);
  CONFIG(options:Options);
  PATH(options:Options,paths:Array<{project:String,version:String}>);
  RUN(options:Options,param:String);
  TEST(options:Options,pkg:String);
  INSTALL(options:Options,pkg:String);
  SEARCH(options:Options,query:String);
  INFO(options:Options,project:String);
  USER(options:Options,email:String);
  REGISTER(options:Options,email:String,password:String,fullName:String);
  SUBMIT(options:Options,pkgPath:String);
  DEV(options:Options,prj:String,dir:String);
  PACKAGE(options:Options,hblFile:String);
}
