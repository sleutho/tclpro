# setup.tcl --
# 
#	This file contains the top-level script fot the TclPro UNIX installation
#	application.
# 
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: setup.tcl,v 1.7 2001/01/25 21:44:21 welch Exp $

source projectInfo/projectInfo.tcl
source install.tcl
source messages.tcl
source unwrapsizes.tcl

namespace eval setup {
    variable installLogFile ""

    proc currTime {} {
	return [clock format [clock seconds] -format "%y%m%d-%H:%M"]
    }
    proc openLogFile {dirName} {
	if {$setup::installLogFile != ""} {
	    closeLogFile
	}
	set setup::installLogFile [open [file join $dirName INSTALL.LOG] "a"]
	setup::writeLogFile \
	    "-- Installation started on [info host] at [setup::currTime] in directory \"$dirName\"--\n"
    }
    proc writeLogFile {arg} {
	puts -nonewline $setup::installLogFile $arg
	flush $setup::installLogFile
    }
    proc closeLogFile {} {
	writeLogFile \
	    "-- Installation finished on [info host] at [setup::currTime] --\n"
	close $setup::installLogFile
	set setup::installLogFile ""
    }
}

if {[llength $argv] != 4} {
    puts stderr "Usage: $argv0 platform imageroot textmode destfile"
    exit 0
}

set tclproPlatform [lindex $argv 0]
set installImageRoot [lindex $argv 1]
set textMode [lindex $argv 2]
set tclproDestFile [lindex $argv 3]

if {[catch {
    if {$textMode == "true"} {
	source text.tcl
	textSetup::start
    } else {
	source gui.tcl
	gui::showWindow
    }
} err]} {
    puts stderr "Installer error:\n$errorInfo"
}
