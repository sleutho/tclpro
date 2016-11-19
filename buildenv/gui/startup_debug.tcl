# startup.tcl --
#
#	This is the entry point into the build environment gui program.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file license.terms.
#
# RCS: @(#) $Id: startup_debug.tcl,v 1.4 2000/10/31 23:30:47 welch Exp $

lappend auto_path [file join [file dirname [info script]] ..]

package require buildenvGui

wm withdraw .

if {[lsearch $argv "-listbox"] != -1} {
    set use_tree 0
} else {
    set use_tree 1
}

::gui::create
::ModuleOps::openProject /home/wart/cvs/connect2.0/buildenv/test.bpj
::ModuleHints::setDataFile /home/wart/cvs/connect2.0/xmlserver/linux/module_data.tcl
::gui::UpdateModulelist
