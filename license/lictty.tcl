# lictty.tcl --
#
#	This module defines the TTY interface for the license 
#	software.
#	Please make sure that changes to this file are reflected in
#	lictty-stub.tcl.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: lictty.tcl,v 1.3 2000/08/01 01:49:55 welch Exp $

package provide lictty 1.0

package require lic

namespace eval lictty {
    variable origStatus
    variable key {}
    variable registeredName {}
    variable srvInfo {{} {}}
    variable srvSiteInfo {{} {}}
}

# lictty::ShowLicense --
#
#	Display the TclPro license.
#
# Arguments:
#	None
#
# Results:
#	None.

proc lictty::ShowLicense {} {

    # Extract the license from the wrapped application.
    # Write the contents to the file system, and then 
    # exec "more" on the temp file to display the license
    # terms.

    set file [open license.txt r]
    set data [read $file]
    close $file
    
    set fileName "/tmp/temp[pid].txt"
    set temp [open $fileName w]
    puts $temp $data
    close $temp
    
    exec more $fileName 2>@stderr >@stdout <@stdin
    file delete $fileName

    puts stdout "\n"
    puts [lictty::format70Columns $lic::prolicense(msg,agree,text)]
    puts stdout "\n"
    puts -nonewline [lictty::format70Columns \
	    "Do you accept the license terms? \[accept/quit\] "]
    flush stdout
    gets stdin reply
    set reply [string trim [string tolower $reply]]
    while {$reply != "accept"} {
	if {$reply == "quit"} {
	    exit
	}
	puts -nonewline [lictty::format70Columns \
		"Please type either \"accept\" or \"quit\": "]
	flush stdout
	gets stdin reply
	set reply [string trim [string tolower $reply]]
    }
}

# lictty::showPrompt --
#
#	Display the status of the license key, and ask the user
#	if they wish to enter a new key.
#
# Arguments:
#	showLicense	Boolean, if true then show the license terms.
#	key		The license key.
#	first		Boolean, indicating if the routine has iterated.
#
# Results:
#	None.

proc lictty::showPrompt {showLicense} {
    if {$showLicense} {
	catch { ShowLicense }
    }

    if {$lic::config(-site)} {
	set optionsType "nolic"
	set optionList [list "_undefined_option_" "1" "2"]
    } else {
	set optionsType "lic"
	set optionList [list "1" "2" "3"]
    }

    # See if their existing key is any good

    set success 0
    set srvSiteMsg {}

    while {1} {
	# Don't cache the value of srvSiteInfo.  Update it's value based
	# on the contents of the license file.  Set to {} to force this
	# update.

	set ::lictty::srvSiteInfo {}

        set lictty::origStatus [lic::probe \
        	text,short \
        	::lictty::registeredName \
		::lictty::key	       keyStatus      keyMsg \
		::lictty::srvInfo      srvStatus      srvMsg \
		::lictty::srvSiteInfo  srvSiteStatus  srvSiteMsg]

	if {!$lic::config(-site) && ($keyMsg != {})} {
	    puts "Named User Key Information:"
	    foreach line [split $keyMsg \n] {
	        puts "    $line"
	    }
	    if {!$lic::config(-site) && ($lictty::registeredName != {})} {
	        puts -nonewline "    [format $lic::messages(registered_to,short) ""]"
	        puts $lictty::registeredName
	    }
	}
	if {!$lic::config(-site) && ($srvMsg != {})} {
	    puts "License Server Information:\n    $srvMsg"
	}
	if {($srvSiteMsg != {})} {
	    puts "$::lictty::srvSiteInfo"
	    puts "Site License Server Information:\n    $srvSiteMsg"
	}
	puts -nonewline [lictty::format70Columns \
		$lic::welcome(msg,text,$optionsType,options)]
	flush stdout
	set selection [string trim [gets stdin]]

	switch -- [lsearch $optionList $selection] {
	    0 {
		if {$lictty::registeredName == ""} {
		    lictty::GetRegisteredName ::lictty::registeredName
		}
		if {$::lictty::registeredName != ""} {
		    set success [lictty::GetKey ::lictty::key keyMsg]
		}
	    }
	    1 {
		set success [lictty::GetServer ::lictty::srvInfo srvMsg]
	    }
	    2 {
		break
	    }
	    default {
		puts -nonewline [lictty::format70Columns [format \
			"\n$lic::welcome(msg,text,lic,options,error)\n" \
			$selection] ]
	    }
	}

	puts ""
    }
}

# lictty::SaveEntry --
#
# 	Saves the entry given by 'entry' using the lic::* APIs and catches
#	and displays I/O errors that are encountered during saving.
#
# Arguments:
#	entry		one of "key", "name", or "erver"
#	value		the actual value to save
#
# Results:
#	1 if successful, 0 otherwise

proc lictty::SaveEntry {entry value} {
    if {[catch {
	switch -- $entry {
	    company {
		lic::saveCompanyName $value
	    }
	    key	{
		lic::savePersonalKey $value
	    }
	    server {
		lic::saveServerInfo [lindex $value 0] [lindex $value 1]
	    }
	}
    } error]} {
	puts [lictty::format70Columns \
		"Unable to save this value: $error"]
	return 0
    }

    return 1
}

# queryBlankReply --
#
#	A simple proc. to ask the user if s/he wansts to erase a value?
#
# Arguments:
#	None.
#
# Results:
#	Returns 1 if the user answers "y" or "Y", 0 otherwise.

proc queryBlankReply {} {
    puts -nonewline [lictty::format70Columns \
	    "Are you sure you want to erase this value (y/n) \[n\]? "]
    flush stdout
    set reply [string trim [gets stdin]]
    if {($reply == "") || [string match {[yY]*} $reply]} {
	return 1
    } else {
	return 0
    }
}

# lictty::GetRegisteredName --
#
#	Prompts the user for a registration name and confirms a non-
#	empty value with the user.  A confirmed value is written to disk.
#
# Arguments:
#	registeredNameVar	a variable to update with the new valid entry
#
# Results:
#	Nothing.

proc lictty::GetRegisteredName {registeredNameVar} {
    upvar 1 $registeredNameVar registeredName

    puts -nonewline [lictty::format70Columns \
	"\n$lic::welcome(msg,text,lic,username)"]
    flush stdout
    set newRegisteredName [string trim [gets stdin]]

    if {$newRegisteredName == {}} {
        puts [lictty::format70Columns [concat \
	        "\nYou must enter a non-empty value for the "\
		"user name."] ]
        flush stdout
    } else {
        puts -nonewline [lictty::format70Columns [format [concat \
		"\nPlease confirm the user name of \"%s\"." \
		"NOTE: You will not be able to change this value in the " \
		"future. (y/n) \[n\]?" ] \
		$newRegisteredName] ]
	flush stdout
	set reply [string trim [gets stdin]]
	if {($reply != "") && [string match {[yY]*} $reply]} {
            set success [lictty::SaveEntry company $newRegisteredName]
	    if {$success} {
	        set registeredName $newRegisteredName
	    }
	}
    }

    return
}

# lictty::GetKey --
#
#	Prompts the user for a key and validates it. If the entry is
#	invalid, the user is informed and nothing else is performed.
#	If the entry is valid the entry is written to disk. If the
#	entry is an empty string, the user is querried as to whether
#	the value on dist should be erased.
#
# Arguments:
#	keyVar		a variable to update with the new valid entry
#	shortMsgVar	a variable to update with a short message string.
#
# Results:
#	Returns 1 if a valid entry is written to disk, 0 in all other cases.

proc lictty::GetKey {keyVar shortMsgVar} {
    upvar 1 $keyVar key $shortMsgVar shortMsg

    puts -nonewline [lictty::format70Columns \
	    "\nEnter a new license key and press enter: "]
    flush stdout
    set newKey [string trim [gets stdin]]

    if {($newKey == {}) && [queryBlankReply]} {
	# Blank entry: user said it's OK to erase the value in file.

	set success 1
	set shortMsg ""
    } elseif {($newKey == {})} {
	# Blank entry: user declined erasure.

	set success 0
    } else {
	# Validate the entry.  We need both short and long messages.

        set status [lic::getPersonalKey text,lic $newKey msg]
        set status [lic::getPersonalKey text,short $newKey shortMsg]
	set shortMsg [string trim $shortMsg]

        switch -glob -- $status {
    	    error* {
		puts "\n[lictty::format70Columns $msg]"
		set success 0
	    }
	    warnTempKey {
		# An evaluation key was entered.

    	        if {$lictty::origStatus == "ok"} {
    		    # Ask if we should override good key with this new
		    # temporary key.

		    puts ""
    		    puts -nonewline [lictty::format70Columns \
    			    $lic::tempKey(msg,text)]
    		    flush stdout
    		    set reply [string trim [gets stdin]]

    		    if {($reply == "") || [string match {[nN]*} $reply]} {
			set success 0
    		    } else {
			set licgui::origStatus $status

			set success 1
		    }
    	        } else {
		    set success 1
		}
    	    }
    	    "ok" {
    	        set success 1
	    }
    	}
    }

    if {$success} {
	# Commit the newly entered valid value.

	set success [lictty::SaveEntry key $newKey]
	if {$success} {
            set key $newKey
	}
    }

    return $success
}

# lictty::GetServer --
#
#	Prompts the user for the name of a host/port and attempts to
#	contact a valid entry.  If the entry is invalid, the user
#	is informed and nothing else is performed.  If the entry is
#	valid and the server is available, the entry is written to disk.  
#	If the entry is valid, but the server is not avaialbe, the user
#	is querried on whether to commit the entry to disk.
#
# Arguments:
#	serverVar	a variable to update with the new valid entry
#	shortMsgVar	a variable to update with a short message string.
#
# Results:
#	Returns 1 if a valid entry is written to disk, 0 in all other cases.

proc lictty::GetServer {serverVar shortMsgVar} {
    upvar 1 $serverVar serverInfo

    puts -nonewline [lictty::format70Columns [format "%s%s%s" \
	    "\nEnter the name of the host machine and port number, delimited " \
	    "by a \":\" character (e.g., \"mars:2577\"), where a Ajuba Solutions" \
	    " License Server is running: "] ]
    flush stdout
    set newServerInfo [string trim [gets stdin]]
    set newSplitServerInfo [split $newServerInfo ":"]

    if {($newServerInfo == "") && [queryBlankReply]} {
	# Blank entry; user said it's OK to erase the value in file.

	set success 1
    } elseif {$newServerInfo == ""} {
	# Blank entry; user declined erasure.

	set success 0
    } elseif {! [lic::serverParse $newServerInfo]} {
	# The entry is malformed.  Inform the user.

	puts ""
	puts [lictty::format70Columns [format \
		$lic::messages(bad_serverPort) $newServerInfo] ]

	set success 0
    } elseif {[catch {lclient::probe $newSplitServerInfo [info hostname]} error]} {
	# The server is not responding favorably.
 
	set msg [format "%s%s%s%s" \
		[format $lic::noserver(msg,text,lic) $newServerInfo] \
		"\n\n    " "$newServerInfo: " $error]
	puts [lictty::format70Columns "\n[lictty::format70Columns $msg]\n"]
	puts -nonewline [lictty::format70Columns [concat \
		"Would you like accept this information anyway?  " \
		"\[y/n\] \[n\]:"] ]
	flush stdout
	set reply [string trim [gets stdin]]
	if {($reply == "") || [string match {[Nn]*} $reply]} {
	    set success 0
	} else {
	    set success 1
	}
    } else {
	set success 1
	# puts [lictty::format70Columns [format \
		"\n$lic::serverok(msg,text)" \
		"[lindex $newServerInfo 0]:[lindex $newServerInfo 1]"] ]
    }

    if {$success} {
	set msg "\n$lic::valid(msg,text)"
	set newServerInfo [split $newServerInfo ":"]
        set success [lictty::SaveEntry server \
		[list [lindex $newServerInfo 0] [lindex $newServerInfo 1]]]
	if {$success} {
	    set serverInfo $newServerInfo
	}
    }

    return $success
}


# lictty::format70ColumnLine --
#
#	Formats the given string to be of multiple lines, with each line no
#	longer than 70 characters.
#
# Arguments:
#	string		The long string to format into several lines.
#
# Results:
#	The formatted line, with embedded "\n" characters to break the lines
#	accordingly.

proc lictty::format70Columns {string} {
    set formattedString ""
    set formattedLine ""
    foreach word [split $string { }] {
	if {[string first "\n" $word] >= 0} {
	    # The word has embedded newlines.  Format the string without
	    # stripping out the newline chars.

	    set len [expr {[string length [lindex [split $word "\n"] 0]] - 1}]
	    if {$len > 0} {
		if {[expr {[string length $formattedLine] + $len}] > 70} {
		    append formattedString "$formattedLine\n"
		    set formattedLine ""
		}
	    }
	    append formattedString "$formattedLine$word "
	    set formattedLine ""
	} else {
	    if {[expr {[string length $formattedLine] \
		    + [string length $word]}] > 70} {
		append formattedString "$formattedLine\n"
		set formattedLine ""
	    }
	    append formattedLine "$word "
	}
    }
    append formattedString $formattedLine
    return $formattedString
}

# lictty::verify --
#
#       Verify the license is valid for the application.
#
# Arguments:
#       name    The application name.
#       ver     The version of the application.
#       prod    The productID of the application.
#
# Results:
#       None.  If the key does not exist, is invalid or is 
#       expired, then exit the application.
 
proc lictty::verify {name ver prod registeredNameVarName} {
    upvar 1 $registeredNameVarName registeredName

    # The message returned from getMsg contains the message,
    # followed by two newlines and the key/expire info.  We
    # only want the message, so extract the string before
    # the first newline.

    set status [lic::getMsg text {} msg $name registeredName]
    if {$status != "ok"} {
	set msg [lindex [split $msg \n] 0]
	set msg [format "$msg" $name]
    }

    if {[string match error* $status]} {
	puts "\n[lictty::format70Columns $msg]"
	exit
    } elseif {[string match warn* $status]} {
	puts [lictty::format70Columns $msg]
    }
    return
}

