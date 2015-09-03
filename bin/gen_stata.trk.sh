#!/usr/bin/bash
# If you want to use the repo as and ADO dir then make the file yourself 
# (since you can't have Stata create it by installing from somewhere)

echo "* 00000012" > stata.trk
echo "*! version 1.0.0" >> stata.trk

COUNTER=0
date=$(date +"%d %b %y")
for filename in */*.pkg; do
	base=$(basename $filename)
	dir=$(dirname $filename)
	echo "S https://raw.github.com/bquistorff/Stata-modules/master/$dir" >> stata.trk
	echo "N $base" >> stata.trk
	echo "D $date" >> stata.trk
	echo "U $COUNTER" >> stata.trk
	cat $filename | grep "^d " >> stata.trk
	#change file paths from relative to pkg, to relative to base
	cat $filename | grep "^f " | sed -e "s|^f \.\./|f |g" -e "s|^f \(.[^/]\)|f $dir/\1|g" >> stata.trk
	echo "e" >> stata.trk
	COUNTER=$((COUNTER + 1))
done
