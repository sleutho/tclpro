# prowrapCmd.tcl --
#
#	The main file for the "TclPro Wrapper Utility Command-Line Interface"
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: startup.tcl,v 1.5 2001/01/24 19:41:24 welch Exp $

if {[catch {package require tbcload}] == 1} {
    set ::hasLoader 0
} else {
    set ::hasLoader 1
}

proc ::Source {path} {
    set stem [file rootname $path]
    set loadTcl 1
    if {($::hasLoader == 1) && ([file exists $stem.tbc] == 1)} {
	set loadTcl [catch [list uplevel 1 source $stem.tbc]]
    }
    
    if {$loadTcl == 1} {
	uplevel 1 [list source $stem.tcl]
    }
}

package require projectInfo
package require cmdline
#package require licdata
#package require lic
#package require lclient

# Set up hook to check TclPro license keys.
# This will be hit by checkerCmdline::init

#package require lictty
#set projectInfo::verifyCommand lictty::verify 

# Load wrapper source relative to startup script
if {![info exists tcl_platform(isWrapped)]} {
    set home [file join [pwd] [file dirname [info script]]]
    Source [file join $home prowrap.tcl]
} else {
    Source prowrap.tcl
}

# Perform all "command-line" level processing, including "-uses" specificatins.

set err [catch {
    proWrap::processCommandLine $argc $argv
} errors]

projectInfo::printCopyright "TclPro Wrapper"

if {$proWrap::printHelpMessage} {
    puts $proWrap::msgStrings(0_USAGE_STATEMENT)
    #lclient::release
    exit $err
}

if {!$err} {
    set err [catch {
	proWrap::validateFlags
	proWrap::createTaskList tasks
	proWrap::processTaskList tasks
    } errors]
}

if {$err} {
    puts [join $errors \n]
}

# Remove any temporary directory that may have been created during the wrapping
# process.

catch {proWrap::tempDirectory delete}

# Release network license

#lclient::release

exit $err
