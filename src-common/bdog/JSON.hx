
package bdog;

#if (neko || php)
import bdog.Json;
#elseif nodejs
import js.Node;
#end

class JSON {

  public static function
  encode(o:Dynamic):String {
#if (nodejs)
    return Node.stringify(o);
#elseif (js && !nodejs)
    return untyped __js__("JSON.stringify(o)");
#else
    return Json.encode(o);
#end
  }

  public static function
  decode(s:String):Dynamic {
#if (nodejs)
    return Node.parse(s);
#elseif (js && !nodejs)
    return untyped __js__("JSON.parse(s)");
#else
    return Json.decode(s);
#end
  }

}


