#!/bin/bash

# populate two repos with users, package and submit

HL="neko ../client.n"
BD="blackdog@ipowerhouse.com"

cd ..
./to-iph
cd tests

./recreateDB
ssh $BD "cd /home/blackdog/haxelib/tests/ && ./recreateDB"

$HL register -R localhost:8200 blackdog@ipowerhouse.com 12345 12345 ritchie
$HL register -R lib.ipowerhouse.com woot@woot.com wooty wooty wooty

$HL package ./myproject.hbl
$HL package ./test.hbl

$HL submit -R localhost:8200 ./project-name.zip
$HL submit -R lib.ipowerhouse.com ./myproject.zip


$HL install myproject