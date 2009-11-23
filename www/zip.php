<?php


$zip = zip_open("/home/blackdog/Projects/haxelib/repo/woot.zip");

  // find entry
do {
  $entry = zip_read($zip);
 } while ($entry && zip_entry_name($entry) != "project-name.xml");


print("entry is $entry");
// open entry
zip_entry_open($zip, $entry, "r");

// read entry
$entry_content = zip_entry_read($entry, zip_entry_filesize($entry));

print($entry_content);

?>