
package tests;

//import hxjson2.JSON;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

import tests.TestParse;
import tests.TestConfigs;
import tests.TestCli;
import tests.TestSubmit;

class Tests {
    
  static function main(){
    var r = new Runner();
    
    r.addCase(new TestParse());

    r.addCase(new TestConfigs());
    r.addCase(new TestPackage());
    r.addCase(new TestCli());
    
    var report = new TraceReport(r);
    r.run();
    neko.Sys.sleep(5);

    var r3 = new Runner() ;
    r3.addCase(new TestZip());
    report = new TraceReport(r3);
    r3.run();
    
    var r2 = new Runner();
    r2.addCase(new TestSubmit());
    report = new TraceReport(r2);
    r2.run();

    neko.Sys.sleep(3);

    var r4 = new Runner() ;
    r4.addCase(new TestPostSubmit());
    report = new TraceReport(r4);
    r4.run();
    

  }
}
