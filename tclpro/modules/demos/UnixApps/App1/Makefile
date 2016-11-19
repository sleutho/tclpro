# This is a simple application that
# compiles and wraps a single .tcl file

tclProToolsDir=..\win32-ix86\bin
prochec=$(tclProToolsDir)\procheck
procomp=$(tclProToolsDir)\procomp
prowrap=$(tclProToolsDir)\prowrap


App1.exe : App1.tbc
    $(prowrap) -uses tclsh -out $@ App1.tbc
    
App1.tbc :
    $(procheck) App1.tcl
    $(procomp) App1.tcl
