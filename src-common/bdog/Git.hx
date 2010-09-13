package bdog;
// test submodule change - 2

import bdog.Os;
import bdog.Tokenizer;
import bdog.Reader;
import bdog.Log;

enum TLog {
  TCommit(id:String);
  TAuthor(a:String);
  TDate(d:String);
  TComment(c:String);
}

typedef LogEntry = {
  var commit:String;
  var author:String;
  var date:String;
  var version:String;
  var comment:String;
}
  
class Git {

  public var dir(default,null):String;
  static var reVer = ~/\(tag:\s([^,)]+)/;
  
  public function new(d:String) {
    dir = Os.slash(d);
    if (!Os.exists(dir))
      Os.mkdir(dir);
    
    if (!Os.exists(dir+".git")) {
      init();
    }
  }

  public function
  inRepo(f:Void->Dynamic):Dynamic {
    Os.cd(dir);
    var o = f();
    Os.cdpop();
    return o;
  }

  public function
  commit(comment:String) {
    inRepo(function() {
        Os.process('git add .');
        Os.process('git commit -m "'+comment+'"');
      });
  }
  
  public function
  tag(name:String) {
    inRepo(function() {
        Os.process('git tag -f -a -m '+name+' '+name);
      });
  }

  public function
  init() {
    inRepo(function() {        
        return Os.process("git init");
      });
  }

  public function
  describe() {
    return inRepo(function() {        
        return Os.process("git describe");
      });
  }

  static function
  parseLog(l:String) {
    var tk = new Tokenizer<TLog>(new StringReader(l));
    tk.match(~/^\s?commit\s(.*?)\n/,function(re) { return TCommit(re.matched(1)); })
      .match(~/^Author:(.*?)\n/,function(re) {return TAuthor(re.matched(1)); })
      .match(~/^Date:(.*?)\n/,function(re) {return TDate(re.matched(1)); })
      .match(~/^\n(.+)\n{1,2}/,function(re) {return TComment(re.matched(1)); });
    var
      state:Int = 0,
      a:Array<LogEntry> = new Array(),
      tok:TLog,
      tmp:LogEntry = { commit:null, author:null, date: null,
                       comment:null,version:null };
    
    while((tok = tk.nextToken()) != null) {
      switch (tok) {
      case TCommit(c):
        if (reVer.match(c)) {
          tmp.version = Os.path(reVer.matched(1),FILE);
          tmp.commit = StringTools.trim(reVer.matchedLeft());
        } else {
          tmp.commit = StringTools.trim(c);
          tmp.version = "None";
        }
      case TAuthor(a):tmp.author = StringTools.trim(a);
      case TDate(d):tmp.date = StringTools.trim(d);
      case TComment(c):
        tmp.comment = StringTools.trim(c);
      }
      state++;
      if (state == 4 && tmp.version != "None") {
        a.push(tmp);
        tmp = { commit:null, author:null, date: null, comment:null,version:null };
        state = 0;
      }
    }

    if (state == 3 && tmp.version != "None") a.push(tmp);
    
    return a;
  }
  
  public function
  log():Array<LogEntry> {
    return inRepo(function() {
        return parseLog(Os.process("git log --decorate"));
      });
  }

  public function
  archive(name:String,outputDir:String,version:String) {
    return inRepo(function() {
        var n = Os.slash(outputDir)+name;
        return Os.process("git archive --format=zip --output "+n+" "+version);
      });
  }
}
