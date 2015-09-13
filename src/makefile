# Makefile to build anything needed for modules
# Right now that is just compiling mlibs
# but could in the future be compiling plugins.

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
