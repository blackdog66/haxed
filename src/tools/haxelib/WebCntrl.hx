
package tools.haxelib;

import tools.haxelib.Common;
import JQuery;
import haxe.Template;

class HtmlMacros {
  public static function
  pkgName(resolve : String -> Dynamic,pkg,ver) {
    return Common.pkgName(pkg,ver);
  }
}

class RepoService {
  var repo:String;
  
  public function new(r:String) {
    repo = r;
  }

  function
  url(cmd:String,params:Dynamic) {
    var
      p:String,
      u = repo+"?method="+cmd;

    if (Std.is(params,String)) {
      p = params;
    } else
      p = JQuery.param(params);
    
    return (p.length == 0) ? u : u + "&" + p;   
  }
  
  public function
  projects(cb:Status->Void) {
    WebCntrl.doService(url("projects",{}),cb);
  }

  public function
  serverInfo(cb:Status->Void) {
    WebCntrl.doService(url("serverInfo",{}),cb);
  }
}

class WebCntrl {
  public static var ctrl;
  
  static var htmlMacros:Dynamic;

  public static function
  main() {
    ctrl = new WebCntrl();
  }
  
  public function new() {
    if(haxe.Firebug.detect())
      haxe.Firebug.redirectTraces();
    else
      haxe.Log.trace = WebCntrl.nullTrace;
    
    setupMacros();
    ready();
  }

  function loadCss(path:String) {
    var jq = new JQuery('link[href*="'+path+'"]');
    if (jq.length == 0) {
      var l = new JQuery("<link/>");
      l.attr({rel:"stylesheet"});
      l.attr({type:"text/css"});
      l.attr({href:path});
      l.appendTo("head");
    }
  }

  public static
  function status(m:String) {
    new JQuery('#help').html('<div style="color:#ff0000">'+m+'</div>').fadeIn();
  }
  
  public
  function trace(s:String) {
    untyped {
      if(window.console){
        window.console.log(s);
      }
    }
  }

  public static function nullTrace( v : Dynamic, ?inf : haxe.PosInfos ) {	}

  public static function
  setupMacros() {
    htmlMacros = {};
  	// set up macros for templating, map them from Common class
    for (f in Type.getClassFields(HtmlMacros)) {
      var fld = Reflect.field(HtmlMacros,f);
      if (Reflect.isFunction(fld))
        Reflect.setField(htmlMacros,f,fld);
    }
  }
  
  static public
  function template(tmpl:String,data:Dynamic):String {
    var tmpl =StringTools.htmlUnescape(new JQuery(tmpl).get(0).innerHTML),
      t = new haxe.Template(tmpl) ;
    return t.execute(data,htmlMacros);
  }
  
  public static
  function doService(url:String,cb:Status->Void) {
    trace("service: "+url);
    JQuery.getJSON(url,function(data) {
        cb(Marshall.fromJson(data));
      });
	}

  function initDialog() {
    var d = new JQuery('#dialog');
    untyped d.dialog({
      bgiframe: true,
          autoOpen:false,
          modal: true,
          buttons: {
        Ok: function() {
            d.dialog('close');
          }
        }
      });
  }

  public static
  function msg(m:String) {
    var d = new JQuery('#dialog');
    d.html(m);
    untyped d.dialog('open');
  }

  static function
  statusHandler(s:Status) {
    switch(s) {
    case OK_PROJECTS(prjs):
      trace(prjs);
      new JQuery("#prj-list").html(template('#tmpl-prj-list',{projects:prjs}));
      untyped __js__("

       $('.project').toggle(
             function() { $('.details',$(this)).css({display:'inline'}) ;},
             function() { $('.details',$(this)).css({display:'none'}); });
");
                                    
      new JQuery(".details").css({display:"none"});
    default:
      trace("nout");
    }
  }

  static function
  serverInfoHandler(s:Status) {
    switch(s) {
    case OK_SERVERINFO(si):
      new JQuery('#server-info').html(template('#tmpl-server-info',si));
    default:
      trace("nout");
    }
     
  }
  
  public
  function ready() {
    var me = this,
      rs = new RepoService("repo.php");
        
    new JQuery('').ready(function() {
        rs.serverInfo(serverInfoHandler);
        rs.projects(statusHandler);
      });
      
  }
}
