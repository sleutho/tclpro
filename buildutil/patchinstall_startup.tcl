# patchinstall_startup.tcl --
#	Startup file for patching installed files
#
# Arguments:
#	srcdir	Directory containing the relocated apache installation
#
# Results:
#	The files "bin/apachectl" and "conf/httpd.conf" will be modified
#

package require cmdline
package require patchinstall

namespace eval StartupArgs {
    variable optionList {? h help infile.arg patsub.arg}
    variable usageStr {Bug Mike to write the usage string}
    variable patternSubPairs {}
    variable infileList {}
}

proc StartupArgs::processArglist {args} {
    variable optionList
    variable usageStr
    variable infileList
    variable patternSubPairs

    set infileList {}
    while {[set err [cmdline::getopt args $optionList opt arg]]} {
	if {$err < 0} {
	    append errorMsg "error:  [cmdline::getArgv0]: " \
		    "$arg (use \"-help\" for legal options)"
	    set errorCode 1
	    break
	} else {
	    switch -exact $opt {
		? -
		h -
		help {
		    set errorMsg $usageStr
		    set errorCode 0
		    break
		}
		infile {
		    set infileList $arg
		}
		patsub {
		    lappend patternSubPairs $arg
		}
	    }
	}
    }
}

eval StartupArgs::processArglist $argv

if {[expr {[llength $argv] % 2}] != 0 || [llength $argv] == 0} {
    puts stderr "Usage:  tclsh patchinstall_startup.tcl 'pat sub' ?'pat sub'?"
    exit 1
}

set result [eval PatchInstall::substitute $StartupArgs::infileList $StartupArgs::patternSubPairs]

if {$result} {
    exit 0
} else {
    exit 1
}
