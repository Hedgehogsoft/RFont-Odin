CC = gcc

ODIN = odin
CUSTOM_CFLAGS =

LIBS := -w -ggdb
ifeq ($(detected_OS),Windows)
	LIB_EXT = .lib
else
	LIB_EXT = .a
endif

all:
	make lib/RFont$(LIB_EXT)

build-RFont:
	make lib/RFont$(LIB_EXT)

debug:
ifeq ($(detected_OS),Windows)
	make clean
	.\build-libs.bat
	make lib/RFont$(LIB_EXT)
else
	make clean
	make lib/RFont$(LIB_EXT)
endif

source/RFont.o:
	$(CC) -I./source $(CUSTOM_CFLAGS) source/RFont.c -c $(LIBS) -fPIC -o source/RFont.o

lib/RFont$(LIB_EXT):
ifeq ($(detected_OS),Windows)
	.\build.bat
else
	mkdir -p lib
	make source/RFont.o
	$(AR) rcs RFont.a source/RFont.o
	mv RFont.a lib/
endif

clean:
	rm -f RFont.o source/RFont.o
	rm -r -f lib 
	rm -f RFont.obj RFont.lib source/RFont.obj
