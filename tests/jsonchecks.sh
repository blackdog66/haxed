#!/bin/bash


HL="neko ../client.n"
BD="blackdog@ipowerhouse.com"

function jsoneval(){
    echo "y=eval(`$1`);$2" |js  
}




jsoneval "$HL info -j -all myproject" "print(y.repo)"