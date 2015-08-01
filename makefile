# to-do:
# -integrate the get_test_script.sh

pkg_files := $(wildcard */*.pkg)

pkg_build_rules.mk : $(pkg_files)
	cat */*.pkg | grep "^d :" | sed "s/^d ://g" > pkg_build_rules.mk
include pkg_build_rules.mk

stata.trk : $(pkg_files)
	./gen_stata.trk.sh

.PHONY : basic_checks ados_witout_version pkgs_without_distr pkgs_not_in_toc
ados_witout_version :
	@echo Should use version unless you work with c(stata_version) (like save12)
	grep -L -P '^\s*version' */*.ado

pkgs_without_distr :
	grep -L "Distribution-Date" */*.pkg

pkgs_not_in_toc :
	@echo checking for package files not in *.toc files
	cat */*.toc | grep "^p " | sed -e 's|p \([^ ]\+\).\+|\1|g' | sort > temp.txt
	find */*.pkg | sed -e "s|..\(.\+\).pkg|\1|g" | sort > temp2.txt
	diff temp.txt temp2.txt
	-rm temp.txt temp2.txt

basic_checks : ados_witout_version pkgs_without_distr pkgs_not_in_toc