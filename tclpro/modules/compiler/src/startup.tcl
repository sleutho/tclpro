# startup.tcl --
#
#  Startup script for the TclPro bytecode compiler.
#  See procomp.tcl for a description of the call syntax and behaviour of the
#  procomp package.
#
# Copyright (c) 1998 by Scriptics Corporation.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: startup.tcl,v 1.4 2000/10/31 23:31:05 welch Exp $

package require projectInfo
package require cmdline

# Set up hook to check TclPro license keys.

#package require lictty
#set projectInfo::verifyCommand lictty::verify 

# Locate the main script, which might be wrapped.

if {![info exists tcl_platform(isWrapped)]} {

    # Make sure an unwrapped app uses an absolute pathname
    # so it can be executed from any directory.

    set home [file dirname [info script]]
    set main [file join [pwd] $home procomp]
} else {

    # The wrapped file is simply "procomp.tbc" or "procomp.tcl"

    set home ""
    set main procomp
}

# Source the script, either .tbc or .tcl flavor

foreach ext {.tbc .tcl} {
    if {[file exists $main$ext]} {
	if {$ext == ".tbc"} {
	    package require tbcload
	}
	source $main$ext
	break
    }
}
set status [procomp::run]

# Release network license and exit

#lclient::release
exit [expr {$status == 0}]
