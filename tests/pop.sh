#!/bin/bash

# populate two repos with users, package and submit

HLD=~/Projects/haxelib
TD=$HLD/tests

HL="neko $HLD/client.n"
BD="blackdog@ipowerhouse.com"

cd $TD

rm *zip

# update remote php server
../ritchie/to-iph

./recreateDB

# recreate remote db
ssh $BD "cd /home/blackdog/Projects/haxelib/tests/ && ./recreateDB"

echo REGISTERING ....

$HL register -R localhost:8200 blackdog@ipowerhouse.com 12345 12345 ritchie
$HL register -R lib.ipowerhouse.com woot@woot.com wooty wooty wooty

echo SUBMITTING ....

$HL submit -R localhost:8200 ./coolproj.hxp
$HL submit -R lib.ipowerhouse.com ./myproject.hxp
$HL submit -R localhost:8200 ./gtk.hxp
$HL submit -R lib.ipowerhouse.com ./funkylic.hxp


echo INSTALLING ....

$HL install hxGtk