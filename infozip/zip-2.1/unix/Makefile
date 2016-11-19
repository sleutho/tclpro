# Makefile for Zip, ZipNote, ZipCloak and ZipSplit

# what you can make ...
all:
	@echo ''
	@echo 'Make what?  You must say what system to make Zip for--e.g.'
	@echo '"make generic".  Choices: generic, generic_gcc,'
	@echo 'att6300, coherent, cray_v3, minix,'
	@echo 'sco_x286, xenix, zilog.'
	@echo 'See the files install.doc and zip.doc for more information.'
	@echo ''

list:   all

MAKE = make -f unix/Makefile
SHELL = /bin/sh

# (to use the Gnu compiler, change cc to gcc in CC and BIND)
CC = cc
BIND = $(CC)
AS = $(CC) -c
E =
CPP = /lib/cpp

# probably can change this to 'install' if you have it
INSTALL = cp

# target directories - where to install executables and man pages to
prefix = /usr/local
BINDIR = $(prefix)/bin
manext=1
MANDIR = $(prefix)/man/man$(manext)

# flags
#   CFLAGS    flags for C compile
#   LFLAGS1   flags after output file spec, before obj file list
#   LFLAGS2   flags after obj file list (libraries, etc)
CFLAGS = -O -I. -DUNIX
LFLAGS1 =
LFLAGS2 = -s

# object file lists
OBJZ = zip.o zipfile.o zipup.o fileio.o util.o globals.o crypt.o ttyio.o \
       unix.o crc32.o crctab.o
OBJI = deflate.o trees.o bits.o
OBJA =
OBJU = zipfile_.o fileio_.o util_.o globals.o
OBJN = zipnote.o  $(OBJU)
OBJC = zipcloak.o $(OBJU) crctab.o crypt_.o ttyio.o
OBJS = zipsplit.o $(OBJU)

ZIP_H = zip.h ziperr.h tailor.h unix/osdep.h

# suffix rules
.SUFFIXES:
.SUFFIXES: _.o .o .c .doc .1
.c_.o:
	rm -f $*_.c; ln $< $*_.c
	$(CC) -c $(CFLAGS) -DUTIL $*_.c
	rm -f $*_.c
.c.o:
	$(CC) -c $(CFLAGS) $<

.1.doc:
	nroff -man $< | col -b | uniq > $@

# rules for zip, zipnote, zipcloak, zipsplit, and zip.doc.
$(OBJZ): $(ZIP_H)
$(OBJI): $(ZIP_H)
$(OBJN): $(ZIP_H)
$(OBJS): $(ZIP_H)
$(OBJC): $(ZIP_H)
zip.o zipup.o crypt.o ttyio.o bits.o zipcloak.o crypt_.o: crypt.h
zip.o zipup.o zipnote.o zipcloak.o zipsplit.o: revision.h
zip.o crypt.o ttyio.o zipcloak.o crypt_.o: ttyio.h
zipup.o: unix/zipup.h

match.o: match.S
	$(CPP) match.S > _match.s
	$(AS) _match.s
	mv _match.o match.o
	rm -f _match.s

unix.o: unix/unix.c
	$(CC) -c $(CFLAGS) unix/unix.c

ZIPS = zip$E zipnote$E zipsplit$E zipcloak$E

zips: $(ZIPS)
zipsman: zip zipnote zipsplit zipcloak zip.doc

zip$E: $(OBJZ) $(OBJI) $(OBJA)
	$(BIND) -o zip$E $(LFLAGS1) $(OBJZ) $(OBJI) $(OBJA) $(LFLAGS2)
zipnote$E: $(OBJN)
	$(BIND) -o zipnote$E $(LFLAGS1) $(OBJN) $(LFLAGS2)
zipcloak$E: $(OBJC)
	$(BIND) -o zipcloak$E $(LFLAGS1) $(OBJC) $(LFLAGS2)
zipsplit$E: $(OBJS)
	$(BIND) -o zipsplit$E $(LFLAGS1) $(OBJS) $(LFLAGS2)

# install
install:        $(ZIPS)
	$(INSTALL) $(ZIPS) unix/zipgrep $(BINDIR)
	$(INSTALL) man/zip.1 $(MANDIR)/zip.$(manext)
	$(INSTALL) man/zipgrep.1 $(MANDIR)/zipgrep.$(manext)

uninstall:
	-cd $(BINDIR); rm -f $(ZIPS)
	-cd $(MANDIR); rm -f zip.$(manext)

dist:
	zip -u9T zip`sed -e '/VERSION/!d' -e 's/.*"\(.*\)".*/\1/' \
			  -e s/[.]//g -e q revision.h` \
	  `awk '/^Makefile/,/vms_zip.rnh/ {print $$1}' < contents`

flags:  unix/configure
	sh unix/configure "${CC}" "${CFLAGS}"

# These symbols, when #defined using -D have these effects on compilation:
# ZMEM                  - includes C language versions of memset(), memcpy(),
#                         and memcmp() (util.c).
# HAVE_DIRENT_H         - use <dirent.h> instead of <sys/dir.h>
# NODIR                 - for 3B1, which has neither getdents() nor opendir().
# HAVE_NDIR_H           - use <ndir.h> (unix/unix.c).
# HAVE_SYS_DIR_H        - use <sys/dir.h>
# HAVE_SYS_NDIR_H       - use <sys/ndir.h>
# UTIL                  - select routines for utilities (note, cloak, split)
# NO_RMDIR              - remove directories using a system("rmdir ...") call.
# NO_PROTO              - cannot handle ANSI prototypes
# NO_CONST              - cannot handle ANSI const

#               Generic targets:

generic: flags
	eval $(MAKE) zips `cat flags`

generic_gcc:
	$(MAKE) generic CC=gcc CPP="$(CC) -E"

# AT&T 6300 PLUS (don't know yet how to allocate 64K bytes):
att6300:
	$(MAKE) zips LFLAGS1="-Ml" \
	CFLAGS="-DUNIX -I. -O -Ml -DNODIR -DRMDIR -DDYN_ALLOC -DMEDIUM_MEM -DWSIZE=16384"

# Coherent (AS definition not needed for gcc)
coherent:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O -DDIRENT -DASMV" AS="as -gx" \
                     OBJA=match.o

# Cray Unicos 6.1, Standard C compiler 3.0 (all routines except trees.c
# may be compiled with vector3; internal compiler bug in 3.0.2.3 and
# earlier requires vector2 for trees.c)
cray_v3:
	$(MAKE) zips CC="scc" \
                CFLAGS="-DUNIX -I. -O -h vector2 -h scalar3 -DHAVE_DIRENT_H"

# DEC OSF/1
#  with OSF/1 v3.2, default compiler in ANSI mode worked.
# should work with make generic
#dec_osf1:
#	$(MAKE) zips CFLAGS="-DUNIX -I. -O -Olimit 1000 -std"

# Some older OSF/1 versions may need -DOSF to work around bug in errno.h.
# should work with make generic
#dec_osf1_old:
#	$(MAKE) zips CFLAGS="-DUNIX -I. -O -Olimit 1000 -DOSF"

# MINIX 1.5.10 with Bruce Evans 386 patches and gcc/GNU make
minix:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O -DDIRENT -DMINIX" CC=gcc
	chmem =262144 zip


# SCO Xenix 286 release 2.2.3, Development System 2.2.1
sco_x286:
	$(MAKE) zips CFLAGS="-I. -O -LARGE -Mel2 -DRMDIR -DTERMIO -DMEDIUM_MEM \
	  -DWSIZE=16384" LFLAGS1="-LARGE -Mel2" LFLAGS2="-lx -s"

# SCO Xenix
xenix:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O" LFLAGS2="-lx -s"

# zilog zeus 3.21
zilog:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O -DZMEM -DNDIR -DRMDIR" \
                CC="scc -i" BIND="scc"


# clean up after making stuff and installing it
clean:
	rm -f *.o $(ZIPS) flags

###############################################################################
## The following targets are used for developing by the Info-Zip group
## or should be considered as experimental.

# This one's for Mark:
it:
	$(MAKE) zipsman CFLAGS="-DUNIX -I. -O -Wall"\
	LFLAGS2="-s -object" VPATH="${HOME}/Unix/bin"

# and these are for Jean-loup:

gcc_d:
	$(MAKE) zip CFLAGS="-DUNIX -I. -g -DDEBUG -DMMAP" CC=gcc LFLAGS2="-g"
	mv zip zipd

old_gcc:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O -fstrength-reduce" CC=gcc LFLAGS2=""
	strip $(ZIPS)

big_gcc:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O2 -DBIG_MEM -W -Wall" CC=gcc \
                LFLAGS2=""
	strip $(ZIPS)

mmap_gcc:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O2 -DMMAP -W -Wall" CC=gcc LFLAGS2=""
	strip $(ZIPS)

mmap:
	$(MAKE) zips CFLAGS="-DUNIX -I. -O -DMMAP"

# end of Makefile
