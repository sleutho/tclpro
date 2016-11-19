# check4.tcl --
#
# This file contains several snippets of Tcl code, each of which
# has one or more errors.  It should be used as a sample input
# file for TclPro Checker.

# The following fragment uses a regular expression whose meaning has
# changed in Tcl 8.1.  Whereas \a used to mean literal-a, it is now 
# treated as an escape sequence by the regular expression parser. 

regexp {\a} a

regexp {\n} "Hello World!\n" match
