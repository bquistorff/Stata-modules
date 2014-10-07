#!/bin/bash
#make a package-specific makefile

# For now get the platform name from the environment STATA_PLATFORM
# The platform names are:
# WIN (32-bit x86) and WIN64A (64-bit x86-64) for Windows; 
# MACINTEL (32-bit Intel, GUI), OSX.X86 (32-bit Intel, console), MACINTEL64 (64-bit Intel, GUI), OSX.X8664 (64-bit Intel, console), MAC (32-bit PowerPC), and OSX.PPC (32-bit PowerPC), for Mac; 
# LINUX (32-bit x86), LINUX64 (64-bit x86-64), SOL64, and SOLX8664 (64-bit x86-64) for Unix.
# To do: generate this automatically

# Currently only dealing with locally installable files
# (f,g) not the system installable files (F,G)
# Also disregarding dtas as those are considered "ancillary" by Stata
# and don't go into ado/<>/ like the other files. Should deal
# better with this.

outfile=makefile
echo "#Generated makefile" > $outfile
echo ".DEFAULT_GOAL := all_modules" >> $outfile

PKGFILES=ado-store/*/*.pkg

for fullfile in $PKGFILES
do
    filename=$(basename "$fullfile") 
    base="${filename%.*}"
    bases="$bases $base"
done

echo .PHONY : all_modules $bases >> $outfile
echo all_modules : $bases >> $outfile

for fullfile in $PKGFILES
do
    filename=$(basename "$fullfile") 
    base="${filename%.*}"
    base_letter=${base:0:1}
    
    targets=$({ cat $fullfile | grep ^f | grep -v .dta | cut -d ' ' --fields 2; cat $fullfile | grep "^g $STATA_PLATFORM " | cut -d ' ' --fields 4; } | sed -e "s:^:ado/$base_letter/:" | paste -sd " ")
    deps=$({ cat $fullfile | grep ^f | grep -v .dta | cut -d ' ' --fields 2; cat $fullfile | grep "^g $STATA_PLATFORM " | cut -d ' ' --fields 3; } | sed -e "s:^:ado-store/$base_letter/:" | paste -sd " ")
    echo $targets : $deps >> $outfile
    echo "	\$\$STATABATCH do cli-install-module.do $base; mv cli-install-module.log ../temp/lastrun" >> $outfile
    echo $base : $targets >> $outfile
    echo -e "\n" >> $outfile
done

