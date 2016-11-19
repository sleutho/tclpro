# checkerCmdline.tcl --
#
#	This file specifies what is done with command line arguments in
#       the Checker.
#
# Copyright (c) 1999-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: checkerCmdline.tcl,v 1.9 2001/04/11 18:48:12 welch Exp $

namespace eval checkerCmdline {

    # The usageStr variable stores the message to print if there is
    # an error in the command line args or -help was specified.

    variable usageStr {}
}

# checkerCmdline::init --
#
#	Based on command line arguments, load type checkers
#	into the anaylyzer.
#
# Arguments:
#	None.
#
# Results:
#	A list of files to be analyzed; an empty list means stdin will
#	analyzed.  If file patterns were specified, but no matching files
#	exist, the print the usage string and exit with an error code of 1.

proc checkerCmdline::init {} {
    global argv ::configure::initPkgs ::configure::versions \
	    ::configure::verTable ::configure::validPkgs \
	    ::configure::usrPcxDirList ::configure::loadPCX \
	    ::configure::usrPkgArgs ::projectInfo::printCopyright
    variable usageStr
    set printCopyright 0

    set usageStr "Usage: [cmdline::getArgv0] ?options? ?filePattern...?
  -logo     show copyright banner
  -help     print this help message
  -quiet    prints minimal error information
  -onepass  perform a single pass without checking proc args
  -verbose  prints summary information
  -suppress \"messageID ?messageID ...?\"
            prevent given messageIDs from being printed
  -use \"package?version? ?package?version? ...?\"
            specify specific versions & packages to check
  -W1       print only error messages
  -W2       print error and usage warnings
  -W3       print all errors and warnings
  -Wall     print all types of messages (same as W3)"

    # Parse the command line args, ammending the global auto_path
    # if a path is specified, and building a list of packages if 
    # a one or more packages are specified.  

    set errorMsg  {}
    set errorCode -1
    set quiet 0
    set usrPkgArgs {}
    set optionList {? h help logo u.arg use.arg s.arg suppress.arg \
	    o onepass q quiet v verbose W1 W2 W3 Wall nopcx pcx.arg}

    while {[set err [cmdline::getopt argv $optionList opt arg]]} {
	if {$err < 0} then {
	    append errorMsg "error: [cmdline::getArgv0]: " \
		    "$arg (use \"-help\" for legal optins)"
	    set errorCode 1
	    break
	} else {
	    switch -exact $opt {
		? -
		h -
		help {
		    set errorMsg  $usageStr
		    set errorCode 0
		    break
		}
		logo {
		    # By modifying this variable in the projectInfo package
		    # we will suppress the logo information when we check
		    # out the license key.

		    set printCopyright 1
		}
		u -
		use {
		    # specify which analyzer packages to load.

		    if {[catch {llength $arg}]} {
			set errorMsg  "invalid package name: \"$arg\""
			set errorCode 1
			break
		    }
		    lappend usrPkgArgs $arg
		}
		s -
		suppress {
		    if {[catch {llength $arg}]} {
			set errorMsg  "invalid methodID \"$arg\""
			set errorCode 1
			break
		    }
		    filter::addSuppressor $arg
		}
		o -
		onepass {
		    analyzer::setTwoPass 0
		}
		q -
		quiet {
		    set quiet 1
		    analyzer::setQuiet 1
		}
		v -
		verbose {
		    analyzer::setVerbose 1
		}
		W1 {
		    # filter all warnings.
		    filter::addFilters {warn nonPortable performance upgrade usage}
		}
		W2 {
		    # filter aux warnings.
		    filter::addFilters {warn nonPortable performance upgrade}
		}
		W3 -
		Wa -
		Wall {
		    # No-op do not filter anything.
		}
		pcx {
		    lappend usrPcxDirList $arg
		}
		nopcx {
		    set loadPCX 0
		}
	    }
	}
    }

    # Print the copyright information and check the license.  By setting the
    # projectInfo::printCopyright variable above we tune the output.
    # But, always call the procedure to ensure the license is checked.
    # See also the startup.tcl script that sets the projectInfo::verifyCommand

    projectInfo::printCopyright $::projectInfo::productName

    if {$errorCode >= 0} {
	Puts $errorMsg
	catch {$::projectInfo::licenseReleaseProc}
	exit $errorCode
    }

    # if no file patterns were specified, use stdin

    if {[llength $argv] == 0} {
	return {}
    }

    # find the list of valid files to check

    set result [cmdline::getfiles $argv $quiet]

    # If no valid files were specified, print the usage string and exit with
    # an error result.  Otherwise, return the list of valid files to check.

    if {[llength $result] == 0} {
	puts stdout $checkerCmdline::usageStr
	catch {$::projectInfo::licenseReleaseProc}
	exit 1
    }
    return $result
}

