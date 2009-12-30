$estr = function() { return js.Boot.__string_rec(this,''); }
StringTools = function() { }
StringTools.__name__ = ["StringTools"];
StringTools.urlEncode = function(s) {
	return encodeURIComponent(s);
}
StringTools.urlDecode = function(s) {
	return decodeURIComponent(s.split("+").join(" "));
}
StringTools.htmlEscape = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
}
StringTools.htmlUnescape = function(s) {
	return s.split("&gt;").join(">").split("&lt;").join("<").split("&amp;").join("&");
}
StringTools.startsWith = function(s,start) {
	return (s.length >= start.length && s.substr(0,start.length) == start);
}
StringTools.endsWith = function(s,end) {
	var elen = end.length;
	var slen = s.length;
	return (slen >= elen && s.substr(slen - elen,elen) == end);
}
StringTools.isSpace = function(s,pos) {
	var c = s.charCodeAt(pos);
	return (c >= 9 && c <= 13) || c == 32;
}
StringTools.ltrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,r)) {
		r++;
	}
	if(r > 0) return s.substr(r,l - r);
	else return s;
}
StringTools.rtrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,l - r - 1)) {
		r++;
	}
	if(r > 0) {
		return s.substr(0,l - r);
	}
	else {
		return s;
	}
}
StringTools.trim = function(s) {
	return StringTools.ltrim(StringTools.rtrim(s));
}
StringTools.rpad = function(s,c,l) {
	var sl = s.length;
	var cl = c.length;
	while(sl < l) {
		if(l - sl < cl) {
			s += c.substr(0,l - sl);
			sl = l;
		}
		else {
			s += c;
			sl += cl;
		}
	}
	return s;
}
StringTools.lpad = function(s,c,l) {
	var ns = "";
	var sl = s.length;
	if(sl >= l) return s;
	var cl = c.length;
	while(sl < l) {
		if(l - sl < cl) {
			ns += c.substr(0,l - sl);
			sl = l;
		}
		else {
			ns += c;
			sl += cl;
		}
	}
	return ns + s;
}
StringTools.replace = function(s,sub,by) {
	return s.split(sub).join(by);
}
StringTools.hex = function(n,digits) {
	var neg = false;
	if(n < 0) {
		neg = true;
		n = -n;
	}
	var s = n.toString(16);
	s = s.toUpperCase();
	if(digits != null) while(s.length < digits) s = "0" + s;
	if(neg) s = "-" + s;
	return s;
}
StringTools.prototype.__class__ = StringTools;
Reflect = function() { }
Reflect.__name__ = ["Reflect"];
Reflect.hasField = function(o,field) {
	if(o.hasOwnProperty != null) return o.hasOwnProperty(field);
	var arr = Reflect.fields(o);
	{ var $it0 = arr.iterator();
	while( $it0.hasNext() ) { var t = $it0.next();
	if(t == field) return true;
	}}
	return false;
}
Reflect.field = function(o,field) {
	var v = null;
	try {
		v = o[field];
	}
	catch( $e1 ) {
		{
			var e = $e1;
			null;
		}
	}
	return v;
}
Reflect.setField = function(o,field,value) {
	o[field] = value;
}
Reflect.callMethod = function(o,func,args) {
	return func.apply(o,args);
}
Reflect.fields = function(o) {
	if(o == null) return new Array();
	var a = new Array();
	if(o.hasOwnProperty) {
		
					for(var i in o)
						if( o.hasOwnProperty(i) )
							a.push(i);
				;
	}
	else {
		var t;
		try {
			t = o.__proto__;
		}
		catch( $e2 ) {
			{
				var e = $e2;
				{
					t = null;
				}
			}
		}
		if(t != null) o.__proto__ = null;
		
					for(var i in o)
						if( i != "__proto__" )
							a.push(i);
				;
		if(t != null) o.__proto__ = t;
	}
	return a;
}
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && f.__name__ == null;
}
Reflect.compare = function(a,b) {
	return ((a == b)?0:((((a) > (b))?1:-1)));
}
Reflect.compareMethods = function(f1,f2) {
	if(f1 == f2) return true;
	if(!Reflect.isFunction(f1) || !Reflect.isFunction(f2)) return false;
	return f1.scope == f2.scope && f1.method == f2.method && f1.method != null;
}
Reflect.isObject = function(v) {
	if(v == null) return false;
	var t = typeof(v);
	return (t == "string" || (t == "object" && !v.__enum__) || (t == "function" && v.__name__ != null));
}
Reflect.deleteField = function(o,f) {
	if(!Reflect.hasField(o,f)) return false;
	delete(o[f]);
	return true;
}
Reflect.copy = function(o) {
	var o2 = { }
	{
		var _g = 0, _g1 = Reflect.fields(o);
		while(_g < _g1.length) {
			var f = _g1[_g];
			++_g;
			o2[f] = Reflect.field(o,f);
		}
	}
	return o2;
}
Reflect.makeVarArgs = function(f) {
	return function() {
		var a = new Array();
		{
			var _g1 = 0, _g = arguments.length;
			while(_g1 < _g) {
				var i = _g1++;
				a.push(arguments[i]);
			}
		}
		return f(a);
	}
}
Reflect.prototype.__class__ = Reflect;
hxjson2 = {}
hxjson2.JSONEncoder = function(value) { if( value === $_ ) return; {
	this.jsonString = this.convertToString(value);
}}
hxjson2.JSONEncoder.__name__ = ["hxjson2","JSONEncoder"];
hxjson2.JSONEncoder.prototype.arrayToString = function(a) {
	var s = "";
	{
		var _g1 = 0, _g = a.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(s.length > 0) {
				s += ",";
			}
			s += this.convertToString(a[i]);
		}
	}
	return "[" + s + "]";
}
hxjson2.JSONEncoder.prototype.convertToString = function(value) {
	if(Std["is"](value,List) || Std["is"](value,IntHash)) value = Lambda.array(value);
	if(Std["is"](value,Hash)) value = this.mapHash(value);
	if(Std["is"](value,String)) {
		return this.escapeString((function($this) {
			var $r;
			var tmp = value;
			$r = (Std["is"](tmp,String)?tmp:(function($this) {
				var $r;
				throw "Class cast error";
				return $r;
			}($this)));
			return $r;
		}(this)));
	}
	else if(Std["is"](value,Float)) {
		return (Math.isFinite((function($this) {
			var $r;
			var tmp = value;
			$r = (Std["is"](tmp,Float)?tmp:(function($this) {
				var $r;
				throw "Class cast error";
				return $r;
			}($this)));
			return $r;
		}(this)))?value + "":"null");
	}
	else if(Std["is"](value,Bool)) {
		return (value?"true":"false");
	}
	else if(Std["is"](value,Array)) {
		return this.arrayToString((function($this) {
			var $r;
			var tmp = value;
			$r = (Std["is"](tmp,Array)?tmp:(function($this) {
				var $r;
				throw "Class cast error";
				return $r;
			}($this)));
			return $r;
		}(this)));
	}
	else if(Std["is"](value,Dynamic) && value != null) {
		return this.objectToString(value);
	}
	return "null";
}
hxjson2.JSONEncoder.prototype.escapeString = function(str) {
	var s = "";
	var ch;
	var len = str.length;
	{
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			ch = str.charAt(i);
			switch(ch) {
			case "\"":{
				s += "\\\"";
			}break;
			case "\\":{
				s += "\\\\";
			}break;
			case "\n":{
				s += "\\n";
			}break;
			case "\r":{
				s += "\\r";
			}break;
			case "\t":{
				s += "\\t";
			}break;
			default:{
				var code = ch.charCodeAt(0);
				if(ch < " " || code > 127) {
					var hexCode = StringTools.hex(ch.charCodeAt(0));
					var zeroPad = "";
					{
						var _g2 = 0, _g1 = 4 - hexCode.length;
						while(_g2 < _g1) {
							var j = _g2++;
							zeroPad += "0";
						}
					}
					s += "\\u" + zeroPad + hexCode;
				}
				else {
					s += ch;
				}
			}break;
			}
		}
	}
	return "\"" + s + "\"";
}
hxjson2.JSONEncoder.prototype.getString = function() {
	return this.jsonString;
}
hxjson2.JSONEncoder.prototype.jsonString = null;
hxjson2.JSONEncoder.prototype.mapHash = function(value) {
	var ret = { }
	{ var $it3 = value.keys();
	while( $it3.hasNext() ) { var i = $it3.next();
	ret[i] = value.get(i);
	}}
	return ret;
}
hxjson2.JSONEncoder.prototype.objectToString = function(o) {
	var s = "";
	var value;
	{
		var _g = 0, _g1 = Reflect.fields(o);
		while(_g < _g1.length) {
			var key = _g1[_g];
			++_g;
			value = Reflect.field(o,key);
			if(!Reflect.isFunction(value)) {
				if(s.length > 0) {
					s += ",";
				}
				s += this.escapeString(key) + ":" + this.convertToString(value);
			}
		}
	}
	return "{" + s + "}";
}
hxjson2.JSONEncoder.prototype.__class__ = hxjson2.JSONEncoder;
haxe = {}
haxe.Log = function() { }
haxe.Log.__name__ = ["haxe","Log"];
haxe.Log.trace = function(v,infos) {
	js.Boot.__trace(v,infos);
}
haxe.Log.clear = function() {
	js.Boot.__clear_trace();
}
haxe.Log.prototype.__class__ = haxe.Log;
hxjson2.JSONTokenizer = function(s,strict) { if( s === $_ ) return; {
	this.jsonString = s;
	this.strict = strict;
	this.loc = 0;
	this.nextChar();
}}
hxjson2.JSONTokenizer.__name__ = ["hxjson2","JSONTokenizer"];
hxjson2.JSONTokenizer.prototype.ch = null;
hxjson2.JSONTokenizer.prototype.getNextToken = function() {
	var token = new hxjson2.JSONToken();
	this.skipIgnored();
	switch(this.ch) {
	case "{":{
		token.type = hxjson2.JSONTokenType.LEFT_BRACE;
		token.value = "{";
		this.nextChar();
	}break;
	case "}":{
		token.type = hxjson2.JSONTokenType.RIGHT_BRACE;
		token.value = "}";
		this.nextChar();
	}break;
	case "[":{
		token.type = hxjson2.JSONTokenType.LEFT_BRACKET;
		token.value = "[";
		this.nextChar();
	}break;
	case "]":{
		token.type = hxjson2.JSONTokenType.RIGHT_BRACKET;
		token.value = "]";
		this.nextChar();
	}break;
	case ",":{
		token.type = hxjson2.JSONTokenType.COMMA;
		token.value = ",";
		this.nextChar();
	}break;
	case ":":{
		token.type = hxjson2.JSONTokenType.COLON;
		token.value = ":";
		this.nextChar();
	}break;
	case "t":{
		var possibleTrue = "t" + this.nextChar() + this.nextChar() + this.nextChar();
		if(possibleTrue == "true") {
			token.type = hxjson2.JSONTokenType.TRUE;
			token.value = true;
			this.nextChar();
		}
		else {
			this.parseError("Expecting 'true' but found " + possibleTrue);
		}
	}break;
	case "f":{
		var possibleFalse = "f" + this.nextChar() + this.nextChar() + this.nextChar() + this.nextChar();
		if(possibleFalse == "false") {
			token.type = hxjson2.JSONTokenType.FALSE;
			token.value = false;
			this.nextChar();
		}
		else {
			this.parseError("Expecting 'false' but found " + possibleFalse);
		}
	}break;
	case "n":{
		var possibleNull = "n" + this.nextChar() + this.nextChar() + this.nextChar();
		if(possibleNull == "null") {
			token.type = hxjson2.JSONTokenType.NULL;
			token.value = null;
			this.nextChar();
		}
		else {
			this.parseError("Expecting 'null' but found " + possibleNull);
		}
	}break;
	case "N":{
		var possibleNAN = "N" + this.nextChar() + this.nextChar();
		if(possibleNAN == "NAN" || possibleNAN == "NaN") {
			token.type = hxjson2.JSONTokenType.NAN;
			token.value = Math.NaN;
			this.nextChar();
		}
		else {
			this.parseError("Expecting 'nan' but found " + possibleNAN);
		}
	}break;
	case "\"":{
		token = this.readString();
	}break;
	default:{
		if(this.isDigit(this.ch) || this.ch == "-") {
			token = this.readNumber();
		}
		else if(this.ch == "") {
			return null;
		}
		else {
			this.parseError("Unexpected " + this.ch + " encountered");
		}
	}break;
	}
	return token;
}
hxjson2.JSONTokenizer.prototype.hexValToInt = function(hexVal) {
	var ret = 0;
	{
		var _g1 = 0, _g = hexVal.length;
		while(_g1 < _g) {
			var i = _g1++;
			ret = ret << 4;
			switch(hexVal.charAt(i).toUpperCase()) {
			case "1":{
				ret += 1;
			}break;
			case "2":{
				ret += 2;
			}break;
			case "3":{
				ret += 3;
			}break;
			case "4":{
				ret += 4;
			}break;
			case "5":{
				ret += 5;
			}break;
			case "6":{
				ret += 6;
			}break;
			case "7":{
				ret += 7;
			}break;
			case "8":{
				ret += 8;
			}break;
			case "9":{
				ret += 9;
			}break;
			case "A":{
				ret += 10;
			}break;
			case "B":{
				ret += 11;
			}break;
			case "C":{
				ret += 12;
			}break;
			case "D":{
				ret += 13;
			}break;
			case "E":{
				ret += 14;
			}break;
			case "F":{
				ret += 15;
			}break;
			}
		}
	}
	return ret;
}
hxjson2.JSONTokenizer.prototype.isDigit = function(ch) {
	return (ch >= "0" && ch <= "9");
}
hxjson2.JSONTokenizer.prototype.isHexDigit = function(ch) {
	var uc = ch.toUpperCase();
	return (this.isDigit(ch) || (uc >= "A" && uc <= "F"));
}
hxjson2.JSONTokenizer.prototype.isWhiteSpace = function(ch) {
	return (ch == " " || ch == "\t" || ch == "\n" || ch == "\r");
}
hxjson2.JSONTokenizer.prototype.jsonString = null;
hxjson2.JSONTokenizer.prototype.loc = null;
hxjson2.JSONTokenizer.prototype.nextChar = function() {
	return this.ch = this.jsonString.charAt(this.loc++);
}
hxjson2.JSONTokenizer.prototype.obj = null;
hxjson2.JSONTokenizer.prototype.parseError = function(message) {
	throw new hxjson2.JSONParseError(message,this.loc,this.jsonString);
}
hxjson2.JSONTokenizer.prototype.readNumber = function() {
	var input = "";
	if(this.ch == "-") {
		input += "-";
		this.nextChar();
	}
	if(!this.isDigit(this.ch)) {
		this.parseError("Expecting a digit");
	}
	if(this.ch == "0") {
		input += this.ch;
		this.nextChar();
		if(this.isDigit(this.ch)) {
			this.parseError("A digit cannot immediately follow 0");
		}
		else {
			if(!this.strict && this.ch == "x") {
				input += this.ch;
				this.nextChar();
				if(this.isHexDigit(this.ch)) {
					input += this.ch;
					this.nextChar();
				}
				else {
					this.parseError("Number in hex format require at least one hex digit after \"0x\"");
				}
				while(this.isHexDigit(this.ch)) {
					input += this.ch;
					this.nextChar();
				}
				input = Std.string(this.hexValToInt(input));
			}
		}
	}
	else {
		while(this.isDigit(this.ch)) {
			input += this.ch;
			this.nextChar();
		}
	}
	if(this.ch == ".") {
		input += ".";
		this.nextChar();
		if(!this.isDigit(this.ch)) {
			this.parseError("Expecting a digit");
		}
		while(this.isDigit(this.ch)) {
			input += this.ch;
			this.nextChar();
		}
	}
	if(this.ch == "e" || this.ch == "E") {
		input += "e";
		this.nextChar();
		if(this.ch == "+" || this.ch == "-") {
			input += this.ch;
			this.nextChar();
		}
		if(!this.isDigit(this.ch)) {
			this.parseError("Scientific notation number needs exponent value");
		}
		while(this.isDigit(this.ch)) {
			input += this.ch;
			this.nextChar();
		}
	}
	var num = Std.parseFloat(input);
	if(Math.isFinite(num) && !Math.isNaN(num)) {
		var token = new hxjson2.JSONToken();
		token.type = hxjson2.JSONTokenType.NUMBER;
		token.value = num;
		return token;
	}
	else {
		this.parseError("Number " + num + " is not valid!");
	}
	return null;
}
hxjson2.JSONTokenizer.prototype.readString = function() {
	var string = "";
	this.nextChar();
	while(this.ch != "\"" && this.ch != "") {
		if(this.ch == "\\") {
			this.nextChar();
			switch(this.ch) {
			case "\"":{
				string += "\"";
			}break;
			case "/":{
				string += "/";
			}break;
			case "\\":{
				string += "\\";
			}break;
			case "n":{
				string += "\n";
			}break;
			case "r":{
				string += "\r";
			}break;
			case "t":{
				string += "\t";
			}break;
			case "u":{
				var hexValue = "";
				{
					var _g = 0;
					while(_g < 4) {
						var i = _g++;
						if(!this.isHexDigit(this.nextChar())) {
							this.parseError(" Excepted a hex digit, but found: " + this.ch);
						}
						hexValue += this.ch;
					}
				}
				string += String.fromCharCode(this.hexValToInt(hexValue));
			}break;
			default:{
				string += "\\" + this.ch;
			}break;
			}
		}
		else {
			string += this.ch;
		}
		this.nextChar();
	}
	if(this.ch == "") {
		this.parseError("Unterminated string literal");
	}
	this.nextChar();
	var token = new hxjson2.JSONToken();
	token.type = hxjson2.JSONTokenType.STRING;
	token.value = string;
	return token;
}
hxjson2.JSONTokenizer.prototype.skipComments = function() {
	if(this.ch == "/") {
		this.nextChar();
		switch(this.ch) {
		case "/":{
			do {
				this.nextChar();
			} while(this.ch != "\n" && this.ch != "");
			this.nextChar();
		}break;
		case "*":{
			this.nextChar();
			while(true) {
				if(this.ch == "*") {
					this.nextChar();
					if(this.ch == "/") {
						this.nextChar();
						break;
					}
				}
				else {
					this.nextChar();
				}
				if(this.ch == "") {
					this.parseError("Multi-line comment not closed");
				}
			}
		}break;
		default:{
			this.parseError("Unexpected " + this.ch + " encountered (expecting '/' or '*' )");
		}break;
		}
	}
}
hxjson2.JSONTokenizer.prototype.skipIgnored = function() {
	var originalLoc;
	do {
		originalLoc = this.loc;
		this.skipWhite();
		this.skipComments();
	} while(originalLoc != this.loc);
}
hxjson2.JSONTokenizer.prototype.skipWhite = function() {
	while(this.isWhiteSpace(this.ch)) {
		this.nextChar();
	}
}
hxjson2.JSONTokenizer.prototype.strict = null;
hxjson2.JSONTokenizer.prototype.__class__ = hxjson2.JSONTokenizer;
StringBuf = function(p) { if( p === $_ ) return; {
	this.b = new Array();
}}
StringBuf.__name__ = ["StringBuf"];
StringBuf.prototype.add = function(x) {
	this.b[this.b.length] = x;
}
StringBuf.prototype.addChar = function(c) {
	this.b[this.b.length] = String.fromCharCode(c);
}
StringBuf.prototype.addSub = function(s,pos,len) {
	this.b[this.b.length] = s.substr(pos,len);
}
StringBuf.prototype.b = null;
StringBuf.prototype.toString = function() {
	return this.b.join("");
}
StringBuf.prototype.__class__ = StringBuf;
hxjson2.JSONParseError = function(message,location,text) { if( message === $_ ) return; {
	if(text == null) text = "";
	if(location == null) location = 0;
	if(message == null) message = "";
	this.name = "JSONParseError";
	this._location = location;
	this._text = text;
	this.message = message;
}}
hxjson2.JSONParseError.__name__ = ["hxjson2","JSONParseError"];
hxjson2.JSONParseError.prototype._location = null;
hxjson2.JSONParseError.prototype._text = null;
hxjson2.JSONParseError.prototype.getlocation = function() {
	return this._location;
}
hxjson2.JSONParseError.prototype.gettext = function() {
	return this._text;
}
hxjson2.JSONParseError.prototype.location = null;
hxjson2.JSONParseError.prototype.message = null;
hxjson2.JSONParseError.prototype.name = null;
hxjson2.JSONParseError.prototype.text = null;
hxjson2.JSONParseError.prototype.toString = function() {
	return this.name + ": " + this.message + " at position: " + this._location + " near \"" + this._text + "\"";
}
hxjson2.JSONParseError.prototype.__class__ = hxjson2.JSONParseError;
hxjson2.JSONToken = function(type,value) { if( type === $_ ) return; {
	this.type = (type == null?hxjson2.JSONTokenType.UNKNOWN:type);
	this.value = value;
}}
hxjson2.JSONToken.__name__ = ["hxjson2","JSONToken"];
hxjson2.JSONToken.prototype.type = null;
hxjson2.JSONToken.prototype.value = null;
hxjson2.JSONToken.prototype.__class__ = hxjson2.JSONToken;
haxe._Template = {}
haxe._Template.TemplateExpr = { __ename__ : ["haxe","_Template","TemplateExpr"], __constructs__ : ["OpVar","OpExpr","OpIf","OpStr","OpBlock","OpForeach","OpMacro"] }
haxe._Template.TemplateExpr.OpBlock = function(l) { var $x = ["OpBlock",4,l]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpExpr = function(expr) { var $x = ["OpExpr",1,expr]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpForeach = function(expr,loop) { var $x = ["OpForeach",5,expr,loop]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpIf = function(expr,eif,eelse) { var $x = ["OpIf",2,expr,eif,eelse]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpMacro = function(name,params) { var $x = ["OpMacro",6,name,params]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpStr = function(str) { var $x = ["OpStr",3,str]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
haxe._Template.TemplateExpr.OpVar = function(v) { var $x = ["OpVar",0,v]; $x.__enum__ = haxe._Template.TemplateExpr; $x.toString = $estr; return $x; }
EReg = function(r,opt) { if( r === $_ ) return; {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
}}
EReg.__name__ = ["EReg"];
EReg.prototype.customReplace = function(s,f) {
	var buf = new StringBuf();
	while(true) {
		if(!this.match(s)) break;
		buf.b[buf.b.length] = this.matchedLeft();
		buf.b[buf.b.length] = f(this);
		s = this.matchedRight();
	}
	buf.b[buf.b.length] = s;
	return buf.b.join("");
}
EReg.prototype.match = function(s) {
	this.r.m = this.r.exec(s);
	this.r.s = s;
	this.r.l = RegExp.leftContext;
	this.r.r = RegExp.rightContext;
	return (this.r.m != null);
}
EReg.prototype.matched = function(n) {
	return (this.r.m != null && n >= 0 && n < this.r.m.length?this.r.m[n]:(function($this) {
		var $r;
		throw "EReg::matched";
		return $r;
	}(this)));
}
EReg.prototype.matchedLeft = function() {
	if(this.r.m == null) throw "No string matched";
	if(this.r.l == null) return this.r.s.substr(0,this.r.m.index);
	return this.r.l;
}
EReg.prototype.matchedPos = function() {
	if(this.r.m == null) throw "No string matched";
	return { pos : this.r.m.index, len : this.r.m[0].length}
}
EReg.prototype.matchedRight = function() {
	if(this.r.m == null) throw "No string matched";
	if(this.r.r == null) {
		var sz = this.r.m.index + this.r.m[0].length;
		return this.r.s.substr(sz,this.r.s.length - sz);
	}
	return this.r.r;
}
EReg.prototype.r = null;
EReg.prototype.replace = function(s,by) {
	return s.replace(this.r,by);
}
EReg.prototype.split = function(s) {
	var d = "#__delim__#";
	return s.replace(this.r,d).split(d);
}
EReg.prototype.__class__ = EReg;
haxe.Template = function(str) { if( str === $_ ) return; {
	var tokens = this.parseTokens(str);
	this.expr = this.parseBlock(tokens);
	if(!tokens.isEmpty()) throw "Unexpected '" + tokens.first().s + "'";
}}
haxe.Template.__name__ = ["haxe","Template"];
haxe.Template.prototype.buf = null;
haxe.Template.prototype.context = null;
haxe.Template.prototype.execute = function(context,macros) {
	this.macros = (macros == null?{ }:macros);
	this.context = context;
	this.stack = new List();
	this.buf = new StringBuf();
	this.run(this.expr);
	return this.buf.b.join("");
}
haxe.Template.prototype.expr = null;
haxe.Template.prototype.macros = null;
haxe.Template.prototype.makeConst = function(v) {
	haxe.Template.expr_trim.match(v);
	v = haxe.Template.expr_trim.matched(1);
	if(v.charCodeAt(0) == 34) {
		var str = v.substr(1,v.length - 2);
		return function() {
			return str;
		}
	}
	if(haxe.Template.expr_int.match(v)) {
		var i = Std.parseInt(v);
		return function() {
			return i;
		}
	}
	if(haxe.Template.expr_float.match(v)) {
		var f = Std.parseFloat(v);
		return function() {
			return f;
		}
	}
	var me = this;
	return function() {
		return me.resolve(v);
	}
}
haxe.Template.prototype.makeExpr = function(l) {
	return this.makePath(this.makeExpr2(l),l);
}
haxe.Template.prototype.makeExpr2 = function(l) {
	var p = l.pop();
	if(p == null) throw "<eof>";
	if(p.s) return this.makeConst(p.p);
	switch(p.p) {
	case "(":{
		var e1 = this.makeExpr(l);
		var p1 = l.pop();
		if(p1 == null || p1.s) throw p1.p;
		if(p1.p == ")") return e1;
		var e2 = this.makeExpr(l);
		var p2 = l.pop();
		if(p2 == null || p2.p != ")") throw p2.p;
		return (function($this) {
			var $r;
			switch(p1.p) {
			case "+":{
				$r = function() {
					return e1() + e2();
				}
			}break;
			case "-":{
				$r = function() {
					return e1() - e2();
				}
			}break;
			case "*":{
				$r = function() {
					return e1() * e2();
				}
			}break;
			case "/":{
				$r = function() {
					return e1() / e2();
				}
			}break;
			case ">":{
				$r = function() {
					return e1() > e2();
				}
			}break;
			case "<":{
				$r = function() {
					return e1() < e2();
				}
			}break;
			case ">=":{
				$r = function() {
					return e1() >= e2();
				}
			}break;
			case "<=":{
				$r = function() {
					return e1() <= e2();
				}
			}break;
			case "==":{
				$r = function() {
					return e1() == e2();
				}
			}break;
			case "!=":{
				$r = function() {
					return e1() != e2();
				}
			}break;
			case "&&":{
				$r = function() {
					return e1() && e2();
				}
			}break;
			case "||":{
				$r = function() {
					return e1() || e2();
				}
			}break;
			default:{
				$r = (function($this) {
					var $r;
					throw "Unknown operation " + p1.p;
					return $r;
				}($this));
			}break;
			}
			return $r;
		}(this));
	}break;
	case "!":{
		var e = this.makeExpr(l);
		return function() {
			var v = e();
			return (v == null || v == false);
		}
	}break;
	case "-":{
		var e = this.makeExpr(l);
		return function() {
			return -e();
		}
	}break;
	}
	throw p.p;
}
haxe.Template.prototype.makePath = function(e,l) {
	var p = l.first();
	if(p == null || p.p != ".") return e;
	l.pop();
	var field = l.pop();
	if(field == null || !field.s) throw field.p;
	var f = field.p;
	haxe.Template.expr_trim.match(f);
	f = haxe.Template.expr_trim.matched(1);
	return this.makePath(function() {
		return Reflect.field(e(),f);
	},l);
}
haxe.Template.prototype.parse = function(tokens) {
	var t = tokens.pop();
	var p = t.p;
	if(t.s) return haxe._Template.TemplateExpr.OpStr(p);
	if(t.l != null) {
		var pe = new List();
		{
			var _g = 0, _g1 = t.l;
			while(_g < _g1.length) {
				var p1 = _g1[_g];
				++_g;
				pe.add(this.parseBlock(this.parseTokens(p1)));
			}
		}
		return haxe._Template.TemplateExpr.OpMacro(p,pe);
	}
	if(p.substr(0,3) == "if ") {
		p = p.substr(3,p.length - 3);
		var e = this.parseExpr(p);
		var eif = this.parseBlock(tokens);
		var t1 = tokens.first();
		var eelse;
		if(t1 == null) throw "Unclosed 'if'";
		if(t1.p == "end") {
			tokens.pop();
			eelse = null;
		}
		else if(t1.p == "else") {
			tokens.pop();
			eelse = this.parseBlock(tokens);
			t1 = tokens.pop();
			if(t1 == null || t1.p != "end") throw "Unclosed 'else'";
		}
		else {
			t1.p = t1.p.substr(4,t1.p.length - 4);
			eelse = this.parse(tokens);
		}
		return haxe._Template.TemplateExpr.OpIf(e,eif,eelse);
	}
	if(p.substr(0,8) == "foreach ") {
		p = p.substr(8,p.length - 8);
		var e = this.parseExpr(p);
		var efor = this.parseBlock(tokens);
		var t1 = tokens.pop();
		if(t1 == null || t1.p != "end") throw "Unclosed 'foreach'";
		return haxe._Template.TemplateExpr.OpForeach(e,efor);
	}
	if(haxe.Template.expr_splitter.match(p)) return haxe._Template.TemplateExpr.OpExpr(this.parseExpr(p));
	return haxe._Template.TemplateExpr.OpVar(p);
}
haxe.Template.prototype.parseBlock = function(tokens) {
	var l = new List();
	while(true) {
		var t = tokens.first();
		if(t == null) break;
		if(!t.s && (t.p == "end" || t.p == "else" || t.p.substr(0,7) == "elseif ")) break;
		l.add(this.parse(tokens));
	}
	if(l.length == 1) return l.first();
	return haxe._Template.TemplateExpr.OpBlock(l);
}
haxe.Template.prototype.parseExpr = function(data) {
	var l = new List();
	var expr = data;
	while(haxe.Template.expr_splitter.match(data)) {
		var p = haxe.Template.expr_splitter.matchedPos();
		var k = p.pos + p.len;
		if(p.pos != 0) l.add({ p : data.substr(0,p.pos), s : true});
		var p1 = haxe.Template.expr_splitter.matched(0);
		l.add({ p : p1, s : p1.indexOf("\"") >= 0});
		data = haxe.Template.expr_splitter.matchedRight();
	}
	if(data.length != 0) l.add({ p : data, s : true});
	var e;
	try {
		e = this.makeExpr(l);
		if(!l.isEmpty()) throw l.first().p;
	}
	catch( $e4 ) {
		if( js.Boot.__instanceof($e4,String) ) {
			var s = $e4;
			{
				throw "Unexpected '" + s + "' in " + expr;
			}
		} else throw($e4);
	}
	return function() {
		try {
			return e();
		}
		catch( $e5 ) {
			{
				var exc = $e5;
				{
					throw "Error : " + Std.string(exc) + " in " + expr;
				}
			}
		}
	}
}
haxe.Template.prototype.parseTokens = function(data) {
	var tokens = new List();
	while(haxe.Template.splitter.match(data)) {
		var p = haxe.Template.splitter.matchedPos();
		if(p.pos > 0) tokens.add({ p : data.substr(0,p.pos), s : true, l : null});
		if(data.charCodeAt(p.pos) == 58) {
			tokens.add({ p : data.substr(p.pos + 2,p.len - 4), s : false, l : null});
			data = haxe.Template.splitter.matchedRight();
			continue;
		}
		var parp = p.pos + p.len;
		var npar = 1;
		while(npar > 0) {
			var c = data.charCodeAt(parp);
			if(c == 40) npar++;
			else if(c == 41) npar--;
			else if(c == null) throw "Unclosed macro parenthesis";
			parp++;
		}
		var params = data.substr(p.pos + p.len,parp - (p.pos + p.len) - 1).split(",");
		tokens.add({ p : haxe.Template.splitter.matched(2), s : false, l : params});
		data = data.substr(parp,data.length - parp);
	}
	if(data.length > 0) tokens.add({ p : data, s : true, l : null});
	return tokens;
}
haxe.Template.prototype.resolve = function(v) {
	if(Reflect.hasField(this.context,v)) return Reflect.field(this.context,v);
	{ var $it6 = this.stack.iterator();
	while( $it6.hasNext() ) { var ctx = $it6.next();
	if(Reflect.hasField(ctx,v)) return Reflect.field(ctx,v);
	}}
	if(v == "__current__") return this.context;
	return Reflect.field(haxe.Template.globals,v);
}
haxe.Template.prototype.run = function(e) {
	var $e = (e);
	switch( $e[1] ) {
	case 0:
	var v = $e[2];
	{
		this.buf.add(Std.string(this.resolve(v)));
	}break;
	case 1:
	var e1 = $e[2];
	{
		this.buf.add(Std.string(e1()));
	}break;
	case 2:
	var eelse = $e[4], eif = $e[3], e1 = $e[2];
	{
		var v = e1();
		if(v == null || v == false) {
			if(eelse != null) this.run(eelse);
		}
		else this.run(eif);
	}break;
	case 3:
	var str = $e[2];
	{
		this.buf.add(str);
	}break;
	case 4:
	var l = $e[2];
	{
		{ var $it7 = l.iterator();
		while( $it7.hasNext() ) { var e1 = $it7.next();
		this.run(e1);
		}}
	}break;
	case 5:
	var loop = $e[3], e1 = $e[2];
	{
		var v = e1();
		try {
			if(v.hasNext == null) {
				var x = v.iterator();
				if(x.hasNext == null) throw null;
				v = x;
			}
		}
		catch( $e8 ) {
			{
				var e2 = $e8;
				{
					throw "Cannot iter on " + v;
				}
			}
		}
		this.stack.push(this.context);
		var v1 = v;
		{ var $it9 = v1;
		while( $it9.hasNext() ) { var ctx = $it9.next();
		{
			this.context = ctx;
			this.run(loop);
		}
		}}
		this.context = this.stack.pop();
	}break;
	case 6:
	var params = $e[3], m = $e[2];
	{
		var v = Reflect.field(this.macros,m);
		var pl = new Array();
		var old = this.buf;
		pl.push($closure(this,"resolve"));
		{ var $it10 = params.iterator();
		while( $it10.hasNext() ) { var p = $it10.next();
		{
			var $e = (p);
			switch( $e[1] ) {
			case 0:
			var v1 = $e[2];
			{
				pl.push(this.resolve(v1));
			}break;
			default:{
				this.buf = new StringBuf();
				this.run(p);
				pl.push(this.buf.b.join(""));
			}break;
			}
		}
		}}
		this.buf = old;
		try {
			this.buf.add(Std.string(v.apply(this.macros,pl)));
		}
		catch( $e11 ) {
			{
				var e1 = $e11;
				{
					var plstr = (function($this) {
						var $r;
						try {
							$r = pl.join(",");
						}
						catch( $e12 ) {
							{
								var e2 = $e12;
								$r = "???";
							}
						}
						return $r;
					}(this));
					var msg = "Macro call " + m + "(" + plstr + ") failed (" + Std.string(e1) + ")";
					throw msg;
				}
			}
		}
	}break;
	}
}
haxe.Template.prototype.stack = null;
haxe.Template.prototype.__class__ = haxe.Template;
haxe.Firebug = function() { }
haxe.Firebug.__name__ = ["haxe","Firebug"];
haxe.Firebug.detect = function() {
	try {
		return console != null && console.error != null;
	}
	catch( $e13 ) {
		{
			var e = $e13;
			{
				return false;
			}
		}
	}
}
haxe.Firebug.redirectTraces = function() {
	haxe.Log.trace = $closure(haxe.Firebug,"trace");
	js.Lib.setErrorHandler($closure(haxe.Firebug,"onError"));
}
haxe.Firebug.onError = function(err,stack) {
	var buf = err + "\n";
	{
		var _g = 0;
		while(_g < stack.length) {
			var s = stack[_g];
			++_g;
			buf += "Called from " + s + "\n";
		}
	}
	haxe.Firebug.trace(buf,null);
	return true;
}
haxe.Firebug.trace = function(v,inf) {
	var type = (inf != null && inf.customParams != null?inf.customParams[0]:null);
	if(type != "warn" && type != "info" && type != "debug" && type != "error") type = (inf == null?"error":"log");
	console[type](((inf == null?"":inf.fileName + ":" + inf.lineNumber + " : ")) + Std.string(v));
}
haxe.Firebug.prototype.__class__ = haxe.Firebug;
IntIter = function(min,max) { if( min === $_ ) return; {
	this.min = min;
	this.max = max;
}}
IntIter.__name__ = ["IntIter"];
IntIter.prototype.hasNext = function() {
	return this.min < this.max;
}
IntIter.prototype.max = null;
IntIter.prototype.min = null;
IntIter.prototype.next = function() {
	return this.min++;
}
IntIter.prototype.__class__ = IntIter;
Std = function() { }
Std.__name__ = ["Std"];
Std["is"] = function(v,t) {
	return js.Boot.__instanceof(v,t);
}
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
}
Std["int"] = function(x) {
	if(x < 0) return Math.ceil(x);
	return Math.floor(x);
}
Std.parseInt = function(x) {
	var v = parseInt(x);
	if(Math.isNaN(v)) return null;
	return v;
}
Std.parseFloat = function(x) {
	return parseFloat(x);
}
Std.random = function(x) {
	return Math.floor(Math.random() * x);
}
Std.prototype.__class__ = Std;
Lambda = function() { }
Lambda.__name__ = ["Lambda"];
Lambda.array = function(it) {
	var a = new Array();
	{ var $it14 = it.iterator();
	while( $it14.hasNext() ) { var i = $it14.next();
	a.push(i);
	}}
	return a;
}
Lambda.list = function(it) {
	var l = new List();
	{ var $it15 = it.iterator();
	while( $it15.hasNext() ) { var i = $it15.next();
	l.add(i);
	}}
	return l;
}
Lambda.map = function(it,f) {
	var l = new List();
	{ var $it16 = it.iterator();
	while( $it16.hasNext() ) { var x = $it16.next();
	l.add(f(x));
	}}
	return l;
}
Lambda.mapi = function(it,f) {
	var l = new List();
	var i = 0;
	{ var $it17 = it.iterator();
	while( $it17.hasNext() ) { var x = $it17.next();
	l.add(f(i++,x));
	}}
	return l;
}
Lambda.has = function(it,elt,cmp) {
	if(cmp == null) {
		{ var $it18 = it.iterator();
		while( $it18.hasNext() ) { var x = $it18.next();
		if(x == elt) return true;
		}}
	}
	else {
		{ var $it19 = it.iterator();
		while( $it19.hasNext() ) { var x = $it19.next();
		if(cmp(x,elt)) return true;
		}}
	}
	return false;
}
Lambda.exists = function(it,f) {
	{ var $it20 = it.iterator();
	while( $it20.hasNext() ) { var x = $it20.next();
	if(f(x)) return true;
	}}
	return false;
}
Lambda.foreach = function(it,f) {
	{ var $it21 = it.iterator();
	while( $it21.hasNext() ) { var x = $it21.next();
	if(!f(x)) return false;
	}}
	return true;
}
Lambda.iter = function(it,f) {
	{ var $it22 = it.iterator();
	while( $it22.hasNext() ) { var x = $it22.next();
	f(x);
	}}
}
Lambda.filter = function(it,f) {
	var l = new List();
	{ var $it23 = it.iterator();
	while( $it23.hasNext() ) { var x = $it23.next();
	if(f(x)) l.add(x);
	}}
	return l;
}
Lambda.fold = function(it,f,first) {
	{ var $it24 = it.iterator();
	while( $it24.hasNext() ) { var x = $it24.next();
	first = f(x,first);
	}}
	return first;
}
Lambda.count = function(it) {
	var n = 0;
	{ var $it25 = it.iterator();
	while( $it25.hasNext() ) { var _ = $it25.next();
	++n;
	}}
	return n;
}
Lambda.empty = function(it) {
	return !it.iterator().hasNext();
}
Lambda.prototype.__class__ = Lambda;
List = function(p) { if( p === $_ ) return; {
	this.length = 0;
}}
List.__name__ = ["List"];
List.prototype.add = function(item) {
	var x = [item];
	if(this.h == null) this.h = x;
	else this.q[1] = x;
	this.q = x;
	this.length++;
}
List.prototype.clear = function() {
	this.h = null;
	this.q = null;
	this.length = 0;
}
List.prototype.filter = function(f) {
	var l2 = new List();
	var l = this.h;
	while(l != null) {
		var v = l[0];
		l = l[1];
		if(f(v)) l2.add(v);
	}
	return l2;
}
List.prototype.first = function() {
	return (this.h == null?null:this.h[0]);
}
List.prototype.h = null;
List.prototype.isEmpty = function() {
	return (this.h == null);
}
List.prototype.iterator = function() {
	return { h : this.h, hasNext : function() {
		return (this.h != null);
	}, next : function() {
		if(this.h == null) return null;
		var x = this.h[0];
		this.h = this.h[1];
		return x;
	}}
}
List.prototype.join = function(sep) {
	var s = new StringBuf();
	var first = true;
	var l = this.h;
	while(l != null) {
		if(first) first = false;
		else s.b[s.b.length] = sep;
		s.b[s.b.length] = l[0];
		l = l[1];
	}
	return s.b.join("");
}
List.prototype.last = function() {
	return (this.q == null?null:this.q[0]);
}
List.prototype.length = null;
List.prototype.map = function(f) {
	var b = new List();
	var l = this.h;
	while(l != null) {
		var v = l[0];
		l = l[1];
		b.add(f(v));
	}
	return b;
}
List.prototype.pop = function() {
	if(this.h == null) return null;
	var x = this.h[0];
	this.h = this.h[1];
	if(this.h == null) this.q = null;
	this.length--;
	return x;
}
List.prototype.push = function(item) {
	var x = [item,this.h];
	this.h = x;
	if(this.q == null) this.q = x;
	this.length++;
}
List.prototype.q = null;
List.prototype.remove = function(v) {
	var prev = null;
	var l = this.h;
	while(l != null) {
		if(l[0] == v) {
			if(prev == null) this.h = l[1];
			else prev[1] = l[1];
			if(this.q == l) this.q = prev;
			this.length--;
			return true;
		}
		prev = l;
		l = l[1];
	}
	return false;
}
List.prototype.toString = function() {
	var s = new StringBuf();
	var first = true;
	var l = this.h;
	s.b[s.b.length] = "{";
	while(l != null) {
		if(first) first = false;
		else s.b[s.b.length] = ", ";
		s.b[s.b.length] = Std.string(l[0]);
		l = l[1];
	}
	s.b[s.b.length] = "}";
	return s.b.join("");
}
List.prototype.__class__ = List;
tools = {}
tools.haxelib = {}
tools.haxelib.Status = { __ename__ : ["tools","haxelib","Status"], __constructs__ : ["OK_USER","OK_PROJECT","OK_PROJECTS","OK_SEARCH","OK_LICENSES","OK_REGISTER","OK_SUBMIT","OK_ACCOUNT","OK_SERVERINFO","OK_REMINDER","ERR_REMINDER","ERR_LICENSE","ERR_UNKNOWN","ERR_NOTHANDLED","ERR_PASSWORD","ERR_EMAIL","ERR_DEVELOPER","ERR_HAXELIBJSON","ERR_USER","ERR_REGISTERED","ERR_PROJECTNOTFOUND"] }
tools.haxelib.Status.ERR_DEVELOPER = ["ERR_DEVELOPER",16];
tools.haxelib.Status.ERR_DEVELOPER.toString = $estr;
tools.haxelib.Status.ERR_DEVELOPER.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_EMAIL = function(which) { var $x = ["ERR_EMAIL",15,which]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.ERR_HAXELIBJSON = ["ERR_HAXELIBJSON",17];
tools.haxelib.Status.ERR_HAXELIBJSON.toString = $estr;
tools.haxelib.Status.ERR_HAXELIBJSON.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_LICENSE = function(info) { var $x = ["ERR_LICENSE",11,info]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.ERR_NOTHANDLED = ["ERR_NOTHANDLED",13];
tools.haxelib.Status.ERR_NOTHANDLED.toString = $estr;
tools.haxelib.Status.ERR_NOTHANDLED.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_PASSWORD = function(which) { var $x = ["ERR_PASSWORD",14,which]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.ERR_PROJECTNOTFOUND = ["ERR_PROJECTNOTFOUND",20];
tools.haxelib.Status.ERR_PROJECTNOTFOUND.toString = $estr;
tools.haxelib.Status.ERR_PROJECTNOTFOUND.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_REGISTERED = ["ERR_REGISTERED",19];
tools.haxelib.Status.ERR_REGISTERED.toString = $estr;
tools.haxelib.Status.ERR_REGISTERED.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_REMINDER = ["ERR_REMINDER",10];
tools.haxelib.Status.ERR_REMINDER.toString = $estr;
tools.haxelib.Status.ERR_REMINDER.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_UNKNOWN = ["ERR_UNKNOWN",12];
tools.haxelib.Status.ERR_UNKNOWN.toString = $estr;
tools.haxelib.Status.ERR_UNKNOWN.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.ERR_USER = function(email) { var $x = ["ERR_USER",18,email]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_ACCOUNT = ["OK_ACCOUNT",7];
tools.haxelib.Status.OK_ACCOUNT.toString = $estr;
tools.haxelib.Status.OK_ACCOUNT.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.OK_LICENSES = function(lics) { var $x = ["OK_LICENSES",4,lics]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_PROJECT = function(pi) { var $x = ["OK_PROJECT",1,pi]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_PROJECTS = function(prj) { var $x = ["OK_PROJECTS",2,prj]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_REGISTER = ["OK_REGISTER",5];
tools.haxelib.Status.OK_REGISTER.toString = $estr;
tools.haxelib.Status.OK_REGISTER.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.OK_REMINDER = ["OK_REMINDER",9];
tools.haxelib.Status.OK_REMINDER.toString = $estr;
tools.haxelib.Status.OK_REMINDER.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.OK_SEARCH = function(si) { var $x = ["OK_SEARCH",3,si]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_SERVERINFO = function(si) { var $x = ["OK_SERVERINFO",8,si]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Status.OK_SUBMIT = ["OK_SUBMIT",6];
tools.haxelib.Status.OK_SUBMIT.toString = $estr;
tools.haxelib.Status.OK_SUBMIT.__enum__ = tools.haxelib.Status;
tools.haxelib.Status.OK_USER = function(ui) { var $x = ["OK_USER",0,ui]; $x.__enum__ = tools.haxelib.Status; $x.toString = $estr; return $x; }
tools.haxelib.Marshall = function() { }
tools.haxelib.Marshall.__name__ = ["tools","haxelib","Marshall"];
tools.haxelib.Marshall.fromJson = function(d) {
	var e;
	if(Reflect.field(d,"PAYLOAD") != null) e = Type.createEnum(tools.haxelib.Status,d.ERR,[d.PAYLOAD]);
	else e = Type.createEnum(tools.haxelib.Status,d.ERR);
	return e;
}
tools.haxelib.Marshall.toJson = function(s) {
	var m = Type.enumConstructor(s);
	return (function($this) {
		var $r;
		var $e = (s);
		switch( $e[1] ) {
		case 0:
		var ui = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : ui});
		}break;
		case 1:
		var info = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : info});
		}break;
		case 2:
		var prjs = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : prjs});
		}break;
		case 3:
		var s1 = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : s1});
		}break;
		case 4:
		var l = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : l});
		}break;
		case 11:
		var l = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : l});
		}break;
		case 18:
		var email = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : email});
		}break;
		case 8:
		var si = $e[2];
		{
			$r = hxjson2.JSON.encode({ ERR : m, PAYLOAD : si});
		}break;
		default:{
			$r = hxjson2.JSON.encode({ ERR : m});
		}break;
		}
		return $r;
	}(this));
}
tools.haxelib.Marshall.prototype.__class__ = tools.haxelib.Marshall;
tools.haxelib.LocalCommand = { __ename__ : ["tools","haxelib","LocalCommand"], __constructs__ : ["LIST","REMOVE","SET","SETUP","CONFIG","PACK","DEV","PATH","RUN","TEST","INSTALL","UPGRADE","NEW","BUILD"] }
tools.haxelib.LocalCommand.BUILD = function(prj) { var $x = ["BUILD",13,prj]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.CONFIG = ["CONFIG",4];
tools.haxelib.LocalCommand.CONFIG.toString = $estr;
tools.haxelib.LocalCommand.CONFIG.__enum__ = tools.haxelib.LocalCommand;
tools.haxelib.LocalCommand.DEV = function(prj,dir) { var $x = ["DEV",6,prj,dir]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.INSTALL = function(prj,ver) { var $x = ["INSTALL",10,prj,ver]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.LIST = ["LIST",0];
tools.haxelib.LocalCommand.LIST.toString = $estr;
tools.haxelib.LocalCommand.LIST.__enum__ = tools.haxelib.LocalCommand;
tools.haxelib.LocalCommand.NEW = ["NEW",12];
tools.haxelib.LocalCommand.NEW.toString = $estr;
tools.haxelib.LocalCommand.NEW.__enum__ = tools.haxelib.LocalCommand;
tools.haxelib.LocalCommand.PACK = function(path) { var $x = ["PACK",5,path]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.PATH = function(paths) { var $x = ["PATH",7,paths]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.REMOVE = function(pkg,ver) { var $x = ["REMOVE",1,pkg,ver]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.RUN = function(param,args) { var $x = ["RUN",8,param,args]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.SET = function(prj,ver) { var $x = ["SET",2,prj,ver]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.SETUP = function(path) { var $x = ["SETUP",3,path]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.TEST = function(pkg) { var $x = ["TEST",9,pkg]; $x.__enum__ = tools.haxelib.LocalCommand; $x.toString = $estr; return $x; }
tools.haxelib.LocalCommand.UPGRADE = ["UPGRADE",11];
tools.haxelib.LocalCommand.UPGRADE.toString = $estr;
tools.haxelib.LocalCommand.UPGRADE.__enum__ = tools.haxelib.LocalCommand;
tools.haxelib.RemoteCommand = { __ename__ : ["tools","haxelib","RemoteCommand"], __constructs__ : ["SEARCH","INFO","USER","REGISTER","SUBMIT","ACCOUNT","LICENSE","PROJECTS","SERVERINFO","REMINDER"] }
tools.haxelib.RemoteCommand.ACCOUNT = function(cemail,cpass,nemail,npass,nname) { var $x = ["ACCOUNT",5,cemail,cpass,nemail,npass,nname]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.INFO = function(project) { var $x = ["INFO",1,project]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.LICENSE = ["LICENSE",6];
tools.haxelib.RemoteCommand.LICENSE.toString = $estr;
tools.haxelib.RemoteCommand.LICENSE.__enum__ = tools.haxelib.RemoteCommand;
tools.haxelib.RemoteCommand.PROJECTS = ["PROJECTS",7];
tools.haxelib.RemoteCommand.PROJECTS.toString = $estr;
tools.haxelib.RemoteCommand.PROJECTS.__enum__ = tools.haxelib.RemoteCommand;
tools.haxelib.RemoteCommand.REGISTER = function(email,password,fullName) { var $x = ["REGISTER",3,email,password,fullName]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.REMINDER = function(email) { var $x = ["REMINDER",9,email]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.SEARCH = function(query) { var $x = ["SEARCH",0,query]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.SERVERINFO = ["SERVERINFO",8];
tools.haxelib.RemoteCommand.SERVERINFO.toString = $estr;
tools.haxelib.RemoteCommand.SERVERINFO.__enum__ = tools.haxelib.RemoteCommand;
tools.haxelib.RemoteCommand.SUBMIT = function(pkgPath) { var $x = ["SUBMIT",4,pkgPath]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.RemoteCommand.USER = function(email) { var $x = ["USER",2,email]; $x.__enum__ = tools.haxelib.RemoteCommand; $x.toString = $estr; return $x; }
tools.haxelib.CmdContext = { __ename__ : ["tools","haxelib","CmdContext"], __constructs__ : ["LOCAL","REMOTE"] }
tools.haxelib.CmdContext.LOCAL = function(l,options) { var $x = ["LOCAL",0,l,options]; $x.__enum__ = tools.haxelib.CmdContext; $x.toString = $estr; return $x; }
tools.haxelib.CmdContext.REMOTE = function(r,options) { var $x = ["REMOTE",1,r,options]; $x.__enum__ = tools.haxelib.CmdContext; $x.toString = $estr; return $x; }
tools.haxelib.Options = function(p) { if( p === $_ ) return; {
	this.switches = new Hash();
}}
tools.haxelib.Options.__name__ = ["tools","haxelib","Options"];
tools.haxelib.Options.prototype.addSwitch = function(k,v) {
	this.switches.set(k,v);
}
tools.haxelib.Options.prototype.addSwitches = function(d) {
	var n = Reflect.copy(d);
	{ var $it26 = this.switches.keys();
	while( $it26.hasNext() ) { var s = $it26.next();
	{
		n[s] = this.switches.get(s);
	}
	}}
	return n;
}
tools.haxelib.Options.prototype.flag = function(s) {
	return this.switches.exists(s);
}
tools.haxelib.Options.prototype.getRepo = function() {
	return this.switches.get("-R");
}
tools.haxelib.Options.prototype.getSwitch = function(s) {
	return this.switches.get(s);
}
tools.haxelib.Options.prototype.gotSome = function() {
	return Lambda.array(this.switches).length > 0;
}
tools.haxelib.Options.prototype.parseSwitches = function(params) {
	{ var $it27 = params.keys();
	while( $it27.hasNext() ) { var o = $it27.next();
	{
		if(StringTools.startsWith(o,"-")) this.switches.set(o,params.get(o));
	}
	}}
}
tools.haxelib.Options.prototype.repo = null;
tools.haxelib.Options.prototype.switches = null;
tools.haxelib.Options.prototype.__class__ = tools.haxelib.Options;
tools.haxelib.Config = function(p) { if( p === $_ ) return; {
	null;
}}
tools.haxelib.Config.__name__ = ["tools","haxelib","Config"];
tools.haxelib.Config.prototype.build = function() {
	return Reflect.field(this.data,tools.haxelib.Config.BUILD);
}
tools.haxelib.Config.prototype.data = null;
tools.haxelib.Config.prototype.file = function() {
	return Reflect.field(this.data,tools.haxelib.Config.FILE);
}
tools.haxelib.Config.prototype.globals = function() {
	return Reflect.field(this.data,tools.haxelib.Config.GLOBAL);
}
tools.haxelib.Config.prototype.pack = function() {
	return Reflect.field(this.data,tools.haxelib.Config.PACK);
}
tools.haxelib.Config.prototype.__class__ = tools.haxelib.Config;
tools.haxelib.ConfigJson = function(j) { if( j === $_ ) return; {
	tools.haxelib.Config.apply(this,[]);
	this.data = hxjson2.JSON.decode(j);
}}
tools.haxelib.ConfigJson.__name__ = ["tools","haxelib","ConfigJson"];
tools.haxelib.ConfigJson.__super__ = tools.haxelib.Config;
for(var k in tools.haxelib.Config.prototype ) tools.haxelib.ConfigJson.prototype[k] = tools.haxelib.Config.prototype[k];
tools.haxelib.ConfigJson.prototype.__class__ = tools.haxelib.ConfigJson;
tools.haxelib.Common = function() { }
tools.haxelib.Common.__name__ = ["tools","haxelib","Common"];
tools.haxelib.Common.slash = function(d) {
	return (StringTools.endsWith(d,"/")?d:(d + "/"));
}
tools.haxelib.Common.safe = function(name) {
	if(!tools.haxelib.Common.alphanum.match(name)) throw "Invalid parameter : " + name;
	return name.split(".").join(",");
}
tools.haxelib.Common.unsafe = function(name) {
	return name.split(",").join(".");
}
tools.haxelib.Common.pkgName = function(lib,ver) {
	return tools.haxelib.Common.safe(lib) + "-" + tools.haxelib.Common.safe(ver) + ".zip";
}
tools.haxelib.Common.camelCase = function(s) {
	if(s.indexOf("-") != -1) {
		var spl = s.split("-"), cc = new StringBuf();
		cc.b[cc.b.length] = spl[0].toLowerCase();
		{
			var _g1 = 1, _g = spl.length;
			while(_g1 < _g) {
				var i = _g1++;
				cc.b[cc.b.length] = spl[i].charAt(0).toUpperCase() + spl[i].substr(1);
			}
		}
		return cc.b.join("");
	}
	return s;
}
tools.haxelib.Common.prototype.__class__ = tools.haxelib.Common;
ValueType = { __ename__ : ["ValueType"], __constructs__ : ["TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"] }
ValueType.TBool = ["TBool",3];
ValueType.TBool.toString = $estr;
ValueType.TBool.__enum__ = ValueType;
ValueType.TClass = function(c) { var $x = ["TClass",6,c]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TEnum = function(e) { var $x = ["TEnum",7,e]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TFloat = ["TFloat",2];
ValueType.TFloat.toString = $estr;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TFunction = ["TFunction",5];
ValueType.TFunction.toString = $estr;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TInt = ["TInt",1];
ValueType.TInt.toString = $estr;
ValueType.TInt.__enum__ = ValueType;
ValueType.TNull = ["TNull",0];
ValueType.TNull.toString = $estr;
ValueType.TNull.__enum__ = ValueType;
ValueType.TObject = ["TObject",4];
ValueType.TObject.toString = $estr;
ValueType.TObject.__enum__ = ValueType;
ValueType.TUnknown = ["TUnknown",8];
ValueType.TUnknown.toString = $estr;
ValueType.TUnknown.__enum__ = ValueType;
Type = function() { }
Type.__name__ = ["Type"];
Type.getClass = function(o) {
	if(o == null) return null;
	if(o.__enum__ != null) return null;
	return o.__class__;
}
Type.getEnum = function(o) {
	if(o == null) return null;
	return o.__enum__;
}
Type.getSuperClass = function(c) {
	return c.__super__;
}
Type.getClassName = function(c) {
	if(c == null) return null;
	var a = c.__name__;
	return a.join(".");
}
Type.getEnumName = function(e) {
	var a = e.__ename__;
	return a.join(".");
}
Type.resolveClass = function(name) {
	var cl;
	try {
		cl = eval(name);
	}
	catch( $e28 ) {
		{
			var e = $e28;
			{
				cl = null;
			}
		}
	}
	if(cl == null || cl.__name__ == null) return null;
	return cl;
}
Type.resolveEnum = function(name) {
	var e;
	try {
		e = eval(name);
	}
	catch( $e29 ) {
		{
			var err = $e29;
			{
				e = null;
			}
		}
	}
	if(e == null || e.__ename__ == null) return null;
	return e;
}
Type.createInstance = function(cl,args) {
	if(args.length <= 3) return new cl(args[0],args[1],args[2]);
	if(args.length > 8) throw "Too many arguments";
	return new cl(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
}
Type.createEmptyInstance = function(cl) {
	return new cl($_);
}
Type.createEnum = function(e,constr,params) {
	var f = Reflect.field(e,constr);
	if(f == null) throw "No such constructor " + constr;
	if(Reflect.isFunction(f)) {
		if(params == null) throw "Constructor " + constr + " need parameters";
		return f.apply(e,params);
	}
	if(params != null && params.length != 0) throw "Constructor " + constr + " does not need parameters";
	return f;
}
Type.createEnumIndex = function(e,index,params) {
	var c = Type.getEnumConstructs(e)[index];
	if(c == null) throw index + " is not a valid enum constructor index";
	return Type.createEnum(e,c,params);
}
Type.getInstanceFields = function(c) {
	var a = Reflect.fields(c.prototype);
	a.remove("__class__");
	return a;
}
Type.getClassFields = function(c) {
	var a = Reflect.fields(c);
	a.remove("__name__");
	a.remove("__interfaces__");
	a.remove("__super__");
	a.remove("prototype");
	return a;
}
Type.getEnumConstructs = function(e) {
	return e.__constructs__;
}
Type["typeof"] = function(v) {
	switch(typeof(v)) {
	case "boolean":{
		return ValueType.TBool;
	}break;
	case "string":{
		return ValueType.TClass(String);
	}break;
	case "number":{
		if(Math.ceil(v) == v % 2147483648.0) return ValueType.TInt;
		return ValueType.TFloat;
	}break;
	case "object":{
		if(v == null) return ValueType.TNull;
		var e = v.__enum__;
		if(e != null) return ValueType.TEnum(e);
		var c = v.__class__;
		if(c != null) return ValueType.TClass(c);
		return ValueType.TObject;
	}break;
	case "function":{
		if(v.__name__ != null) return ValueType.TObject;
		return ValueType.TFunction;
	}break;
	case "undefined":{
		return ValueType.TNull;
	}break;
	default:{
		return ValueType.TUnknown;
	}break;
	}
}
Type.enumEq = function(a,b) {
	if(a == b) return true;
	try {
		if(a[0] != b[0]) return false;
		{
			var _g1 = 2, _g = a.length;
			while(_g1 < _g) {
				var i = _g1++;
				if(!Type.enumEq(a[i],b[i])) return false;
			}
		}
		var e = a.__enum__;
		if(e != b.__enum__ || e == null) return false;
	}
	catch( $e30 ) {
		{
			var e = $e30;
			{
				return false;
			}
		}
	}
	return true;
}
Type.enumConstructor = function(e) {
	return e[0];
}
Type.enumParameters = function(e) {
	return e.slice(2);
}
Type.enumIndex = function(e) {
	return e[1];
}
Type.prototype.__class__ = Type;
js = {}
js.Lib = function() { }
js.Lib.__name__ = ["js","Lib"];
js.Lib.isIE = null;
js.Lib.isOpera = null;
js.Lib.document = null;
js.Lib.window = null;
js.Lib.alert = function(v) {
	alert(js.Boot.__string_rec(v,""));
}
js.Lib.eval = function(code) {
	return eval(code);
}
js.Lib.setErrorHandler = function(f) {
	js.Lib.onerror = f;
}
js.Lib.prototype.__class__ = js.Lib;
js.Boot = function() { }
js.Boot.__name__ = ["js","Boot"];
js.Boot.__unhtml = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
}
js.Boot.__trace = function(v,i) {
	var msg = (i != null?i.fileName + ":" + i.lineNumber + ": ":"");
	msg += js.Boot.__unhtml(js.Boot.__string_rec(v,"")) + "<br/>";
	var d = document.getElementById("haxe:trace");
	if(d == null) alert("No haxe:trace element defined\n" + msg);
	else d.innerHTML += msg;
}
js.Boot.__clear_trace = function() {
	var d = document.getElementById("haxe:trace");
	if(d != null) d.innerHTML = "";
	else null;
}
js.Boot.__closure = function(o,f) {
	var m = o[f];
	if(m == null) return null;
	var f1 = function() {
		return m.apply(o,arguments);
	}
	f1.scope = o;
	f1.method = m;
	return f1;
}
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ != null || o.__ename__ != null)) t = "object";
	switch(t) {
	case "object":{
		if(o instanceof Array) {
			if(o.__enum__ != null) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				{
					var _g1 = 2, _g = o.length;
					while(_g1 < _g) {
						var i = _g1++;
						if(i != 2) str += "," + js.Boot.__string_rec(o[i],s);
						else str += js.Boot.__string_rec(o[i],s);
					}
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			{
				var _g = 0;
				while(_g < l) {
					var i1 = _g++;
					str += ((i1 > 0?",":"")) + js.Boot.__string_rec(o[i1],s);
				}
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		}
		catch( $e31 ) {
			{
				var e = $e31;
				{
					return "???";
				}
			}
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = (o.hasOwnProperty != null);
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) continue;
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__") continue;
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	}break;
	case "function":{
		return "<function>";
	}break;
	case "string":{
		return o;
	}break;
	default:{
		return String(o);
	}break;
	}
}
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	try {
		if(o instanceof cl) {
			if(cl == Array) return (o.__enum__ == null);
			return true;
		}
		if(js.Boot.__interfLoop(o.__class__,cl)) return true;
	}
	catch( $e32 ) {
		{
			var e = $e32;
			{
				if(cl == null) return false;
			}
		}
	}
	switch(cl) {
	case Int:{
		return Math.ceil(o%2147483648.0) === o;
	}break;
	case Float:{
		return typeof(o) == "number";
	}break;
	case Bool:{
		return o === true || o === false;
	}break;
	case String:{
		return typeof(o) == "string";
	}break;
	case Dynamic:{
		return true;
	}break;
	default:{
		if(o == null) return false;
		return o.__enum__ == cl || (cl == Class && o.__name__ != null) || (cl == Enum && o.__ename__ != null);
	}break;
	}
}
js.Boot.__init = function() {
	js.Lib.isIE = (document.all != null && window.opera == null);
	js.Lib.isOpera = (window.opera != null);
	Array.prototype.copy = Array.prototype.slice;
	Array.prototype.insert = function(i,x) {
		this.splice(i,0,x);
	}
	Array.prototype.remove = (Array.prototype.indexOf?function(obj) {
		var idx = this.indexOf(obj);
		if(idx == -1) return false;
		this.splice(idx,1);
		return true;
	}:function(obj) {
		var i = 0;
		var l = this.length;
		while(i < l) {
			if(this[i] == obj) {
				this.splice(i,1);
				return true;
			}
			i++;
		}
		return false;
	});
	Array.prototype.iterator = function() {
		return { cur : 0, arr : this, hasNext : function() {
			return this.cur < this.arr.length;
		}, next : function() {
			return this.arr[this.cur++];
		}}
	}
	var cca = String.prototype.charCodeAt;
	String.prototype.cca = cca;
	String.prototype.charCodeAt = function(i) {
		var x = cca.call(this,i);
		if(isNaN(x)) return null;
		return x;
	}
	var oldsub = String.prototype.substr;
	String.prototype.substr = function(pos,len) {
		if(pos != null && pos != 0 && len != null && len < 0) return "";
		if(len == null) len = this.length;
		if(pos < 0) {
			pos = this.length + pos;
			if(pos < 0) pos = 0;
		}
		else if(len < 0) {
			len = this.length + len - pos;
		}
		return oldsub.apply(this,[pos,len]);
	}
	$closure = js.Boot.__closure;
}
js.Boot.prototype.__class__ = js.Boot;
IntHash = function(p) { if( p === $_ ) return; {
	this.h = {}
	if(this.h.__proto__ != null) {
		this.h.__proto__ = null;
		delete(this.h.__proto__);
	}
	else null;
}}
IntHash.__name__ = ["IntHash"];
IntHash.prototype.exists = function(key) {
	return this.h[key] != null;
}
IntHash.prototype.get = function(key) {
	return this.h[key];
}
IntHash.prototype.h = null;
IntHash.prototype.iterator = function() {
	return { ref : this.h, it : this.keys(), hasNext : function() {
		return this.it.hasNext();
	}, next : function() {
		var i = this.it.next();
		return this.ref[i];
	}}
}
IntHash.prototype.keys = function() {
	var a = new Array();
	
			for( x in this.h )
				a.push(x);
		;
	return a.iterator();
}
IntHash.prototype.remove = function(key) {
	if(this.h[key] == null) return false;
	delete(this.h[key]);
	return true;
}
IntHash.prototype.set = function(key,value) {
	this.h[key] = value;
}
IntHash.prototype.toString = function() {
	var s = new StringBuf();
	s.b[s.b.length] = "{";
	var it = this.keys();
	{ var $it33 = it;
	while( $it33.hasNext() ) { var i = $it33.next();
	{
		s.b[s.b.length] = i;
		s.b[s.b.length] = " => ";
		s.b[s.b.length] = Std.string(this.get(i));
		if(it.hasNext()) s.b[s.b.length] = ", ";
	}
	}}
	s.b[s.b.length] = "}";
	return s.b.join("");
}
IntHash.prototype.__class__ = IntHash;
tools.haxelib.HtmlMacros = function() { }
tools.haxelib.HtmlMacros.__name__ = ["tools","haxelib","HtmlMacros"];
tools.haxelib.HtmlMacros.pkgName = function(resolve,pkg,ver) {
	return tools.haxelib.Common.pkgName(pkg,ver);
}
tools.haxelib.HtmlMacros.prototype.__class__ = tools.haxelib.HtmlMacros;
tools.haxelib.RepoService = function(r) { if( r === $_ ) return; {
	this.repo = r;
}}
tools.haxelib.RepoService.__name__ = ["tools","haxelib","RepoService"];
tools.haxelib.RepoService.prototype.projects = function(cb) {
	tools.haxelib.WebCntrl.doService(this.url("projects",{ }),cb);
}
tools.haxelib.RepoService.prototype.repo = null;
tools.haxelib.RepoService.prototype.serverInfo = function(cb) {
	tools.haxelib.WebCntrl.doService(this.url("serverInfo",{ }),cb);
}
tools.haxelib.RepoService.prototype.url = function(cmd,params) {
	var p, u = this.repo + "?method=" + cmd;
	if(Std["is"](params,String)) {
		p = params;
	}
	else p = JQuery.param(params);
	return ((p.length == 0)?u:u + "&" + p);
}
tools.haxelib.RepoService.prototype.__class__ = tools.haxelib.RepoService;
tools.haxelib.WebCntrl = function(p) { if( p === $_ ) return; {
	if(haxe.Firebug.detect()) haxe.Firebug.redirectTraces();
	else haxe.Log.trace = $closure(tools.haxelib.WebCntrl,"nullTrace");
	tools.haxelib.WebCntrl.setupMacros();
	this.ready();
}}
tools.haxelib.WebCntrl.__name__ = ["tools","haxelib","WebCntrl"];
tools.haxelib.WebCntrl.ctrl = null;
tools.haxelib.WebCntrl.htmlMacros = null;
tools.haxelib.WebCntrl.main = function() {
	tools.haxelib.WebCntrl.ctrl = new tools.haxelib.WebCntrl();
}
tools.haxelib.WebCntrl.status = function(m) {
	new JQuery("#help").html("<div style=\"color:#ff0000\">" + m + "</div>").fadeIn();
}
tools.haxelib.WebCntrl.nullTrace = function(v,inf) {
	null;
}
tools.haxelib.WebCntrl.setupMacros = function() {
	tools.haxelib.WebCntrl.htmlMacros = { }
	{
		var _g = 0, _g1 = Type.getClassFields(tools.haxelib.HtmlMacros);
		while(_g < _g1.length) {
			var f = _g1[_g];
			++_g;
			var fld = Reflect.field(tools.haxelib.HtmlMacros,f);
			if(Reflect.isFunction(fld)) tools.haxelib.WebCntrl.htmlMacros[f] = fld;
		}
	}
}
tools.haxelib.WebCntrl.template = function(tmpl,data) {
	var tmpl1 = StringTools.htmlUnescape(new JQuery(tmpl).get(0).innerHTML), t = new haxe.Template(tmpl1);
	return t.execute(data,tools.haxelib.WebCntrl.htmlMacros);
}
tools.haxelib.WebCntrl.doService = function(url,cb) {
	haxe.Log.trace("service: " + url,{ fileName : "WebCntrl.hx", lineNumber : 114, className : "tools.haxelib.WebCntrl", methodName : "doService"});
	JQuery.getJSON(url,function(data) {
		cb(tools.haxelib.Marshall.fromJson(data));
	});
}
tools.haxelib.WebCntrl.msg = function(m) {
	var d = new JQuery("#dialog");
	d.html(m);
	d.dialog("open");
}
tools.haxelib.WebCntrl.statusHandler = function(s) {
	var $e = (s);
	switch( $e[1] ) {
	case 2:
	var prjs = $e[2];
	{
		haxe.Log.trace(prjs,{ fileName : "WebCntrl.hx", lineNumber : 145, className : "tools.haxelib.WebCntrl", methodName : "statusHandler"});
		new JQuery("#prj-list").html(tools.haxelib.WebCntrl.template("#tmpl-prj-list",{ projects : prjs}));
		

       $('.project').toggle(
             function() { $('.details',$(this)).css({display:'inline'}) ;},
             function() { $('.details',$(this)).css({display:'none'}); });
;
		new JQuery(".details").css({ display : "none"});
	}break;
	default:{
		haxe.Log.trace("nout",{ fileName : "WebCntrl.hx", lineNumber : 156, className : "tools.haxelib.WebCntrl", methodName : "statusHandler"});
	}break;
	}
}
tools.haxelib.WebCntrl.serverInfoHandler = function(s) {
	var $e = (s);
	switch( $e[1] ) {
	case 8:
	var si = $e[2];
	{
		new JQuery("#server-info").html(tools.haxelib.WebCntrl.template("#tmpl-server-info",si));
	}break;
	default:{
		haxe.Log.trace("nout",{ fileName : "WebCntrl.hx", lineNumber : 166, className : "tools.haxelib.WebCntrl", methodName : "serverInfoHandler"});
	}break;
	}
}
tools.haxelib.WebCntrl.prototype.initDialog = function() {
	var d = new JQuery("#dialog");
	d.dialog({ bgiframe : true, autoOpen : false, modal : true, buttons : { Ok : function() {
		d.dialog("close");
	}}});
}
tools.haxelib.WebCntrl.prototype.loadCss = function(path) {
	var jq = new JQuery("link[href*=\"" + path + "\"]");
	if(jq.length == 0) {
		var l = new JQuery("<link/>");
		l.attr({ rel : "stylesheet"});
		l.attr({ type : "text/css"});
		l.attr({ href : path});
		l.appendTo("head");
	}
}
tools.haxelib.WebCntrl.prototype.ready = function() {
	var me = this, rs = new tools.haxelib.RepoService("/repo.php");
	new JQuery("").ready(function() {
		rs.serverInfo($closure(tools.haxelib.WebCntrl,"serverInfoHandler"));
		rs.projects($closure(tools.haxelib.WebCntrl,"statusHandler"));
	});
}
tools.haxelib.WebCntrl.prototype.trace = function(s) {
	if(window.console) {
		window.console.log(s);
	}
	else null;
}
tools.haxelib.WebCntrl.prototype.__class__ = tools.haxelib.WebCntrl;
hxjson2.JSONTokenType = { __ename__ : ["hxjson2","JSONTokenType"], __constructs__ : ["UNKNOWN","COMMA","LEFT_BRACE","RIGHT_BRACE","LEFT_BRACKET","RIGHT_BRACKET","COLON","TRUE","FALSE","NULL","STRING","NUMBER","NAN"] }
hxjson2.JSONTokenType.COLON = ["COLON",6];
hxjson2.JSONTokenType.COLON.toString = $estr;
hxjson2.JSONTokenType.COLON.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.COMMA = ["COMMA",1];
hxjson2.JSONTokenType.COMMA.toString = $estr;
hxjson2.JSONTokenType.COMMA.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.FALSE = ["FALSE",8];
hxjson2.JSONTokenType.FALSE.toString = $estr;
hxjson2.JSONTokenType.FALSE.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.LEFT_BRACE = ["LEFT_BRACE",2];
hxjson2.JSONTokenType.LEFT_BRACE.toString = $estr;
hxjson2.JSONTokenType.LEFT_BRACE.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.LEFT_BRACKET = ["LEFT_BRACKET",4];
hxjson2.JSONTokenType.LEFT_BRACKET.toString = $estr;
hxjson2.JSONTokenType.LEFT_BRACKET.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.NAN = ["NAN",12];
hxjson2.JSONTokenType.NAN.toString = $estr;
hxjson2.JSONTokenType.NAN.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.NULL = ["NULL",9];
hxjson2.JSONTokenType.NULL.toString = $estr;
hxjson2.JSONTokenType.NULL.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.NUMBER = ["NUMBER",11];
hxjson2.JSONTokenType.NUMBER.toString = $estr;
hxjson2.JSONTokenType.NUMBER.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.RIGHT_BRACE = ["RIGHT_BRACE",3];
hxjson2.JSONTokenType.RIGHT_BRACE.toString = $estr;
hxjson2.JSONTokenType.RIGHT_BRACE.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.RIGHT_BRACKET = ["RIGHT_BRACKET",5];
hxjson2.JSONTokenType.RIGHT_BRACKET.toString = $estr;
hxjson2.JSONTokenType.RIGHT_BRACKET.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.STRING = ["STRING",10];
hxjson2.JSONTokenType.STRING.toString = $estr;
hxjson2.JSONTokenType.STRING.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.TRUE = ["TRUE",7];
hxjson2.JSONTokenType.TRUE.toString = $estr;
hxjson2.JSONTokenType.TRUE.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONTokenType.UNKNOWN = ["UNKNOWN",0];
hxjson2.JSONTokenType.UNKNOWN.toString = $estr;
hxjson2.JSONTokenType.UNKNOWN.__enum__ = hxjson2.JSONTokenType;
hxjson2.JSONDecoder = function(s,strict) { if( s === $_ ) return; {
	this.strict = strict;
	this.tokenizer = new hxjson2.JSONTokenizer(s,strict);
	this.nextToken();
	this.value = this.parseValue();
	if(strict && this.nextToken() != null) this.tokenizer.parseError("Unexpected characters left in input stream!");
}}
hxjson2.JSONDecoder.__name__ = ["hxjson2","JSONDecoder"];
hxjson2.JSONDecoder.prototype.getValue = function() {
	return this.value;
}
hxjson2.JSONDecoder.prototype.nextToken = function() {
	return this.token = this.tokenizer.getNextToken();
}
hxjson2.JSONDecoder.prototype.parseArray = function() {
	var a = new Array();
	this.nextToken();
	if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACKET) {
		return a;
	}
	else {
		if(!this.strict && this.token.type == hxjson2.JSONTokenType.COMMA) {
			this.nextToken();
			if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACKET) {
				return a;
			}
			else {
				this.tokenizer.parseError("Leading commas are not supported.  Expecting ']' but found " + this.token.value);
			}
		}
	}
	while(true) {
		a.push(this.parseValue());
		this.nextToken();
		if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACKET) {
			return a;
		}
		else if(this.token.type == hxjson2.JSONTokenType.COMMA) {
			this.nextToken();
			if(!this.strict) {
				if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACKET) {
					return a;
				}
			}
		}
		else {
			this.tokenizer.parseError("Expecting ] or , but found " + this.token.value);
		}
	}
	return null;
}
hxjson2.JSONDecoder.prototype.parseObject = function() {
	var o = { }
	var key;
	this.nextToken();
	if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACE) {
		return o;
	}
	else {
		if(!this.strict && this.token.type == hxjson2.JSONTokenType.COMMA) {
			this.nextToken();
			if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACE) {
				return o;
			}
			else {
				this.tokenizer.parseError("Leading commas are not supported.  Expecting '}' but found " + this.token.value);
			}
		}
	}
	while(true) {
		if(this.token.type == hxjson2.JSONTokenType.STRING) {
			key = Std.string(this.token.value);
			this.nextToken();
			if(this.token.type == hxjson2.JSONTokenType.COLON) {
				this.nextToken();
				o[key] = this.parseValue();
				this.nextToken();
				if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACE) {
					return o;
				}
				else if(this.token.type == hxjson2.JSONTokenType.COMMA) {
					this.nextToken();
					if(!this.strict) {
						if(this.token.type == hxjson2.JSONTokenType.RIGHT_BRACE) {
							return o;
						}
					}
				}
				else {
					this.tokenizer.parseError("Expecting } or , but found " + this.token.value);
				}
			}
			else {
				this.tokenizer.parseError("Expecting : but found " + this.token.value);
			}
		}
		else {
			this.tokenizer.parseError("Expecting string but found " + this.token.value);
		}
	}
	return null;
}
hxjson2.JSONDecoder.prototype.parseValue = function() {
	if(this.token == null) this.tokenizer.parseError("Unexpected end of input");
	var $e = (this.token.type);
	switch( $e[1] ) {
	case 2:
	{
		return this.parseObject();
	}break;
	case 4:
	{
		return this.parseArray();
	}break;
	case 10:
	{
		return this.token.value;
	}break;
	case 11:
	{
		return this.token.value;
	}break;
	case 7:
	{
		return true;
	}break;
	case 8:
	{
		return false;
	}break;
	case 9:
	{
		return null;
	}break;
	case 12:
	{
		if(!this.strict) return this.token.value;
		else this.tokenizer.parseError("Unexpected " + this.token.value);
	}break;
	default:{
		this.tokenizer.parseError("Unexpected " + this.token.value);
	}break;
	}
	return null;
}
hxjson2.JSONDecoder.prototype.strict = null;
hxjson2.JSONDecoder.prototype.token = null;
hxjson2.JSONDecoder.prototype.tokenizer = null;
hxjson2.JSONDecoder.prototype.value = null;
hxjson2.JSONDecoder.prototype.__class__ = hxjson2.JSONDecoder;
Hash = function(p) { if( p === $_ ) return; {
	this.h = {}
	if(this.h.__proto__ != null) {
		this.h.__proto__ = null;
		delete(this.h.__proto__);
	}
	else null;
}}
Hash.__name__ = ["Hash"];
Hash.prototype.exists = function(key) {
	try {
		key = "$" + key;
		return this.hasOwnProperty.call(this.h,key);
	}
	catch( $e34 ) {
		{
			var e = $e34;
			{
				
				for(var i in this.h)
					if( i == key ) return true;
			;
				return false;
			}
		}
	}
}
Hash.prototype.get = function(key) {
	return this.h["$" + key];
}
Hash.prototype.h = null;
Hash.prototype.iterator = function() {
	return { ref : this.h, it : this.keys(), hasNext : function() {
		return this.it.hasNext();
	}, next : function() {
		var i = this.it.next();
		return this.ref["$" + i];
	}}
}
Hash.prototype.keys = function() {
	var a = new Array();
	
			for(var i in this.h)
				a.push(i.substr(1));
		;
	return a.iterator();
}
Hash.prototype.remove = function(key) {
	if(!this.exists(key)) return false;
	delete(this.h["$" + key]);
	return true;
}
Hash.prototype.set = function(key,value) {
	this.h["$" + key] = value;
}
Hash.prototype.toString = function() {
	var s = new StringBuf();
	s.b[s.b.length] = "{";
	var it = this.keys();
	{ var $it35 = it;
	while( $it35.hasNext() ) { var i = $it35.next();
	{
		s.b[s.b.length] = i;
		s.b[s.b.length] = " => ";
		s.b[s.b.length] = Std.string(this.get(i));
		if(it.hasNext()) s.b[s.b.length] = ", ";
	}
	}}
	s.b[s.b.length] = "}";
	return s.b.join("");
}
Hash.prototype.__class__ = Hash;
hxjson2.JSON = function() { }
hxjson2.JSON.__name__ = ["hxjson2","JSON"];
hxjson2.JSON.encode = function(o) {
	return new hxjson2.JSONEncoder(o).getString();
}
hxjson2.JSON.decode = function(s,strict) {
	if(strict == null) strict = true;
	return new hxjson2.JSONDecoder(s,strict).getValue();
}
hxjson2.JSON.prototype.__class__ = hxjson2.JSON;
$Main = function() { }
$Main.__name__ = ["@Main"];
$Main.prototype.__class__ = $Main;
$_ = {}
js.Boot.__res = {}
js.Boot.__init();
{
	var JQuery = window.jQuery;;
}
{
	String.prototype.__class__ = String;
	String.__name__ = ["String"];
	Array.prototype.__class__ = Array;
	Array.__name__ = ["Array"];
	Int = { __name__ : ["Int"]}
	Dynamic = { __name__ : ["Dynamic"]}
	Float = Number;
	Float.__name__ = ["Float"];
	Bool = { __ename__ : ["Bool"]}
	Class = { __name__ : ["Class"]}
	Enum = { }
	Void = { __ename__ : ["Void"]}
}
{
	Math.NaN = Number["NaN"];
	Math.NEGATIVE_INFINITY = Number["NEGATIVE_INFINITY"];
	Math.POSITIVE_INFINITY = Number["POSITIVE_INFINITY"];
	Math.isFinite = function(i) {
		return isFinite(i);
	}
	Math.isNaN = function(i) {
		return isNaN(i);
	}
	Math.__name__ = ["Math"];
}
{
	js.Lib.document = document;
	js.Lib.window = window;
	onerror = function(msg,url,line) {
		var f = js.Lib.onerror;
		if( f == null )
			return false;
		return f(msg,[url+":"+line]);
	}
}
haxe.Template.splitter = new EReg("(::[A-Za-z0-9_ ()&|!+=/><*.\"-]+::|\\$\\$([A-Za-z0-9_-]+)\\()","");
haxe.Template.expr_splitter = new EReg("(\\(|\\)|[ \\r\\n\\t]*\"[^\"]*\"[ \\r\\n\\t]*|[!+=/><*.&|-]+)","");
haxe.Template.expr_trim = new EReg("^[ ]*([^ ]+)[ ]*$","");
haxe.Template.expr_int = new EReg("^[0-9]+$","");
haxe.Template.expr_float = new EReg("^([+-]?)(?=\\d|,\\d)\\d*(,\\d*)?([Ee]([+-]?\\d+))?$","");
haxe.Template.globals = { }
tools.haxelib.Config.GLOBAL = "global";
tools.haxelib.Config.BUILD = "build";
tools.haxelib.Config.FILE = "file";
tools.haxelib.Config.PACK = "pack";
tools.haxelib.Common.CONFIG_FILE = "haxelib.json";
tools.haxelib.Common.HXP_FILE = "Hxpfile";
tools.haxelib.Common.alphanum = new EReg("^[A-Za-z0-9_.-]+$","");
js.Lib.onerror = null;
$Main.init = tools.haxelib.WebCntrl.main();
