#!/bin/bash
# Example usage
#./store-mod-install-files.sh http://fmwww.bc.edu/repec/bocode/s/synth.pkg ado-store
#Assumes the standard first-letter directory structure.

pkgfilename=$(basename "$1") 
pkgdirpath=$(dirname "$1")
pkgbase="${pkgfilename%.*}"
pkgbase_letter=${pkgbase:0:1}
orig_dir=$PWD

mkdir -p $2/$pkgbase_letter/
cd $2/$pkgbase_letter/

wget $1

files=$({ cat $pkgfilename | grep ^[fF] | cut -d ' ' --fields 2; cat $pkgfilename | grep '^[gG]' | cut -d ' ' --fields 3; })
for f in $files
do
    dirpath=$(dirname "$f")
    mkdir -p $dirpath
    wget $pkgdirpath/$f -P $dirpath
done 

cd $orig_dir
