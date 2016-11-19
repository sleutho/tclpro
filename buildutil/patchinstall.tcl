# patchinstall.tcl --
#	This file implements a way to make multiple pattern substitutions
#	on a file, just like "sed -e 's/foo/bar' -e 's/baz/bear'

package provide patchinstall 1.0

namespace eval PatchInstall {
}

# PatchInstall::substitute --
#
#	Perform sed-like substitutions on a file
#
# Arguments:
#	filename	Name of file to create.  The input file is the same
#			as "filename", but with a .in extension.  This is
#			supposed to mimic autoconf's behaviour.
#
#	args		Pattern/substitution pairs.  Each element of args
#			must be a list of 2 elements.  The first element is
#			the pattern to replace, and the second element is the
#			string to use as the replacement.
#
# Results:
#
#	A new file will be created.
#
# Returns:
#
#	1 if everything succeeded, 0 if errors were encountered.

proc PatchInstall::substitute {filename args} {
    set inputFile $filename.in
    set outputFile $filename

    if {![file exists $inputFile]} {
	puts "input file $inputFile does not exist"
	return 0
    }

    set infileId [open $inputFile r]
    set outfileId [open $outputFile w]

    while {![eof $infileId]} {
	gets $infileId line

	if {![eof $infileId]} {
	    foreach pair $args {
		set pattern [lindex $pair 0]
		set replacement [lindex $pair 1]
		regsub $pattern $line $replacement line
	    }
	    puts $outfileId $line
	}
    }
    close $infileId
    close $outfileId

    return 1
}
