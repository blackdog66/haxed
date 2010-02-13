package haxed;

// don't like a separate file for this

//import hxjson2.JSON;

import haxed.Common;
import haxed.JSON;

class ConfigJson extends Config {
  public
  function new (j:String) {
    super();
    data = JSON.decodeString(j);
  }
}
