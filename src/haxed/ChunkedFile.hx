
package haxed;

import neko.io.File;

class ChunkedFile implements Reader {
  public static var BUF_SIZE=1024;
  var f:neko.io.FileInput;
  var buf:haxe.io.Bytes;
  var len:Int;
  var totalRead:Int;
  var curChunk:Int;
  var eof:Bool;
  
  public function new(file:String) {
    f = neko.io.File.read(file,false);
    eof = false;
    buf = haxe.io.Bytes.alloc(BUF_SIZE);
    totalRead = 0;
    bufferChunk(0);
  }

  function
  bufferChunk(chunk) {
    f.seek(chunk*BUF_SIZE,SeekBegin);
    curChunk = chunk;

    if (f.eof()) {
      f.close();
      return -1;
    }

    //trace("getting chunk "+chunk);
    len = f.readBytes(buf,0,BUF_SIZE);
    
    totalRead += len;
    return len;
  }

  public function
  charAt(i:Int) {

    if (eof) return "EOF";
    
    var
      pos = i % BUF_SIZE,
      chunk = Math.floor(i / BUF_SIZE);

    if (chunk != curChunk) {
      if (bufferChunk(chunk) == -1)
        eof = true;
    }
    
    if (pos < len) {
      return String.fromCharCode(buf.get(pos));
    } else {
      eof = true;
      f.close();
    }

    return "EOF";
  }

  public function
  atEof() {
    return eof;
  }

}
