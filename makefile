#
pkg_files := $(wildcard */*.pkg)
pkg_build_rules.mk : $(pkg_files)
	find | grep .pkg | xargs cat | grep "^d :" | sed "s/^d ://g" > pkg_build_rules.mk

include pkg_build_rules.mk
