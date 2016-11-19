# Makefile.pro --
#
#  Scriptics version of the build Makefile for unzip, Win32 version.
#  This is modified version of Makefile, whose header is preserved below.
#  It assumes that it will be called from VC++ 5.0 on NT.
#  The objects for the library are compiled assuming that execs will be
#  linked against the multi-threaded DLLs.
#
# Copyright (c) 1998 by Scriptics Corporation.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: Makefile.pro,v 1.5 1998/07/13 17:43:56 escoffon Exp $
#
# NMAKE Makefile for Windows NT/Windows 95
#   D. Feinleib 7/92 <t-davefe@microsoft.com>
#   H. Gessau 9/93 <henryg@kullmar.kullmar.se>
#   J. Lee 8/95 (johnnyl@microsoft.com)
#
#
# Last revised:  9 Mar 97
#
# Tested with VC++ 2.0 for NT for MIPS and Alpha, Visual C++ 2.2 for Intel CPUs
#

# Nmake macros for building Windows NT applications

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IFNDEF APPVER
APPVER = 4.0
!ENDIF

# To build with debug info use 'nmake NODEBUG=0'
NODEBUG	= 1

TOOLS32_BASE	= c:\progra~1\devstudio
TOOLS32		= $(TOOLS32_BASE)\vc
TOOLS32_rc	= $(TOOLS32_BASE)\sharedide
TOOLS32_HDR_DIR	= $(TOOLS32)\include

ROOTDIR		= ..
GENERICDIR	= $(ROOTDIR)
WIN32DIR	= $(ROOTDIR)\win32
BINROOT		= .

# TARGETOS can be specified to change the target OS bfor the build, but
# leave as is please.
TARGETOS = WINNT

!IF "$(NODEBUG)" == "1"
TMPDIR		= $(BINROOT)\Release
DBGX		=
!ELSE
TMPDIR		= $(BINROOT)\Debug
DBGX		= d
!ENDIF
OUTDIR		= $(TMPDIR)

# the name of the library and executables to generate
UNZIPLIB	= $(OUTDIR)\unzip31$(DBGX).lib
UNZIPEXE	= $(OUTDIR)\unzip.exe
FUNZIPEXE	= $(OUTDIR)\funzip.exe
UNZIPSFXEXE	= $(OUTDIR)\unzipsfx.exe

# object files to place in the library; note how unzip.obj is placed
# in the library, because it allocates space for a number of variables
# used by other parts of the system

LIB32_OBJS= \
	"$(TMPDIR)\unzip.obj" \
	"$(TMPDIR)\api.obj" \
	"$(TMPDIR)\crc32.obj" \
	"$(TMPDIR)\crctab.obj" \
	"$(TMPDIR)\crypt.obj" \
	"$(TMPDIR)\envargs.obj" \
	"$(TMPDIR)\explode.obj" \
	"$(TMPDIR)\extract.obj" \
	"$(TMPDIR)\fileio.obj" \
	"$(TMPDIR)\globals.obj" \
	"$(TMPDIR)\inflate.obj" \
	"$(TMPDIR)\list.obj" \
	"$(TMPDIR)\match.obj" \
	"$(TMPDIR)\nt.obj" \
	"$(TMPDIR)\process.obj" \
	"$(TMPDIR)\ttyio.obj" \
	"$(TMPDIR)\unreduce.obj" \
	"$(TMPDIR)\unshrink.obj" \
	"$(TMPDIR)\win32.obj" \
	"$(TMPDIR)\zipinfo.obj"

#
# Build the compiler flags
#

!IF "$(CPU)" == ""  &&  "$(PROCESSOR_ARCHITECTURE)" == "x86"
CPU = i386
!ENDIF
!IF "$(CPU)" == ""  &&  "$(PROCESSOR_ARCHITECTURE)" == "MIPS"
CPU = $(PROCESSOR_ARCHITECTURE)
!ENDIF
!IF "$(CPU)" == ""  &&  "$(PROCESSOR_ARCHITECTURE)" == "ALPHA"
CPU = $(PROCESSOR_ARCHITECTURE)
!ENDIF
!IF "$(CPU)" == ""  &&  "$(PROCESSOR_ARCHITECTURE)" == "PPC"
CPU = $(PROCESSOR_ARCHITECTURE)
!ENDIF
!IF "$(CPU)" == ""
CPU = i386
!ENDIF

!IF "$(CPU)" == "i386"
ARCH_FLAGS	= -D_X86_=1
!ELSE
!IF "$(CPU)" == "MIPS"
ARCH_FLAGS	= -D_MIPS_=1
!ELSE
!IF "$(CPU)" == "PPC"
ARCH_FLAGS	= -D_PPC_=1
!ELSE
!IF "$(CPU)" == "ALPHA"
ARCH_FLAGS	= -D_ALPHA_=1
!ENDIF
!ENDIF
!ENDIF
!ENDIF

!IF "$(TARGETOS)" == "WINNT"
OS_FLAGS	= -D_WINNT -D_WIN32_WINNT=0x0400 -DWINVER=0x0400
!ELSE
!IF "$(TARGETOS)" == "WIN95"
OS_FLAGS	= -D_WIN95 -D_WIN32_WINDOWS=0x0400 -DWINVER=0x0400
!ENDIF
!ENDIF

# COMMON_FLAGS are switches common to debug/nodebug/optimize/nooptimize

# If DLL is defined, unzpriv.h defines REENTRANT, but then we run into
# inconsistencies in the headers, which show up as the unresolved external
# symbol _G when unzip.exe is created. So define REENTRANT here.

COMMON_CFLAGS	= /nologo /W3 /J \
	/I "$(ROOTDIR)" /I "$(WIN32DIR)" \
	/D WIN32 /D _WIN32 \
	/D UZPFILETREE2 /DNO_ZIPINFO /D REENTRANT \
	/Fo"$(TMPDIR)\\" /Fd"$(TMPDIR)\\" /FD \
	$(ARCH_FLAGS) $(OS_FLAGS)

COMMON_CFLAGS	= /nologo /W3 /J \
	/I "$(TOOLS32_HDR_DIR)" /I "$(ROOTDIR)" /I "$(WIN32DIR)" \
	/D WIN32 /D _WIN32 \
	/D NO_ASM /D UZPFILETREE2 /DNO_ZIPINFO \
	/Fo"$(TMPDIR)\\" /Fd"$(TMPDIR)\\" /FD \
	$(ARCH_FLAGS) $(OS_FLAGS)

OBJ_CFLAGS	= $(COMMON_CFLAGS) /D DLL
EXE_CFLAGS	= $(COMMON_CFLAGS)

LINK_FLAGS	= /NODEFAULTLIB /INCREMENTAL:NO /PDB:NONE /RELEASE /NOLOGO

# DEBUG_CFLAGS are flags that change depending on whether we are turning
# debugging on or off. Similarly for OPTIMIZE_CFLAGS.

!IF "$(NODEBUG)" == "1"
DEBUG_CFLAGS	= /MD /D NDEBUG
OPTIMIZE_CFLAGS	= /O2
!ELSE
DEBUG_CFLAGS	= /MDd /Z7 /D _DEBUG
OPTIMIZE_CFLAGS	= /Od
LINK_FLAGS	= $(LINK_FLAGS) -debug:full -debugtype:cv
!ENDIF

LIB32_FLAGS	= /nologo /out:"$(UNZIPLIB)" 

CON_LINK_FLAGS	= -subsystem:console,$(APPVER)

# libraries against which to link

LIBPATH		= $(TOOLS32)\lib
LINK_LIBS 	= $(UNZIPLIB) user32.lib advapi32.lib

#
# Locations of the tools
#

CC 	= $(TOOLS32)\bin\cl
LIB32	= $(TOOLS32)\bin\link.exe -lib
LINK	= $(TOOLS32)\bin\link.exe 

#
# Implicit rules
#

{$(GENERICDIR)}.c{$(TMPDIR)}.obj:
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $<

{$(WIN32DIR)}.c{$(TMPDIR)}.obj:
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $<

{$(WINDLLDIR)}.c{$(TMPDIR)}.obj:
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $<

#
# finally! the targets
#

####all : setup libs exes
all : setup libs 

setup :
	if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"
	if not exist "$(TMPDIR)/$(NULL)" mkdir "$(TMPDIR)"

libs : $(UNZIPLIB)

#exes : $(UNZIPEXE) $(FUNZIPEXE) $(UNZIPSFXEXE)
exes : $(UNZIPEXE) 

"$(UNZIPLIB)" : setup $(LIB32_OBJS)
	$(LIB32) @<<
  $(LIB32_FLAGS) $(LIB32_OBJS)
<<

UNZIPEXE_SRCS = $(ROOTDIR)\unzip.c
$(UNZIPEXE) : $(UNZIPEXE_SRCS)
	$(CC) /Fe$@ /Fo$(TMPDIR)\ $(EXE_CFLAGS) $(DEBUG_CFLAGS) \
		$(OPTIMIZE_CFLAGS) $(UNZIPEXE_SRCS) $(LINK_LIBS)

$(FUNZIPEXE) :
	$(CC) /Fe$@ /Fo$(TMPDIR)\ $(EXE_CFLAGS) $(DEBUG_CFLAGS) \
		$(OPTIMIZE_CFLAGS) $(ROOTDIR)\funzip.c

$(UNZIPSFXEXE) :
	$(CC) /Fe$@ /Fo$(TMPDIR)\ $(EXE_CFLAGS) $(DEBUG_CFLAGS) \
		$(OPTIMIZE_CFLAGS) $(ROOTDIR)\unzipsfx.c

clean :
	if exist "$(OUTDIR)/$(NULL)" rmdir "$(OUTDIR)" /s /q
	if exist "$(TMPDIR)/$(NULL)" rmdir "$(TMPDIR)" /s /q

#
# Dependencies and explicit rules (from a VC-generated .mak file)
#

SOURCE=$(ROOTDIR)\api.c
DEP_CPP_API_C=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(ROOTDIR)\version.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\api.obj" : $(SOURCE) $(DEP_CPP_API_C) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\crc32.c
DEP_CPP_CRC32=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"\
	"$(ROOTDIR)\zip.h"

"$(TMPDIR)\crc32.obj" : $(SOURCE) $(DEP_CPP_CRC32) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\crctab.c
DEP_CPP_CRCTA=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"\
	"$(ROOTDIR)\zip.h"

"$(TMPDIR)\crctab.obj" : $(SOURCE) $(DEP_CPP_CRCTA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\crypt.c

"$(TMPDIR)\crypt.obj" : $(SOURCE) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\explode.c
DEP_CPP_EXPLO=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\explode.obj" : $(SOURCE) $(DEP_CPP_EXPLO) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\extract.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_EXTRA=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\extract.obj" : $(SOURCE) $(DEP_CPP_EXTRA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_EXTRA=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\extract.obj" : $(SOURCE) $(DEP_CPP_EXTRA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\fileio.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_FILEI=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\ebcdic.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\ttyio.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\fileio.obj" : $(SOURCE) $(DEP_CPP_FILEI) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_FILEI=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\ebcdic.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\ttyio.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\fileio.obj" : $(SOURCE) $(DEP_CPP_FILEI) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\globals.c
DEP_CPP_GLOBA=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\globals.obj" : $(SOURCE) $(DEP_CPP_GLOBA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\inflate.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_INFLA=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\inflate.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\inflate.obj" : $(SOURCE) $(DEP_CPP_INFLA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_INFLA=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\inflate.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\inflate.obj" : $(SOURCE) $(DEP_CPP_INFLA) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\list.c
DEP_CPP_LIST_=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\list.obj" : $(SOURCE) $(DEP_CPP_LIST_) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\match.c
DEP_CPP_MATCH=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\match.obj" : $(SOURCE) $(DEP_CPP_MATCH) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(WIN32DIR)\nt.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_NT_C14=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\nt.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\nt.obj" : $(SOURCE) $(DEP_CPP_NT_C14) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_NT_C14=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\nt.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\nt.obj" : $(SOURCE) $(DEP_CPP_NT_C14) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\process.c
DEP_CPP_PROCE=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\process.obj" : $(SOURCE) $(DEP_CPP_PROCE) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\ttyio.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_TTYIO=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\ttyio.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"\
	"$(ROOTDIR)\zip.h"

"$(TMPDIR)\ttyio.obj" : $(SOURCE) $(DEP_CPP_TTYIO) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_TTYIO=\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\ttyio.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"\
	"$(ROOTDIR)\zip.h"

"$(TMPDIR)\ttyio.obj" : $(SOURCE) $(DEP_CPP_TTYIO) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\unreduce.c
DEP_CPP_UNRED=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\unreduce.obj" : $(SOURCE) $(DEP_CPP_UNRED) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(ROOTDIR)\unshrink.c
DEP_CPP_UNSHR=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\unshrink.obj" : $(SOURCE) $(DEP_CPP_UNSHR) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


SOURCE=$(WIN32DIR)\win32.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_WIN32=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\nt.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\win32.obj" : $(SOURCE) $(DEP_CPP_WIN32) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_WIN32=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\nt.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\win32.obj" : $(SOURCE) $(DEP_CPP_WIN32) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(WINDLLDIR)\windll.c

!IF "$(NODEBUG)" == "1"

DEP_CPP_WINDL=\
	"$(ROOTDIR)\consts.h"\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(ROOTDIR)\version.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\windll.obj" : $(SOURCE) $(DEP_CPP_WINDL) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ELSEIF "$(NODEBUG)" == "0"

DEP_CPP_WINDL=\
	"$(ROOTDIR)\consts.h"\
	"$(ROOTDIR)\crypt.h"\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(ROOTDIR)\version.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\windll.obj" : $(SOURCE) $(DEP_CPP_WINDL) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)


!ENDIF 

SOURCE=$(ROOTDIR)\zipinfo.c
DEP_CPP_ZIPIN=\
	"$(ROOTDIR)\globals.h"\
	"$(ROOTDIR)\unzip.h"\
	"$(ROOTDIR)\unzpriv.h"\
	"$(WIN32DIR)\w32cfg.h"

"$(TMPDIR)\zipinfo.obj" : $(SOURCE) $(DEP_CPP_ZIPIN) "$(TMPDIR)"
	$(CC) /c $(OBJ_CFLAGS) $(DEBUG_CFLAGS) $(OPTIMIZE_CFLAGS) $(SOURCE)
