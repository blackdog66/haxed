
package tests;

//import hxjson2.JSON;

import utest.Assert;
import utest.Runner;
import utest.ui.text.TraceReport;

import tests.Parse;
import tests.TestConfigs;
import tests.TestCli;

class Tests {
    
  static function main(){
    var r = new Runner();
    r.addCase(new Parse());
    r.addCase(new PackageTests());
    r.addCase(new TestConfigs());
    r.addCase(new TestCli());
    var report = new TraceReport(r);
    r.run();
  }
}
