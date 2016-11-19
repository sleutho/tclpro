# startup.tcl --
#
#	This file is the primary entry point for the 
#       TclPro Checker.
#
# Copyright (c) 1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: check.tcl,v 1.3 2000/10/31 23:31:04 welch Exp $

# Initialize the checker library

package require projectInfo
package require cmdline

set odir [pwd]
cd /home/hershey/cvs/tclchecker
source checker.tcl
cd $odir
#package require checker

# process the commandline args

set filesToCheck [checkerCmdline::init]

# load the pcx extension files

if {[configure::packageSetup] == 0} {
    exit 1
}

# Register our information gathering procedure. This replaces
# the usual silent mode with a "print to stdout" procedure.

set ::message::displayProc ::message::displayTTY

# Call the main routine that checks all the files.

analyzer::check $filesToCheck

# Release network license

#lclient::release

# Return an error code if any of the messages generated were 
# error messages.

if {[analyzer::getErrorCount] > 0} {
    exit 1
} else {
    exit
}

