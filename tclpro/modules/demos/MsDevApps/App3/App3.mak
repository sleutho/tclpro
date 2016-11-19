tclProToolsDir	=	..\..\..\win32-ix86\bin
tclProLibDir	=	..\..\..\win32-ix86\lib

procomp	=   $(tclProToolsDir)\procomp.exe
prowrap	=   $(tclProToolsDir)\prowrap.exe
procheck    =    $(tclProToolsDir)\procheck.exe

tclstublib  =	$(tclProLibDir)\tclstub83.lib
tclstaticlib	=   $(tclProLibDir)\tcl83s.lib
itclstublib =	$(tclProLibDir)\itclstub32.lib
itclstaticlib	=   $(tclProLibDir)\itcl32s.lib
tbcstaticlib	=   $(tclProLibDir)\tbcload13s.lib
wrapstaticlib	=   $(tclProLibDir)\wrapper14s.lib


TBCs = \
	itclstack.tbc \
	startup.tbc

OBJs = \
	itclstack.obj \
	myMain.obj


App3.exe : App3U.exe $(TBCs)
	$(prowrap) -nologo -out $@ \
	-uses itclsh \
	-executable App3U.exe \
	-startup startup.tbc \
	$(TBCs)

# -nodefaultlib:msvcrt.lib is needed to strip the -MD compile from the
# Stubs libraries.

App3U.exe : $(OBJs)
	link -nologo -subsystem:console -out:$@ $(OBJs) \
	    -nodefaultlib:msvcrt.lib libcmt.lib user32.lib advapi32.lib \
	    $(tclstublib) $(itclstublib) $(tclstaticlib) $(itclstaticlib) \
	    $(tbcstaticlib) $(wrapstaticlib)

.cpp.obj::
	cl -nologo -c -MT -I"..\..\..\include" -DSTATIC_BUILD $<

.c.obj::
	cl -nologo -c -MT -I"..\..\..\include" $<

.tcl.tbc ::
	$(procheck) $<
	$(procomp) $<


# need this to enable our new inference rules
.SUFFIXES:
.SUFFIXES: .c .cpp .tcl

