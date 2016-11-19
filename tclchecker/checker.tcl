# checker.tcl --
#
#       This file imports the checker functionality, and
#       provides an interface to it. 
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: checker.tcl,v 1.13 2001/10/17 18:08:05 andreas_kupries Exp $

package provide checker 1.4

# Get the required packages...
# This package imports the "parse" command.
package require parser

# This package imports the tbc loading functionality
if {[catch {package require tbcload}] == 1} {
    set ::hasLoader 0
} else {
    set ::hasLoader 1
}

# Unwrapped checker can be run from any working directory
# if {![info exists tcl_platform(isWrapped)]} {
#     cd [file dirname [file join [pwd] [info script]]]
# }

namespace eval checker {
    variable libdir [file dirname [info script]]
}

# ::checker::source --
#
#	Get the file... either as a tbc or a .tcl file.
#
# Arguments:
#	path              The file name to be loaded
#
# Results:
#       The file is loaded, and may change pretty much anything.

proc ::checker::source {path} {
    set stem [file rootname $path]
    set loadTcl 1
    if {($::hasLoader == 1) && ([file exists $stem.tbc] == 1)} {
        set loadTcl [catch [list uplevel 1 source $stem.tbc] msg]
    }
    if {$loadTcl == 1} {
        uplevel 1 [list source $stem.tcl]
    }
}

# ::checker::check --
#
#	This is the main routine that is used to
#       scan and then analyze a script.
#
# Arguments:
#	script            The Tcl script to check
#
# Results:
#       The found warnings and errors. The format of the return
#       list is as follows:
#           {{{error message} {location}} ...}

proc ::checker::check {script} {

    # Initialize the internal variables
    set ::message::collectedResults ""
    ::analyzer::init
    
    # Assign the script to scan
    set ::analyzer::script $script

    # First pass analysis
    set ::analyzer::scanning 1
    analyzer::checkScript
    set ::analyzer::scanning 0
    # Second phase analysis
    analyzer::checkScript

    # Return the result
    return $::message::collectedResults
}

::checker::source [file join $::checker::libdir location.tcl]
::checker::source [file join $::checker::libdir analyzer.tcl]
::checker::source [file join $::checker::libdir context.tcl]
::checker::source [file join $::checker::libdir userproc.tcl]
::checker::source [file join $::checker::libdir configure.tcl]
::checker::source [file join $::checker::libdir filter.tcl]
::checker::source [file join $::checker::libdir message.tcl]
::checker::source [file join $::checker::libdir checkerCmdline.tcl]

# This code must be run after the other checker files have been
# sourced in, in order for the namespace imports to work. It provides
# the public API for checker extensions.
namespace eval checker {
    # import internal functions

    namespace import ::configure::register
    namespace import ::analyzer::*
}

# Configure the checker system
::analyzer::init
