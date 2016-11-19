# tkTable.tcl --
#
#	This file contains type and command checkers for the TkTable
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: tkTable.tcl,v 1.3 2000/10/31 23:30:55 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide tkTable 1.0

namespace eval tkTable {
    # A list os supported versions, ordered from earliest 
    # to most recent.

    variable supportedVers [list 2.4]

    # scanCmdsX.X --
    # Define the set of commands that need to be recuresed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds2.4 {
    }

    # checkersX.X --
    # Define the set of command-specific checkers used by this package.

    # itcl 1.5 -> Tcl 7.3
    variable checkers2.4 {
    }

    # messages --
    # Define the set of message types and their human-readable translations. 

    variable messages
    array set messages {
    }
}

# tkTable::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc tkTable::init {ver} {
    foreach name [lsort [info vars ::tkTable::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::tkTable::scanCmds$ver"} {
	    break
	}
    }
    foreach name [lsort [info vars ::tkTable::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::tkTable::checkers$ver"} {
	    break
	}
    }
    return
}

# tkTable::getMessage --
#
#	Convert the message type into a human readable
#	string.  
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the message string or empty string if the
#	message type is undefined.

proc tkTable::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# tkTable::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc tkTable::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# Checkers for specific commands --
#
#	Each checker is passed the tokens for the arguments to 
#	the command.  The name of each checker should be of the
#	form tkTable::check<Name>Cmd, where <name> is the command
# 	being checked.
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.


