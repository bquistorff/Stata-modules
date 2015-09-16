# Makefile to build anything needed for modules
# It compiles mlibs in the base folder allows for more complicated stuff in sub-folders
# Note: You probably want to compile mlibs in an older version of Stata so 
#  they are more portable.

DIRS = synth2

lperm_inference.mlib : perm_inference.mata
	../bin/statab.sh do cli_build_mlib.do "$@ $^"

.PHONY : all install clean

all: lperm_inference.mlib
	for d in $(DIRS); do (cd $$d && $(MAKE) all); done
	
install:
	cp l*.mlib ../l
	for d in $(DIRS); do (cd $$d && $(MAKE) install); done

clean:
	rm -f *.mlib
	for d in $(DIRS); do (cd $$d && $(MAKE) clean); done
