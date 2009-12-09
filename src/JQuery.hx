import js.Dom;

extern class JQuery implements ArrayAccess<HtmlDom>{
    static function __init__():Void{
        untyped __js__("var JQuery = window.jQuery;");
    }
    /**
        Constructor
    **/
    public static function new(selector:Dynamic,?context:Dynamic):Void;

    /**
        Properties
    **/
    public var length(default,null):Int;

    /**
        Core
    **/
    public function each(fn:Int->HtmlDom->Void):JQuery;
    public function get(?index:Int):Dynamic;
    public function index(subject:HtmlDom):Int;
    public function data(name:String,?value:Dynamic):Dynamic;
    public function removeData(name:String):JQuery;

    /**
        Traversing functions
    **/
    public function eq(index:Int):JQuery;
    //public function filter<T:(String,Int2BoolFn)>(expression:T):JQuery;
    public function filter(expression:Dynamic):JQuery;
    public function is(expression:String):Bool;
    public function map(fn:Int->HtmlDom):JQuery;
    //public function not<T:(String,HtmlDom,Array<HtmlDom>)>(expression:T):JQuery;
    public function not(expression:Dynamic):JQuery;
    public function slice(startIndex:Int,?endIndex:Int):JQuery;

    /**
        Finding functions
    **/
    //public function add<T:(String,HtmlDom,Array<HtmlDom>)>(expression:T):JQuery;
    public function add(expression:Dynamic):JQuery;
    public function children(?expression:String):JQuery;
    public function contents():JQuery;
    public function find(expression:String):JQuery;
    public function next(?expression:String):JQuery;
    public function nextAll(?expression:String):JQuery;
    public function parent(?expression:String):JQuery;
    public function parents(?expression:String):JQuery;
    public function prev(?expression:String):JQuery;
    public function prevAll(?expression:String):JQuery;
    public function siblings(?expression:String):JQuery;


    /**
        Chaining
    **/
    public function andSelf():JQuery;
    public function end():JQuery;

    /**
        Manipulation
    **/
    public function html(?val:String):Dynamic;
    public function text(?val:String):Dynamic;
    public function val(?val:String):Dynamic;
    public function append(content:Dynamic):JQuery;
    public function appendTo(content:Dynamic):JQuery;
    public function prepend(content:Dynamic):JQuery;
    public function prependTo(content:Dynamic):JQuery;

    public function after(content:Dynamic):JQuery;
    public function before(content:Dynamic):JQuery;
    public function insertAfter(content:Dynamic):JQuery;
    public function insertBefore(content:Dynamic):JQuery;

    public function wrap(content:Dynamic):JQuery;
    public function wrapAll(content:Dynamic):JQuery;
    public function wrapInner(content:Dynamic):JQuery;

    public function replaceWith(content:Dynamic):JQuery;
    public function replaceAll(selector:Dynamic):JQuery;
    public function empty():JQuery;
    public function remove(expression:String):JQuery;

    public function clone(?cloneHandlers:Bool):JQuery;

    /**
        Attributes
    **/
    public function attr(param1:Dynamic,?param2:Dynamic):Dynamic;
    public function removeAttr(name:String):JQuery;

    /**
        Class
    **/
    public function addClass(className:String):JQuery;
    public function hasClass(className:String):Bool;
    public function removeClass(className:String):JQuery;
    public function toggleClass(className:String):JQuery;

    /**
        Css
    **/
    public function css(param1:Dynamic,?param2:Dynamic):Dynamic;
    public function offset():Dynamic;
    public function position():Dynamic;
    public function scrollTop(?val:Int):Dynamic;
    public function scrollLeft(?val:Int):Dynamic;
    public function height(?val:Int):Dynamic;
    public function width(?val:Int):Dynamic;
    public function innerHeight():Int;
    public function innerWidth():Int;
    public function outerHeight(?options:Dynamic):Int;
    public function outerWidth(?options:Dynamic):Int;

    /**
        Events
    **/

    public function bind(type:String,?data:Dynamic,fn:Event->Void):JQuery;
    public function one(type:String,?data:Dynamic,fn:Event->Void):JQuery;
    public function trigger(type:String,?data:Dynamic):JQuery;
    public function triggerHandler(type:String,?data:Dynamic):JQuery;
    public function unbind(?type:String,?fn:Event->Void):JQuery;

    public function hover(fnOver:Event->Void,fnOut:Event->Void):JQuery;
    public function toggle(?fn1:Event->Void,?fn2:Event->Void,?fn3:Event->Void,?fn4:Event->Void,?fn5:Event->Void,?fn6:Event->Void,?fn7:Event->Void,?fn8:Event->Void):JQuery;

    public function blur(?fn:Event->Void):JQuery;
    public function change(?fn:Event->Void):JQuery;
    public function click(?fn:Event->Void):JQuery;
    public function dblclick(?fn:Event->Void):JQuery;
    public function error(?fn:Event->Void):JQuery;
    public function focus(?fn:Event->Void):JQuery;
    public function keydown(?fn:Event->Void):JQuery;
    public function keypress(?fn:Event->Void):JQuery;
    public function keyup(?fn:Event->Void):JQuery;
    public function load(fn:Event->Void):JQuery;
    public function mousedown(fn:Event->Void):JQuery;
    public function mousemove(fn:Event->Void):JQuery;
    public function mouseout(fn:Event->Void):JQuery;
    public function mouseover(fn:Event->Void):JQuery;
    public function mouseup(fn:Event->Void):JQuery;
    public function resize(fn:Event->Void):JQuery;
    public function scroll(fn:Event->Void):JQuery;
    public function select(?fn:Event->Void):JQuery;
    public function submit(?fn:Event->Void):JQuery;
    public function unload(fn:Event->Void):JQuery;

    /**
        Effects
    **/
    public function hide(?speed:Int,?cback:HtmlDom->Void):JQuery;
    public function show(?show:Int,?cback:HtmlDom->Void):JQuery;
    public function slideDown(speed:Int,?cback:HtmlDom->Void):JQuery;
    public function slideUp(speed:Int,?cback:HtmlDom->Void):JQuery;
    public function slideToggle(speed:Int,?cback:HtmlDom->Void):JQuery;
    public function fadeIn(speed:Int,?cback:HtmlDom->Void):JQuery;
    public function fadeOut(speed:Int,?cback:HtmlDom->Void):JQuery;
    public function fadeTo(speed:Int,opacity:Float,?cback:HtmlDom->Void):JQuery;

// ritchie's
	public static function param(d:Dynamic):String;
	public static function getJSON(url:String,fn:Dynamic->Void):Void;
	public static function getScript(url:String,fn:Void->Void):Void;
	public function ready(fn:Void->Void):JQuery;
	public function serialize():String;
}
