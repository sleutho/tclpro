# startup.tcl --
#
#	This is the entry point into the build environment gui program.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: startup.tcl,v 1.8 2000/10/31 23:30:47 welch Exp $

lappend auto_path [file join [file dirname [info script]] ..]

package require buildenvGui

wm withdraw .

if {[lsearch $argv "-listbox"] != -1} {
    set use_tree 0
} else {
    set use_tree 1
}

::gui::create
