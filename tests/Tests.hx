
package tests;

//import hxjson2.JSON;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

import tests.TestParse;
import tests.TestConfigs;
import tests.TestCli;

class Tests {
    
  static function main(){
    var r = new Runner();
    r.addCase(new TestParse());
    r.addCase(new PackageTests());
    r.addCase(new TestConfigs());
    r.addCase(new TestCli());
    var report = new TraceReport(r);
    r.run();
    neko.Sys.sleep(5);

    var r2 = new Runner();
    r2.addCase(new TestSubmit());
    report = new TraceReport(r2);
    r2.run();

    neko.Sys.sleep(10);
  }
}
