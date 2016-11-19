# all.tcl --
#
# This file contains a top-level script to run all of the Debugger
# tests.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: all.tcl,v 1.2 2000/10/31 23:31:07 welch Exp $

set testsDir [file dirname [file join [pwd] [info script]]]
set tcldebuggerDir [file join $testsDir .. .. .. .. tcldebugger]
source [file join $tcldebuggerDir tests all.tcl]
