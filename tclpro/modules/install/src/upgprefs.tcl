# upgprefs.tcl --
#
#	This file propagates the registry keys on Windows and preference files
#	on UNIX from a lower version of TclPro to a higher version of TclPro.
#	If the higher version of TclPro registry entries already exist, nothing
#	is performed.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: upgprefs.tcl,v 1.3 2000/10/31 23:31:15 welch Exp $


# UpgradeKeys --
#
#	This routine starts from the base key given by "$co" and the sub key
#	path given by "$srcKey" and populates all entries in the registry
#	given by the sub key "$toKey".  Entries include sub-sub keys, and
#	recursively thereof, and all values in 
#
# Arguments:
#	co	    top-level key in which the copy operation should take place
#	srcKey      source key hierarchy
#	destKey	    destination key hierarchy
#	excludeList a list of registry entries that should not be copied; each
#		    list element specifies a string that can exist anywhere in
#		    the hierarchy as a key or value name; (see known problem)
#
# Results:
#	Returns the number of keys that were actually copied over.
#
# Known problem:
#	Because each exclude list element is a string that may exist anywhere
#	in the key/value hieararchy, there can be no duplicated names in the
#	hieararchy.  For example:
#
#	    "HKEY_CURR_USER\\Scriptics\\TclPro\\1.1\\license"
#	    "HKEY_CURR_USER\\Scriptics\\TclPro\\1.1\\Debugger\\Prefs\\license"
#
#	will both be excluded if "license" appears in the exclude list.

proc UpgradeKeys {co srcKey destKey excludeList} {
    # If the specified key does not exist return immediately.

    if {[catch {registry keys "$co\\$srcKey"}]} {
	return 0
    }

    set nEntriesSet 0

    # Prepend each element in the exclude list with the source key string in
    # order to make it easier to search.

    set exclList {}
    foreach excludeEntry $excludeList {
	lappend exclList "$co\\$srcKey\\$excludeEntry"
    }

    # Don't copy any key listed in the exclude entry list.

    foreach subKey [registry keys "$co\\$srcKey"] {
	# Recursively copy all keys that exist in this source key.

	if {[lsearch -exact $exclList "$co\\$srcKey\\$subKey"] == -1} {
	    # It's OK to copy this key.

	    incr nEntriesSet [UpgradeKeys $co "$srcKey\\$subKey" \
	    			"$destKey\\$subKey" \
	    	    		$excludeList]
	}
    }

    # Copy all value entries that exist in this source key.

    foreach valueName [registry values "$co\\$srcKey"] {
        set value [registry get "$co\\$srcKey" $valueName]

        # Don't copy any value entry listied in the exclude entry list.

	if {[lsearch -exact $exclList "$co\\$srcKey\\$valueName"] == -1} {
	    # It's OK to copy this value.

	    registry set "$co\\$destKey" $valueName $value
	    incr nEntriesSet
	}
    }

    return $nEntriesSet
}


catch {
    switch $::tcl_platform(platform) {
	"windows" {
	    package require registry

	    set base "HKEY_CURRENT_USER\\SOFTWARE\\Scriptics\\TclPro"
	    set excludeEntries [list "license"]

	    if {[catch {registry keys "$base\\1.2"}]} {
		# TclPro 1.2 has never been installed!

		if {! [catch {registry keys "$base\\1.1"}]} {
		    # TclPro 1.1 was used.  Upgrade these prefs.

		    UpgradeKeys $base "1.1" "1.2" $excludeEntries
		} elseif {! [catch {registry keys "$base\\1.0"}]} {
		    # TclPro 1.0 was used.  Upgrade these prefs.

		    UpgradeKeys $base "1.0" "1.2" $excludeEntries
		}
	    }

	    # Have this file delete itself before it exits.  This is needed
	    # because Wise delete file command seems to be broken.

	    catch {file delete [info script]}
	}
	"unix" {
	    set base [file join ~ .TclPro]
	    set excludeEntries [list "License"]

	    if {![file isdir [file join $base 1.2]]} {
		# TclPro 1.2 has never been installed!

		if {[file isdir [file join $base 1.1]]} {
		    # TclPro 1.1 was used.  Upgrade these prefs.

		    file copy [file join $base 1.1] [file join $base 1.2]
		} elseif {[file isdir [file join $base 1.0]]} {
		    # TclPro 1.0 was used.  Upgrade these prefs.

		    file copy [file join $base 1.0] [file join $base 1.2]
		}

		foreach excludeEntry $excludeEntries {
		    file delete [file join ~ $base 1.2 $excludeEntry]
		}
	    }
	}
    }
}
