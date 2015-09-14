#http://www.stata.com/plugins/#sect5a (a bit out of date)
#Add mingw and mingw64-x86_64 and cygwin32 cygwin packages (since i'm on Cygwin64)

.PHONY: all clean install

#synth2opt.mac, see http://stackoverflow.com/questions/693952/how-to-compile-for-os-x-in-linux-or-windows

ifeq ($(OS),Windows_NT)
all : synth2opt.win64 synth2opt.win32
else
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
all : synth2opt.mac
else
all : synth2opt.linux64 synth2opt.linux32
endif
endif

synth2opt.linux64: synth2opt.cpp
	g++ -fPIC -DSYSTEM=OPUNIX -c -O3 pr_loqo.c
	g++ -fPIC -DSYSTEM=OPUNIX -c -O3 synth2opt.cpp
	g++ -fPIC -DSYSTEM=OPUNIX -c -O3 stplugin.c
	g++ -fPIC -shared -O3 pr_loqo.o stplugin.o synth2opt.o -o synth2opt.linux64
	
synth2opt.linux32: synth2opt.cpp
	g++ -fPIC -DSYSTEM=OPUNIX -m32 -c -O3 pr_loqo.c
	g++ -fPIC -DSYSTEM=OPUNIX -m32 -c -O3 synth2opt.cpp
	g++ -fPIC -DSYSTEM=OPUNIX -m32 -c -O3 stplugin.c
	g++ -fPIC -m32 -shared -O3 pr_loqo.o stplugin.o synth2opt.o -o synth2opt.linux32

#For win* builds, putting all on one resulted in unresolved symbol from pr_loqo when imported
synth2opt.win64: synth2opt.cpp
	x86_64-w64-mingw32-g++ -c -O3 pr_loqo.c
	x86_64-w64-mingw32-g++ -c -O3 synth2opt.cpp
	x86_64-w64-mingw32-g++ -c -O3 stplugin.c
	x86_64-w64-mingw32-g++ -static -shared -O3 pr_loqo.o stplugin.o synth2opt.o -o synth2opt.win64

#i686-pc-mingw32-g++ (alternate mingw for 32 bit)
#Haven't checked these (don't have a 32 bit stata.
synth2opt.win32: synth2opt.cpp
	i686-w64-mingw32-g++ -c -O3 pr_loqo.c
	i686-w64-mingw32-g++ -c -O3 synth2opt.cpp
	i686-w64-mingw32-g++ -c -O3 stplugin.c
	i686-w64-mingw32-g++ -static -shared -O3 pr_loqo.o stplugin.o synth2opt.o -o synth2opt.win32


synth2opt.mac : synth2opt.cpp
	clang++ -DSYSTEM=APPLEMAC -c -O3 pr_loqo.c
	clang++ -DSYSTEM=APPLEMAC -c -O3 synth2opt.cpp
	clang++ -DSYSTEM=APPLEMAC -c -O3 stplugin.c
	clang++ -DSYSTEM=APPLEMAC -shared -O3 pr_loqo.o stplugin.o synth2opt.o -o synth2opt.mac

clean:
	-rm -f synth2opt.win* synth2opt.lin* synth2opt.mac *.o

install:
	-cp synth2opt.win* ../../s/
	-cp synth2opt.linux* ../../s/
	-cp synth2opt.mac ../../s/
