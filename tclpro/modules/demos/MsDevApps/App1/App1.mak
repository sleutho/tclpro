# This is a simple application that
# compiles and wraps a single .tcl file

tclProToolsDir =	..\win32-ix86\bin
procomp	=   "$(tclProToolsDir)\procomp.exe"
prowrap	=   "$(tclProToolsDir)\prowrap.exe"


App1.exe : App1.tbc
    $(prowrap) -uses tclsh -out $@ App1.tbc
    
App1.tbc :
    $(procomp) App1.tcl

