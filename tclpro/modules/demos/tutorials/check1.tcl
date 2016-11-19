# check1.tcl --
#
# This file contains several snippets of Tcl code, each of which
# has one or more errors.  It should be used as a sample input
# file for TclPro Checker.

# The following code has a missing close-quote.

if {$x < 0} {
    set y "x was too small
}

# In the following code snippet, the open-brace for the "if" body
# is on the wrong line.

if {$x < 14}
{
    set x 14
}

# In the following snippet the "compare" option to the "string"
# command is misspelled.

string cmpare $x $y

# In the code below there is an illegal configuration option for
# the button widget.

button .b -text Hello -size 20

# The following defines a procedue myProc that accepts two
# arguments. The script than incorrectly calls myProc with
# only one argument.

proc myProc { num1 num2 } {
    puts "The sum of $num1 and $num2 is [expr { $num1 + $num2 }]"
    return
}

myProc {3}
