
package haxed;

#if neko
import neko.io.File;
import neko.io.FileInput;
#else
import php.io.File;
import php.io.FileInput;
#end

class ChunkedFile implements Reader {
  public static var BUF_SIZE=1024;
  static var EOF = -1;
  var f:FileInput;
  var buf:haxe.io.Bytes;
  var len:Int;
  var totalRead:Int;
  var curChunk:Int;
  var eof:Bool;
  
  public function new(file:String) {
    f = File.read(file,false);
    eof = false;
    buf = haxe.io.Bytes.alloc(BUF_SIZE);
    totalRead = 0;
    bufferChunk(0);
  }

  function
  bufferChunk(chunk) {
    f.seek(chunk*BUF_SIZE,SeekBegin);
    curChunk = chunk;

    #if neko
    if (f.eof()) {
      f.close();
      return -1;
    }
    #end
    

    //trace("getting chunk "+chunk);
    try {
      len = f.readBytes(buf,0,BUF_SIZE);
    } catch(ex:Dynamic) {
      //      trace("prob at "+chunk+" = "+chunk*1024+" but at "+f.tell());
      eof = true;
    }
    
    totalRead += len;
    return len;
  }

  function
  updateChunk(chunk:Int) {
    if (chunk != curChunk) {
      if (bufferChunk(chunk) == -1)
        eof = true;
    }
  }
  
  public function canChunk() { return true; }

  public function nextChunk():String {
    var b = buf.toString().substr(0,len);
    updateChunk(curChunk+1);
    return b;
  }
  
  public function
  charCodeAt(i:Int):Int {

    if (eof) return EOF;
    
    var
      pos = i % BUF_SIZE,
      chunk = Math.floor(i / BUF_SIZE);

    updateChunk(chunk);
    
    if (pos < len) {
      return buf.get(pos);
    } else {
      eof = true;
      f.close();
    }

    return EOF;
  }

  public inline function
  atEof() {
    return eof;
  }

}
