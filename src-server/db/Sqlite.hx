#if php
/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package db;

import php.db.Connection;
import php.Lib;
import php.NativeArray;
import php.NativeString;

/**
 * PDO::FETCH_COLUMN = 7
 * PDO::FETCH_CLASS = 8
 * PDO::FETCH_INTO = 9
 * PDO::PARAM_STR = 2
 * PDO::FETCH_BOTH = 4
 * PDO::FETCH_ORI_NEXT = 0
 */
extern class PDO 
{
	public function new(dns : String, ?username : String, ?password : String, ?driver_options : NativeArray) : Void;

	public function beginTransaction() : Bool;
	public function commit() : Bool;
	public function errorCode() : Dynamic;
	public function errorInfo() : NativeArray;
	public function exec(statement : String) : Int;
	public function getAttribute(attribute : Int) : Dynamic;
	public function getAvailableDrivers() : NativeArray;
	public function lastInsertId(?name : String) : String;
	// Optional is empty NativeArray, not sure how to implement, but not needed for the SQLite implementation.
	//public function prepare(statement : String, ?driver_options : NativeArray = NativeArray()) : PDOStatement;
	public function query(statement : String, ?mode : Int, ?fetch : Dynamic, ?ctorargs : NativeArray) : PDOStatement;	
	public function quote(String : String, ?parameter_type : Int = 2) : String;
	public function rollBack() : Bool;
	public function setAttribute(attribute : Int, value : Dynamic) : Bool;
}

extern class PDOStatement
{
	public function bindColumn(column : Dynamic, param : Dynamic, ?type : Int, ?maxlen : Int, ?driverdata : Dynamic) : Bool;
	public function bindParam(parameter : Dynamic, variable : Dynamic, ?data_type : Int, ?length : Int, ?driver_options : Dynamic) : Bool;
	public function bindValue(parameter : Dynamic, value : Dynamic, ?data_type : Int) : Bool;
	public function closeCursor() : Bool;
	public function columnCount() : Int;
	public function debugDumpParams() : Bool;
	public function errorCode() : String;
	public function errorInfo() : NativeArray;
	// Optional is empty NativeArray, not sure how to implement, but not needed for the SQLite implementation.
	//public function execute(?input_parameters : NativeArray = NativeArray()) : Bool;
	public function fetch(?fetch_style : Int = 4, ?cursor_orientation : Int = 0, ?cursor_offset : Int = 0) : Dynamic;
	// Optional is empty NativeArray, not sure how to implement, but not needed for the SQLite implementation.
	//public function fetchAll(?fetch_style : Int = 4, ?column_index : Int, ?ctor_args : NativeArray = NativeArray()) : NativeArray;
	public function fetchColumn(?column_number : Int = 0) : String;
	public function fetchObject(?class_name : String, ?ctor_args : NativeArray) : Dynamic;
	public function getAttribute(attribute : Int) : Dynamic;
	public function getColumnMeta(column : Int) : NativeArray;
	public function nextRowset() : Bool;
	public function rowCount() : Int;
	public function setAttribute(attribute : Int, value : Dynamic) : Bool;
	public function setFetchMode(mode : Int, ?fetch : Dynamic, ?ctorargs : NativeArray) : Bool;
}

/////////////////////////////////////////////////////////////////////

private class SqliteConnection implements Connection {

	var pdo : PDO;

	public function new( file : String, ?version2 = false ) {
		pdo = new PDO((version2 ? 'sqlite2' : 'sqlite:') + file);
	}

	public function close() {
		pdo = null;
		untyped __call__("unset", pdo);
	}

	public function request( s : String ) : php.db.ResultSet {
		var result = pdo.query(s);
		if(untyped __physeq__(result, false))
		{
			var info = Lib.toHaxeArray(pdo.errorInfo());
			throw "Error while executing " + s + " (" + info[2] + ")";
		}

		return new SqliteResultSet(result);
	}

	public function escape( s : String ) {
		var output = pdo.quote(s);
		return output.length > 2 ? output.substr(1, output.length-2) : output;
	}

	public function quote( s : String ) {
		if( s.indexOf("\000") >= 0 )
			return "x'"+base16_encode(s)+"'";
		return pdo.quote(s);
	}

	public function addValue( s : StringBuf, v : Dynamic ) {
		if( untyped __call__("is_int", v) || __call__("is_null", v) )
			s.add(v);
		else if( untyped __call__("is_bool", v) )
			s.add(v ? 1 : 0);
		else
			s.add(quote(Std.string(v)));
	}

	public function lastInsertId() {
		return cast(Std.parseInt(pdo.lastInsertId()), Int);
	}

	public function dbName() {
		return "SQLite";
	}

	public function startTransaction() {
		request("BEGIN TRANSACTION");
	}

	public function commit() {
		request("COMMIT");
		startTransaction(); // match mysql usage
	}

	public function rollback() {
		request("ROLLBACK");
		startTransaction(); // match mysql usage
	}

	function base16_encode(str : String) {
		str = untyped __call__("unpack", "H"+(2 * str.length), str);
		str = untyped __call__("chunk_split", untyped str[1]);
		return str;
	}
}


private class SqliteResultSet implements php.db.ResultSet {

	public var length(getLength,null) : Int;
	public var nfields(getNFields,null) : Int;
	var r : PDOStatement;
	var cache : List<Dynamic>;

	public function new( r : PDOStatement ) {
		cache = new List();
		this.r = r;
		hasNext(); // execute the request
	}

	function getLength() {
		if( nfields != 0 ) {
			while( true ) {
				var c = doNext();
				if( c == null )
					break;
				cache.add(c);
			}
			return cache.length;
		}
		return r.rowCount();
	}

	function getNFields() {
		return r.columnCount();
	}

	public function hasNext() {
		var c = next();
		if( c == null )
			return false;
		cache.push(c);
		return true;
	}

	public function next() : Dynamic {
		var c = cache.pop();
		if( c != null )
			return c;
		return doNext();
	}

	private function doNext() : Dynamic {
		var c : Dynamic = r.fetch(2);
		if(untyped __physeq__(c, false))
			return null;
		return untyped __call__("_hx_anonymous", c);
	}

	public function results() : List<Dynamic> {
		var l = new List();
		while( true ) {
			var c = next();
			if( c == null )
				break;
			l.add(c);
		}
		return l;
	}

	public function getResult( n : Int ) : String {
		return Reflect.field(next(), cast n);
	}

	public function getIntResult( n : Int ) : Int {
		return untyped __call__("intval", Reflect.field(next(), cast n));
	}

	public function getFloatResult( n : Int ) : Float {
		return untyped __call__("floatval", Reflect.field(next(), cast n));
	}
}

/**
 * Sqlite version 3 for PHP.
 */
class Sqlite {

	public static function open( file : String ) : Connection {
		return new SqliteConnection(file);
	}

}
#end
