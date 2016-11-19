# lictty-stub.tcl --
#
#	This module defines a stubbed version of the the TTY interface for
#	the license software. It is used to build and create our own tools,
#	for which we don't want to have license restrictions.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: lictty-stub.tcl,v 1.3 2000/08/01 01:49:55 welch Exp $

package provide licttyStub 1.0

namespace eval lictty {
}

# lictty::showPrompt --
#
#	Display the status of the license key, and ask the user
#	if they wish to enter a new key.
#
# Arguments:
#	showLicense	Boolean, if true then show the license terms.
#	key		The license key.
#	loop		Boolean, indicating if the routine has iterated.
#
# Results:
#	None.

proc lictty::showPrompt {showLicense {key {}} {loop 1}} {
    error "called the lictty::showprompt stub!"
}

# lictty::verify --
#
#	Verify the license is valid for the application.
#	This version always succeeds.
#
# Arguments:
#	name	The application name.
#	ver	The version of the application.
#	prod	The productID of the application.
#
# Results:
#	None.  If the key does not exist, is invalid or is 
#	expired, then exit the application.

proc lictty::verify {name ver prod registeredNameVarName} {
}


