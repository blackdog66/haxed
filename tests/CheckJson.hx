
import hxjson2.JSON;

class CheckJson {
  static var json = '{"data":{"file":"./test.hbl","sourceRepo":{"type":"darcs","location":"http://darcs.haskell.org/cabal-branches/cabal-1.6/","tag":"1.6.1","attrs":["this"]},"end":{"attrs":[""]},"global":{"projectUrl":"http://www.woot.com","name":"project-name","license":"GPL","homepage":"URL","tags":["tag1","tag2"],"bug-reports":"URL","stability":"freeform","copyright":"freeform","description":"freeform","package-url":"URL","data-dir":"directory","author":"Ritchie Turner","version":"numbers (required)","license-url":"URL","haxelibVersion":">, <=, etc. & numbers","extra-source-files":"filename list","synopsis":"freeform","tested-with":"compiler list","derives-from":"project-name & version","maintainer":"address","authorEmail":"blackdog@ipowerhouse.com","extra-tmp-files":"filename list","category":"freeform","data-files":"filename list"},"executable":{"haxe-options":"token list","sourceDirs":["directory","list"],"buildable":false,"build-depends":"package list (e.g. base >= 2, foo >= 1.2 && < 1.3, bar)","attrs":["foo"],"mainIs":"filename (required)"},"library":{"haxe-options":"token list","sourceDirs":["/home/blackdog/Projects/haxelib/src"],"buildable":true,"build-depends":"package list (e.g. base >= 2, foo >= 1.2 && < 1.3, bar)","attrs":[""]}}}';

  public static
  function main() {
    trace(JSON.decode(json));
  } 
  

}