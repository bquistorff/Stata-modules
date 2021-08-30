
#SHELL := /bin/bash

pkg_files := $(wildcard */*.pkg)
toc_files := $(wildcard */*.toc)

.PHONY : all install clean check_pkg_files check_stata_code check_smcl

all : stata.trk pkg_list.txt check_pkg_files check_stata_code check_smcl
	cd src && $(MAKE) all

install : 
	cd src && $(MAKE) install
	
clean : 
	cd src && $(MAKE) clean

test:
	cd tests && $(MAKE) test

stata.trk : $(pkg_files)
	bin/gen_stata.trk.sh

# Make sure all the toc_files have empty line at the end or a "v 3" will get added (can search this to check)
pkg_list.txt : $(toc_files)
	bin/gen_pkg_list.sh

#See http://www.statalist.org/forums/forum/general-stata-discussion/general/6850-text-goes-missing-in-sthlp-file where it says that lines shouldn't be longer than 244
check_smcl :
	grep -r --include "*.sthlp" '.\{245\}'
	#Also -help usersite- says "The text listed on the second and subsequent d lines in both stata.toc and pkgname.pkg may contain SMCL as long as you include v 3 (or v 2)"


.PHONY : ados_witout_version pkgs_without_distr pkgs_not_in_toc ados_missing_tempname
check_pkg_files : pkgs_without_distr pkgs_not_in_toc
check_stata_code : ados_witout_version ados_missing_tempname

ados_witout_version :
	@echo Should use version unless you work with c\(stata_version\) \(like save12\)
	X=$$(find . -name "*.ado" | grep -v "save12" | xargs grep -L -P '^\s*version'); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 

#Ideally check for other named things like graph names.
ados_missing_tempname :
	@echo Checking or ados with missing tempname and instead use globals
	X=$$(grep "file open [^\`]" */*.ado); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	X=$$(grep "^\s\+\(qui \)\?scalar [^\`]" */*.ado | grep -v "scalar define \`"); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 
	X=$$(grep "^\s\+mat\(rix\)\? [^\`\$$]" */*.ado | grep -v "\(row\|col\)\(n\(ames\?\)\?\|eq\)" | grep -v " li\(st\)\?" | grep -v " drop" | grep -v " input [\`\$$]"); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 

pkgs_without_distr :
	@echo Checking for packages without distribution dates
	X=$$(grep -L "Distribution-Date" */*.pkg); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ] 

pkgs_not_in_toc :
	@echo checking for package files not in *.toc files
	trap 'rm -f temp.txt temp2.txt' EXIT; cat */*.toc | grep "^p " | sed -e 's|p \([^ ]\+\).\+|\1|g' | sort > temp.txt && find */*.pkg | sed -e "s|..\(.\+\).pkg|\1|g" | sort > temp2.txt && diff temp.txt temp2.txt