# filter.tcl --
#
#	This file implements the analyzer's filter.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# SCCS: @(#) filter.tcl 1.5 98/07/24 13:56:33

namespace eval filter {
    
    # The array of messages types to filter.

    variable filters

    # The array of messageIDs to supress.

    variable suppressor
}

# filter::addFilters --
#
#	Add a set of filters that suppresses certain types
#	of error messages or warnings.
#
# Arguments:
#	msgTypes	The list of message types to filter.
#
# Results:
#	None.

proc filter::addFilters {msgTypes} {
    foreach type $msgTypes {
	set filter::filters($type) 1
    }
    return
}

# filter::addSuppressor --
#
#	Add a set of filters that suppresses certain types
#	of messageIDs.
#
# Arguments:
#	mids	The list of messageIDs to supress.
#
# Results:
#	None.

proc filter::addSuppressor {mids} {
    foreach mid $mids {
	set filter::suppressor($mid) 1
    }
    return
}

# filter::clearFilters --
#
#	Reset the filter to empty.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc filter::clearFilters {} {
    variable filters
    catch {unset filters}
    array set filters {}
    return
}

# filter::clearSuppressors --
#
#	Clear all current message id suppressors.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc filter::clearSuppressors {} {
    variable suppressor
    catch {unset suppressor}
    array set suppressor {}
    return
}

# filter::removeFilters --
#
#	Remove a set of filters that suppresses certain types
#	of error messages or warnings.
#
# Arguments:
#	msgTypes	The list of message types to stop filtering.
#
# Results:
#	None.

proc filter::removeFilters {msgTypes} {
    foreach type $msgTypes {
	if {[info exists filter::filters($type)]} {
	    unset filter::filters($type)
	}
    }
    return
}

# filter::suppress --
#
#	Determines if the message should be filtered.
#
# Arguments:
#	msgTypes	A list of msgTypes associated with
#			the reported message.
#	mid		The messageID associated with the message.
#
# Results:
#	Returns 1 if the message should be suppressed, 0 if
#	it should be displayed.

proc filter::suppress {msgTypes mid} {
    # Iterate over all the msgTypes for this message, if the 
    # number of matches equals the number of message types 
    # then suppress this message.

    set count 0
    set need  [llength $msgTypes]
    foreach type $msgTypes {
	if {[info exists filter::filters($type)]} {
	    incr count
	}
    }
    if {$count == $need} {
	return 1
    }

    # If the messageID for this message is on the list
    # then suppress this messgae.
    
    set mid [namespace tail $mid]
    if {[info exists filter::suppressor($mid)]} {
	return 1
    }

    return 0
}



