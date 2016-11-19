# sampleApp.mak  --
# 
#	This file is a Visual C++ 5.0 compatible Makefile for building Tcl
#       interpreters with TclPro Byte Code Loader and TclPro Wrapper
#       extensions.
# 
# Copyright (c) 1998-1999 by Scriptics Corporation. 
# All rights reserved.
# 

# Common definitions.

#
# Project directories
#
# TCLPRO_ROOT    = top of TclPro installation tree
#
# TMPDIR  = location where .obj files should be stored during build
#
# TOOLS32 = location of VC++ 32-bit development tools. Note that the
#	    VC++ 2.0 header files are broken, so you need to use the
#	    ones that come with the developer network CD's, or later
#	    versions of VC++.
#

TCLPRO_ROOT		= ..\..
TOOLS32		= c:\progra~1\devstudio\vc
TOOLS32_rc	= c:\progra~1\devstudio\sharedide

cc32		= $(TOOLS32)\bin\cl.exe
link32		= $(TOOLS32)\bin\link.exe
rc32		= $(TOOLS32_rc)\bin\rc.exe
include32	= -I$(TOOLS32)\include


######################################################################
# Sample Application specific Macros
######################################################################

PROCOMP			= $(TCLPRO_ROOT)\win32-ix86\bin\procomp.exe
PROWRAP			= $(TCLPRO_ROOT)\win32-ix86\bin\prowrap.exe

NAMEPREFIX = sampleApp

# Set this to the appropriate value of /MACHINE: for your platform
MACHINE	= IX86

# Set NODEBUG to 0 to compile with symbols
NODEBUG = 1

SAMPLEAP_ROOT = .
!IF "$(NODEBUG)" == "1"
TMPDIRNAME	= Release
DBGX		=
!ELSE
TMPDIRNAME	= Debug
DBGX		= d
!ENDIF
OUTDIR_STATIC = Static-$(TMPDIRNAME)
OUTDIR_DYNAMIC = Dynamic-$(TMPDIRNAME)

STATICX = s
DYNAMICX =
DYNAMICX_X = x
TCLSH_PREFIX = Tclsh
WISH_PREFIX = Wish
BIGTCLSH_PREFIX = Big
BIGWISH_PREFIX = Big
TK_VERSION = 8.3.0

TK_BASE=$(TCLPRO_ROOT)/src/tk$(TK_VERSION)

SAMPLEAPP_TCL_STATIC_SHELL =  \
    $(OUTDIR_STATIC)\$(NAMEPREFIX)$(TCLSH_PREFIX)$(STATICX)$(DBGX).exe
SAMPLEAPP_WISH_STATIC_SHELL =   \
    $(OUTDIR_STATIC)\$(NAMEPREFIX)$(WISH_PREFIX)$(STATICX)$(DBGX).exe
SAMPLEAPP_BIGTCL_STATIC_SHELL = \
    $(OUTDIR_STATIC)\$(NAMEPREFIX)$(BIGTCLSH_PREFIX)$(TCLSH_PREFIX)$(STATICX)$(DBGX).exe
SAMPLEAPP_BIGWISH_STATIC_SHELL =  \
    $(OUTDIR_STATIC)\$(NAMEPREFIX)$(BIGWISH_PREFIX)$(WISH_PREFIX)$(STATICX)$(DBGX).exe
SAMPLEAPP_TCL_DYNAMIC_SHELL = \
    $(OUTDIR_DYNAMIC)\$(NAMEPREFIX)$(TCLSH_PREFIX)$(DYNAMICX)$(DBGX).exe
SAMPLEAPP_WISH_DYNAMIC_SHELL =  \
    $(OUTDIR_DYNAMIC)\$(NAMEPREFIX)$(WISH_PREFIX)$(DYNAMICX)$(DBGX).exe

SAMPLEAPP_TCL_STATIC_OBJS = \
    $(OUTDIR_STATIC)\proTclWinMain.obj \
    $(OUTDIR_STATIC)\proWrapTclMain.obj

SAMPLEAPP_BIGTCL_STATIC_OBJS = \
    $(OUTDIR_STATIC)\proBigtclWinMain.obj \
    $(OUTDIR_STATIC)\proWrapTclMain.obj

SAMPLEAPP_TCL_STATIC_RES = \
    $(OUTDIR_STATIC)\sampleAppTclshExe.res

SAMPLEAPP_WISH_STATIC_OBJS = \
    $(OUTDIR_STATIC)\proTkWinMain.obj \
    $(OUTDIR_STATIC)\proWrapTkMain.obj

SAMPLEAPP_BIGWISH_STATIC_OBJS = \
    $(OUTDIR_STATIC)\proBigwishWinMain.obj \
    $(OUTDIR_STATIC)\proWrapTkMain.obj

SAMPLEAPP_WISH_STATIC_RES = \
    $(OUTDIR_STATIC)\sampleAppWishExe.res

SAMPLEAPP_TCL_DYNAMIC_OBJS = \
    $(OUTDIR_DYNAMIC)\proTclWinMain.obj \
    $(OUTDIR_DYNAMIC)\proWrapTclMain.obj

SAMPLEAPP_TCL_DYNAMIC_RES = \
    $(OUTDIR_STATIC)\sampleAppTclshExe.res

SAMPLEAPP_WISH_DYNAMIC_OBJS = \
    $(OUTDIR_DYNAMIC)\proTkWinMain.obj \
    $(OUTDIR_DYNAMIC)\proWrapTkMain.obj

SAMPLEAPP_WISH_DYNAMIC_RES = \
    $(OUTDIR_DYNAMIC)\sampleAppWishExe.res

TCLPRO_TCLLIBDIR = $(TCLPRO_ROOT)\lib\tcl8.3
TCLPRO_TKLIBDIR  = $(TCLPRO_ROOT)\lib\tk8.3
TCLPRO_INCLUDEDIR = $(TCLPRO_ROOT)\include
TCLPRO_STATIC_WRAPPERLIB = $(TCLPRO_ROOT)\win32-ix86\lib\wrapper10$(STATICX)$(DBGX).lib
TCLPRO_DYNAMIC_WRAPPERLIB = $(TCLPRO_ROOT)\win32-ix86\lib\wrapper10$(DYNAMICX_X)$(DBGX).lib
TCLPRO_STATIC_TBCLOADLIB = $(TCLPRO_ROOT)\win32-ix86\lib\tbcload13$(STATICX)$(DBGX).lib
TCLPRO_DYNAMIC_TBCLOADLIB = $(TCLPRO_ROOT)\win32-ix86\lib\tbcload13$(DYNAMICX)$(DBGX).lib

TCLPRO_DEFINES  = -D__WIN32__ $(DEBUGDEFINES)

TCLPRO_STATIC_CFLAGS = \
	$(cdebug) $(cflags) $(cvarsstatic) $(include32) \
	-DSTATIC_BUILD -I$(TCLPRO_INCLUDEDIR) $(TCLPRO_DEFINES)

TCLPRO_DYNAMIC_CFLAGS = \
	$(cdebug) $(cflags) $(cvarsdynamic) $(include32) \
	-I$(TCLPRO_INCLUDEDIR) $(TCLPRO_DEFINES)


######################################################################
# Link flags
######################################################################

!IF "$(NODEBUG)" == "1"
ldebug = /RELEASE
!ELSE
ldebug = -debug:full -debugtype:cv
!ENDIF

# declarations common to all linker options
lcommon = /NODEFAULTLIB /RELEASE /NOLOGO

# declarations for use on Intel i386, i486, and Pentium systems
!IF "$(MACHINE)" == "IX86"
DLLENTRY = @12
lflags   = $(lcommon) /MACHINE:$(MACHINE)
!ELSE
lflags   = $(lcommon) /MACHINE:$(MACHINE)
!ENDIF

conlflags = $(lflags) -subsystem:console -entry:mainCRTStartup
guilflags = $(lflags) -subsystem:windows -entry:WinMainCRTStartup

!IF "$(MACHINE)" == "PPC"
libc = libc.lib
libcdll = crtdll.lib
!ELSE
libc = libcmt$(DBGX).lib oldnames.lib
libcdll = msvcrt$(DBGX).lib oldnames.lib
!ENDIF

baselibs   = kernel32.lib $(optlibs) advapi32.lib user32.lib wsock32.lib
winlibs    = $(baselibs) gdi32.lib comdlg32.lib winspool.lib

conlibs	   = $(libc) $(baselibs)
guilibs	   = $(libc) $(winlibs)
guilibsdll = $(libcdll) $(winlibs)
conlibsdll = $(libcdll) $(baselibs)

TCLPRO_STATIC_TCLLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tcl83$(STATICX)$(DBGX).lib
TCLPRO_STATIC_TKLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tk83$(STATICX)$(DBGX).lib
TCLPRO_STATIC_ITCLLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\itcl32$(STATICX)$(DBGX).lib
TCLPRO_STATIC_ITKLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\itk32$(STATICX)$(DBGX).lib
TCLPRO_STATIC_WRAPPERLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\wrapper10$(STATICX)$(DBGX).lib
TCLPRO_STATIC_TBCLOADLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tbcload13$(STATICX)$(DBGX).lib
TCLPRO_STATIC_TCLXLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tclx82$(STATICX)$(DBGX).lib
TCLPRO_STATIC_TKXLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tkx82$(STATICX)$(DBGX).lib
TCLPRO_DYNAMIC_TCLLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tcl83$(DYNAMICX)$(DBGX).lib
TCLPRO_DYNAMIC_TKLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tk83$(DYNAMICX)$(DBGX).lib
TCLPRO_DYNAMIC_WRAPPERLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\wrapper10x$(DYNAMICX)$(DBGX).lib
TCLPRO_DYNAMIC_TBCLOADLIB = \
    $(TCLPRO_ROOT)\win32-ix86\lib\tbcload13$(DYNAMICX)$(DBGX).lib


######################################################################
# Compile flags
######################################################################

!IF "$(NODEBUG)" == "1"
!IF "$(MACHINE)" == "ALPHA"
# MSVC on Alpha doesn't understand -Ot
cdebug = -O2i -Gs -GD
!ELSE
cdebug = -Oti -Gs -GD
!ENDIF
!ELSE
cdebug = -Z7 -Od -WX
!ENDIF

# declarations common to all compiler options
ccommon = -c -W3 -nologo -YX -Fp$(TMPDIR)\ -Dtry=__try -Dexcept=__except

!IF "$(MACHINE)" == "IX86"
cflags = $(ccommon) -D_X86_=1
!ELSE
!IF "$(MACHINE)" == "MIPS"
cflags = $(ccommon) -D_MIPS_=1
!ELSE
!IF "$(MACHINE)" == "PPC"
cflags = $(ccommon) -D_PPC_=1
!ELSE
!IF "$(MACHINE)" == "ALPHA"
cflags = $(ccommon) -D_ALPHA_=1
!ENDIF
!ENDIF
!ENDIF
!ENDIF

cvars      = -DWIN32 -D_WIN32

!IF "$(NODEBUG)" == "1"
cvarsstatic =  $(cvars) -MT
cvarsdynamic = $(cvars) -MD
!ELSE
cvarsstatic =  $(cvars) -MT$(DBGX)
cvarsdynamic = $(cvars) -MD$(DBGX)
!ENDIF


######################################################################
# Factorial application macros
######################################################################

FACTORIAL_TCL_FILES	= factorial.tcl startup.tcl
FACTORIAL_WRAP_FILES	= \
    factorial\factorial.tbc factorial\startup.tbc factorial\pkgIndex.tcl
FACTORIAL_STATIC	= factorial\fac-static.exe
FACTORIAL_DYNAMIC	= factorial\fac-dynamic.exe


######################################################################
# SampleApp specific targets
######################################################################

all : static dynamic

all-debug-and-release:
	$(MAKE) /f sampleApp.mak NODEBUG=1
	$(MAKE) /f sampleApp.mak NODEBUG=0

static : tclsh-static wish-static bigtclsh-static bigwish-static

dynamic : tclsh-dynamic wish-dynamic

tclsh : tclsh-static tclsh-dynamic

wish : wish-static wish-dynamic

bigtclsh : bigtclsh-static

bigwish : bigwish-static

tclsh-static : $(OUTDIR_STATIC) $(SAMPLEAPP_TCL_STATIC_SHELL)

tclsh-dynamic : $(OUTDIR_DYNAMIC) $(SAMPLEAPP_TCL_DYNAMIC_SHELL)

wish-static : $(OUTDIR_STATIC) $(SAMPLEAPP_WISH_STATIC_SHELL)

wish-dynamic : $(OUTDIR_DYNAMIC) $(SAMPLEAPP_WISH_DYNAMIC_SHELL)

bigtclsh-static : $(OUTDIR_STATIC) $(SAMPLEAPP_BIGTCL_STATIC_SHELL)

bigwish-static : $(OUTDIR_STATIC) $(SAMPLEAPP_BIGWISH_STATIC_SHELL)

$(OUTDIR_STATIC) $(OUTDIR_DYNAMIC):
	@mkdir $@

$(SAMPLEAPP_TCL_STATIC_SHELL): $(SAMPLEAPP_TCL_STATIC_OBJS) $(SAMPLEAPP_TCL_STATIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(conlflags) $(SAMPLEAPP_TCL_STATIC_RES) \
		-stack:2300000 -out:$@ $(conlibs) \
		$(TCLPRO_STATIC_TCLLIB) \
		$(TCLPRO_STATIC_WRAPPERLIB) \
		$(TCLPRO_STATIC_TBCLOADLIB) \
		$(SAMPLEAPP_TCL_STATIC_OBJS)

$(SAMPLEAPP_WISH_STATIC_SHELL): $(TK_BASE) $(SAMPLEAPP_WISH_STATIC_OBJS) $(SAMPLEAPP_WISH_STATIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(guilflags) $(SAMPLEAPP_WISH_STATIC_RES) \
		-stack:2300000 -out:$@ $(guilibs) \
		$(TCLPRO_STATIC_TCLLIB) \
		$(TCLPRO_STATIC_TKLIB) \
		$(TCLPRO_STATIC_WRAPPERLIB) \
		$(TCLPRO_STATIC_TBCLOADLIB) \
		$(SAMPLEAPP_WISH_STATIC_OBJS)

$(SAMPLEAPP_BIGTCL_STATIC_SHELL): $(SAMPLEAPP_BIGTCL_STATIC_OBJS) $(SAMPLEAPP_STATIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(conlflags) $(SAMPLEAPP_TCL_STATIC_RES) \
		-stack:2300000 -out:$@ $(conlibs) \
		$(TCLPRO_STATIC_TCLLIB) \
		$(TCLPRO_STATIC_ITCLLIB) \
		$(TCLPRO_STATIC_TCLXLIB) \
		$(TCLPRO_STATIC_WRAPPERLIB) \
		$(TCLPRO_STATIC_TBCLOADLIB) \
		$(SAMPLEAPP_BIGTCL_STATIC_OBJS)

$(SAMPLEAPP_BIGWISH_STATIC_SHELL): $(TK_BASE) $(SAMPLEAPP_BIGWISH_STATIC_OBJS) $(SAMPLEAPP_STATIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(guilflags) $(SAMPLEAPP_WISH_STATIC_RES) \
		-stack:2300000 -out:$@ $(guilibs) \
		$(TCLPRO_STATIC_TCLLIB) \
		$(TCLPRO_STATIC_TKLIB) \
		$(TCLPRO_STATIC_ITCLLIB) \
		$(TCLPRO_STATIC_ITKLIB) \
		$(TCLPRO_STATIC_TCLXLIB) \
		$(TCLPRO_STATIC_TKXLIB) \
		$(TCLPRO_STATIC_WRAPPERLIB) \
		$(TCLPRO_STATIC_TBCLOADLIB) \
		$(SAMPLEAPP_BIGWISH_STATIC_OBJS)

$(SAMPLEAPP_TCL_DYNAMIC_SHELL): $(SAMPLEAPP_TCL_DYNAMIC_OBJS) $(SAMPLEAPP_TCL_DYNAMIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(conlflags) $(SAMPLEAPP_TCL_DYNAMIC_RES) \
		-stack:2300000 -out:$@ $(conlibsdll) \
		$(TCLPRO_DYNAMIC_TCLLIB) \
		$(TCLPRO_DYNAMIC_WRAPPERLIB) \
		$(TCLPRO_DYNAMIC_TBCLOADLIB) \
		$(SAMPLEAPP_TCL_DYNAMIC_OBJS)

$(SAMPLEAPP_WISH_DYNAMIC_SHELL): $(SAMPLEAPP_WISH_DYNAMIC_OBJS) $(SAMPLEAPP_WISH_DYNAMIC_RES)
	set LIB=$(TOOLS32)\lib
	$(link32) $(ldebug) $(guilflags) $(SAMPLEAPP_WISH_DYNAMIC_RES) \
		-stack:2300000 -out:$@ $(guilibsdll) \
		$(TCLPRO_DYNAMIC_TCLLIB) \
		$(TCLPRO_DYNAMIC_TKLIB) \
		$(TCLPRO_DYNAMIC_WRAPPERLIB) \
		$(TCLPRO_DYNAMIC_TBCLOADLIB) \
		$(SAMPLEAPP_WISH_DYNAMIC_OBJS)

$(TK_BASE):
	@if not exist $(TK_BASE) echo *************** ERROR ****************
	@if not exist $(TK_BASE) echo You will need  to install the Tk $(TK_VERSION)
	@if not exist $(TK_BASE) echo sources to complete the build of the 
	@if not exist $(TK_BASE) echo static sample Wish and BigWish applica- 
	@if not exist $(TK_BASE) echo tions. These sources include the icon 
	@if not exist $(TK_BASE) echo resources that do not currently exist. 
	@if not exist $(TK_BASE) echo **************************************

#
# Sample application object.
#

$(OUTDIR_STATIC)\proTclWinMain.obj: $(TCLPRO_TCLLIBDIR)\proTclWinMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) -DCONSOLE -Fo$@ $?

$(OUTDIR_STATIC)\proBigTclWinMain.obj: $(TCLPRO_TCLLIBDIR)\proTclWinMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) \
	-DITCL_STATIC_BUILD -DTCLX_STATIC_BUILD \
	 -DCONSOLE -Fo$@ $?

$(OUTDIR_STATIC)\proTkWinMain.obj: $(TCLPRO_TKLIBDIR)\proTkWinMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) -Fo$@ $?

$(OUTDIR_STATIC)\proBigwishWinMain.obj: $(TCLPRO_TKLIBDIR)\proTkWinMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) \
	-DITCL_STATIC_BUILD -DTCLX_STATIC_BUILD \
	-Fo$@ $?

$(OUTDIR_STATIC)\proWrapTclMain.obj: $(TCLPRO_TCLLIBDIR)\proWrapTclMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) -DCONSOLE -Fo$@ $?

$(OUTDIR_STATIC)\proWrapTkMain.obj: $(TCLPRO_TKLIBDIR)\proWrapTkMain.c
	$(cc32) $(TCLPRO_STATIC_CFLAGS) -Fo$@ $?

$(OUTDIR_DYNAMIC)\proTclWinMain.obj: $(TCLPRO_TCLLIBDIR)\proTclWinMain.c
	$(cc32) $(TCLPRO_DYNAMIC_CFLAGS) -DBUILD_wrapper -DCONSOLE -Fo$@ $?

$(OUTDIR_DYNAMIC)\proTkWinMain.obj: $(TCLPRO_TKLIBDIR)\proTkWinMain.c
	$(cc32) $(TCLPRO_DYNAMIC_CFLAGS) -DBUILD_wrapper -Fo$@ $?

$(OUTDIR_DYNAMIC)\proWrapTclMain.obj:  $(TCLPRO_TCLLIBDIR)\proWrapTclMain.c
	$(cc32) $(TCLPRO_DYNAMIC_CFLAGS) -DBUILD_wrapper -DCONSOLE -Fo$@ $?

$(OUTDIR_DYNAMIC)\proWrapTkMain.obj: $(TCLPRO_TKLIBDIR)\proWrapTkMain.c
	$(cc32) $(TCLPRO_DYNAMIC_CFLAGS) -DBUILD_wrapper -Fo$@ $?

# The factorial target creates two wrapped executables:
#  - from the statically linked tclsh that was just created
#  - from one of the .in files provided with the TclPro distribution.
# These are examples of how to wrap your own extension, and of how to use
# the prebuilt ones.

factorial: $(OUTDIR_STATIC) $(SAMPLEAPP_TCL_STATIC_SHELL) \
	compile-factorial wrap-factorial

wrap-factorial:
	$(PROWRAP) -nologo \
		-uses "" \
		-executable $(SAMPLEAPP_TCL_STATIC_SHELL) \
		-out $(FACTORIAL_STATIC) \
		-startup factorial/startup.tbc \
		$(FACTORIAL_WRAP_FILES) \
		-relativeto $(TCLPRO_ROOT) $(TCLPRO_TCLLIBDIR)/* \
		-code "set tcl_library lib/tcl8.3"
	$(PROWRAP) -nologo \
		-uses tclsh-dynamic \
		-out $(FACTORIAL_DYNAMIC) \
		-startup factorial/startup.tbc \
		$(FACTORIAL_WRAP_FILES)

# compile the factorial package, generate a pkgIndex.tcl file

compile-factorial:
	if not exist factorial mkdir factorial
	$(PROCOMP) -verbose -out factorial $(FACTORIAL_TCL_FILES)
	$(SAMPLEAPP_TCL_STATIC_SHELL) <<
cd factorial ; pkg_mkIndex -load tbcload . factorial.tbc
<<

.rc{$(OUTDIR_STATIC)}.res:
	$(rc32) -fo $@ -r -i $(TCLPRO_INCLUDEDIR) -D__WIN32__ -DTK_BASE=$(TK_BASE) \
		$(TCL_DEFINES) $<

.rc{$(OUTDIR_DYNAMIC)}.res:
	$(rc32) -fo $@ -r -i $(TCLPRO_INCLUDEDIR) -D__WIN32__  \
		$(TCL_DEFINES) $<

clean-all:
	$(MAKE) /f sampleApp.mak NODEBUG=1 clean
	$(MAKE) /f sampleApp.mak NODEBUG=0 clean

clean:
	-@del $(OUTDIR_STATIC)\*.*
	-@del $(OUTDIR_DYNAMIC)\*.*
	-@del factorial\*.*
	-@rmdir $(OUTDIR_STATIC)
	-@rmdir $(OUTDIR_DYNAMIC)
	-@rmdir factorial

