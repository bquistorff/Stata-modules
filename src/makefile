# Makefile to build anything needed for modules
# Right now that is just compiling mlibs
# but could in the future be compiling plugins.

.PHONY : build install

build: lperm_inference.mlib

lperm_inference.mlib : perm_inference.mata
	statab.sh do cli_build_mlib.do "$@ $^"
	
install:
	cp l*.mlib ../l
