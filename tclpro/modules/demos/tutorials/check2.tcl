# check2.tcl --
#
# This file contains several snippets of Tcl code, each of which
# has one or more errors.  It should be used as a sample input
# file for TclPro Checker.  This file contains portability problems.

# The following code concatenations file names instead of using "file join".

open $dir/foo
open [file join $dir foo]

# The "registry" command only works under Windows.

package require registry 1.0
registry get {a\b\c} value

# The channel name "file1" isn't portable: use "stdout" instead

puts file1 "Test line"
