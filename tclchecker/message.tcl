# message.tcl --
#
#	This file defines the messaging system for the analyzer.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# SCCS: %Z% %M% %I% %E% %U%

namespace eval message {

    # Define the set of generic message types, their filtering categories,
    # and their human-readable translations. 

    array set messages {
	argAfterArgs	{"argument specified after \"args\"" err}
	argsNotDefault	{"\"args\" cannot be defaulted" err}
	badBoolean	{"invalid Boolean value" err}
	badByteNum	{"invalid number, should be between 0 and 255" err}
	badColorFormat	{"invalid color name" err}
	badCursor	{"invalid cursor spec" err}
	badFloat	{"invalid floating-point value" err}
	badIndex	{"invalid index: should be integer or \"end\"" err}
	badInt		{"invalid integer" err}
	badKey		{"invalid keyword \"%2$s\" must be: %1$s" err}
	badList		{"invalid list: %1$s" err}
	badLevel	{"invalid level" err}
	badMode		{"access mode must include either RDONLY, WRONLY, or RDWR" err}
	badOption	{"invalid option \"%2$s\" must be: %1$s" err}
	badPixel	{"invalid pixel value" err}
	badResource	{"invalid resource name" err}
	badSwitch	{"invalid switch: \"%1$s\"" err}
	badVersion	{"invalid version number" err}
	badWholeNum	{"invalid value \"%1$s\": must be a positive integer" err}
	mismatchOptions {"the specified options cannot be used in tandem" err}
	noExpr		{"missing an expression" err}
	noScript	{"missing a script after \"%1$s\"" err}
	noSwitchArg	{"missing argument for %1$s switch" err}
	nonDefAfterDef	{"non-default arg specified after default" err}
	nonPortChannel	{"use of non-portable file descriptor, use \"%1$s\" instead" warn nonPortable}
	nonPortCmd	{"use of non-portable command" warn nonPortable}
	nonPortColor	{"non-portable color name" warn nonPortable}
	nonPortCursor	{"non-portable cursor usage" warn nonPortable}
	nonPortFile	{"use of non-portable file name, use \"file join\"" warn nonPortable}
	nonPortOption	{"use of non-portable option" warn nonPortable}
	nonPortVar	{"use of non-portable variable" warn nonPortable}
	numArgs		{"wrong # args" err}
	numListElts	{"wrong # of list elements" err}
	obsoleteCmd	{"Obsolete usage, use \"%1$s\" instead" err}
	parse 		{"parse error: %1$s" err}
	procNumArgs	{"wrong # args for user-defined proc: \"%1$s\"" err}
	tooManyFieldArg	{"too many fields in argument specifier" err}
	warnDeprecated	{"deprecated usage, use \"%1$s\" instead" warn upgrade}
	warnExportPat	{"export patterns should not be qualified" warn}
	warnExpr	{"use curly braces to avoid double substitution" warn performance}
	warnExtraClose	{"unmatched closing character" warn usage}
	warnIfKeyword	{"deprecated usage, use else or elseif" warn}
	warnNamespacePat {"glob chars in wrong portion of pattern" warn}
	warnPattern	{"possible unexpected substitution in pattern"	warn}
	warnReserved	{"keyword is reserved for use in %1$s" warn upgrade}
	warnRedefine	{"%1$s %2$s redefines %3$s %2$s in file %4$s on line %5$s" warn usage}
	warnUndefProc	{"undefined procedure: %1$s" warn}
	warnUnsupported	{"unsupported command, option or variable: use %1$s" warn upgrade}
	warnVarRef	{"variable reference used where variable name expected" warn}
	winAlpha	{"window name cannot begin with a capital letter" err}
	winBeginDot	{"window name must begin with \".\"" err}
	winNotNull	{"window name cannot be an empty string" err}
    }

    # This var is the name of the proc to execute when a message
    # is being displayed--the default is collectMsg, which keeps messages silent,
    # but you can change it to displayTTY.

    variable displayProc message::collectMsg

    # Write to <outChannel> instead of the default stdout so 
    # we can have control over re-directing the output without
    # messing around with stdout.

    variable outChannel stdout
}

# message::show --
#
#	Create the message to display and call the command
#	that will dump the error message.
#
# Arguments:
#	mid		The message id for the message.
#	errRange	The range of the error relative to the start
#			of the current analyzer script.
#	clientData	Extra data used when generation the message.
#
# Results:
#	None.

proc message::show {mid errRange clientData} {
    $message::displayProc $mid $errRange $clientData [analyzer::getQuiet]
    return
}

# message::showSummary --
#
#	Show summary information.
#
# Arguments:
#	None.
#
# Results:
#	None.  Summary info is printed to stdout.

proc message::showSummary {} {
    # Show the packages loaded and checked.

    Puts ""
    Puts "Packages Checked | Version"
    Puts "-----------------|--------"
    array set pkgs [configure::getInitPkgs]
    foreach name [lsort -dictionary [array names pkgs]] {
	switch $name {
	    coreTcl {
		set pkg "tcl"
	    }
	    coreTk {
		set pkg "tk"
	    }
	    incrTcl {
		set pkg "\[incr Tcl\]"
	    } 
	    default {
		set pkg $name
	    }
	}
	Puts [format "%-17.16s  %-s" $pkg $pkgs($name)]
    }
    
    # Show Number of errors and warnings.

    Puts ""
    Puts "Number of Errors:   [analyzer::getErrorCount]"
    Puts "Number of Warnings: [analyzer::getWarningCount]"
    Puts ""

    # Show names of command that were called but never defined.
    # Currently, Tk is not defininig widget names as procs.
    # Ignore all unknown commands that start with period.

    if {$analyzer::unknownCmds != {}} {
        Puts "Commands that were called but never defined:"
        Puts "--------------------------------------------"
        foreach cmd $analyzer::unknownCmds {
	    Puts $cmd
	}
        Puts ""
    }

    return
}

# message::setDisplayProc --
#
#	Set the display proc to use when printing out messages.
#
# Arguments:
#	procName	The name of a fully qualified proc name.
#			The proc must take three args: mid, errRange
#			and clientData.  See the header for 
#			message::show for details on these args.
#
# Results:
#	None.

proc message::setDisplayProc {procName} {
    set analyzer::displayProc $procName
    return
}

# message::getMessage --
#
#	Convert the messageID into a human-readable message.
#
# Arguments:
#	mid	The messageID.  If the mid is not qualified,
#		it is defined in the analyzer's generic message
#		list.  Otherwise, it is defined in the namespace
#		of the qualified mid.
#
# Results:
#	The human readable message.

proc message::getMessage {mid} {
    variable messages

    set ns   [namespace qualifiers $mid]
    set tail [namespace tail $mid]
    set result {}
    if {$ns == {}} {
	if {[info exists messages($tail)]} {
	    set result [lindex $messages($tail) 0]
	} else {
	    set result $tail
	}
    } else {
	set result [${ns}::getMessage $mid]
    }
    return $result
}

# message::getTypes --
#
#	Convert the messageID into a list of message types that 
#	apply to this message.
#
# Arguments:
#	mid	The messageID.  If the mid is not qualified,
#		it is defined in the analyzer's generic message
#		list.  Otherwise, it is defined in the namespace
#		of the qualified mid.
#
# Results:
#	A list of message type keywords.  If none are defined, the message is of type "err".

proc message::getTypes {mid} {
    variable messages

    set ns   [namespace qualifiers $mid]
    set tail [namespace tail $mid]
    set result {}
    if {$ns == {}} {
	if {[info exists messages($tail)]} {
	    set result [lrange $messages($tail) 1 end]
	} else {
	    set result err
	}
    } else {
	set result [${ns}::getTypes $mid]
    }
    return $result
}

# message::displayTTY --
#
#	Display the output to a standard tty display.
#
# Arguments:
#	mid		The message id for the message.
#	errRange	The range of the error relative to the start
#			of the current analyzer script.
#	clientData	Extra data used when generation the message.
#
# Results:
#	None.

proc message::displayTTY {mid errRange clientData quiet} {
    set pwd      [pwd]
    set file     [analyzer::getFile]
    set line     [analyzer::getLine]
    set script   [analyzer::getScript]
    set cmdRange [analyzer::getCmdRange]

    # Pwd is automatically appended to relative paths to avoid conflicts
    # with wrapped files.  However this makes the strings very verbose.
    # If the file's path begins with [pwd] then strip off that string.

    if {[string match $pwd/* $file]} {
	# The length of PWD plus one for the file separator.

	set len [expr {[string length $pwd] + 1}]
	set file [string range $file $len end]
    }

    if {$errRange != {}} {
	set cmdStr   [parse getstring $script $cmdRange]
	set cmdIndex [parse charindex $script $cmdRange]
	set tokIndex [parse charindex  $script $errRange]
	
	# Scan through the command string looking for the
	# line the error occured on.  When the loop is
	# done, prevIndex and nextIndex point to the
	# start and end of the error line.

	set errIndex  [expr {$tokIndex - $cmdIndex}]
	set prevIndex -1
	set nextIndex 0
	set subStr    $cmdStr
	while {1} {
	    set prevIndex $nextIndex
	    set charIndex [string first \n $subStr]
	    if {$charIndex >= 0} {
		incr nextIndex [expr {$charIndex + 1}]
		set subStr [string range $cmdStr $nextIndex end]
	    } else {
		set nextIndex [expr {[string length $cmdStr] + 2}]
		break
	    }
	    if {$nextIndex >= $errIndex} {
		break
	    }
	    incr line
	}

	# Scan the error line adding spaces and tabs to the carrot
	# string foreach letter or tab in the error string.
	# When this is complete, the "carrot" string will be
	# a string with a "^" just under the word that caused
	# the error.

	set errStr   [string range $cmdStr $prevIndex $errIndex]
	set cmdStr   [string range $cmdStr $prevIndex [expr {$nextIndex - 2}]]
	set numTabs  [regsub -all \t $errStr \t errStr]
	set numChar  [expr {$errIndex - $prevIndex - $numTabs}]
	for {set i 0} {$i < $numTabs} {incr i} {
	    append carrot "\t"
	}
	for {set i 0} {$i < $numChar} {incr i} {
	    append carrot " "
	}
	append carrot "^"
    } else {
	set cmdStr [parse getstring $script $cmdRange]
	set index  [string first \n $cmdStr]
	if {$index > 0} {
	    set cmdStr [string range $cmdStr 0 [expr {$index - 1}]]
	}
	set carrot "^"
    }

    set msg    [eval [list format [message::getMessage $mid]] $clientData]
    set logMsg "$file:$line ([namespace tail $mid]) $msg"

    if {[catch {
	Puts $logMsg
	if {!$quiet} {
	    Puts $cmdStr
	    Puts $carrot
	}
    }]} {
	exit
    }
}

# ::message::collectMsg --
#
#	This is the routine that collects the results from
#       the checker runs. The final results are stored in 
#       the variable ::message::collectedResults, which has
#       to be cleared and retrieved by the calling 
#       application.
#
# Arguments:
#	mid		The message id for the message.
#	errRange	The range of the error relative to the start
#			of the current analyzer script.
#	clientData	Extra data used when generation the message.
#
# Results:
#       none

proc ::message::collectMsg {mid errRange clientData quiet} {
    set line     [analyzer::getLine]
    set script   [analyzer::getScript]
    set cmdRange [analyzer::getCmdRange]

    if {$errRange != {}} {
	set cmdStr   [parse getstring $script $cmdRange]
	set cmdIndex [parse charindex $script $cmdRange]
	set tokIndex [parse charindex  $script $errRange]
	
	# Scan through the command string looking for the
	# line the error occured on.  When the loop is
	# done, prevIndex and nextIndex point to the
	# start and end of the error line.

	set errIndex  [expr {$tokIndex - $cmdIndex}]
	set prevIndex -1
	set nextIndex 0
	set subStr    $cmdStr
	while {1} {
	    set prevIndex $nextIndex
	    set charIndex [string first \n $subStr]
	    if {$charIndex >= 0} {
		incr nextIndex [expr {$charIndex + 1}]
		set subStr [string range $cmdStr $nextIndex end]
	    } else {
		set nextIndex [expr {[string length $cmdStr] + 2}]
		break
	    }
	    if {$nextIndex >= $errIndex} {
		break
	    }
	    incr line
	}
    } else {
	set cmdStr [parse getstring $script $cmdRange]
	set index  [string first \n $cmdStr]
	if {$index > 0} {
	    set cmdStr [string range $cmdStr 0 [expr {$index - 1}]]
        }
        set errRange $cmdRange
    }

    set msg    [eval [list format [message::getMessage $mid]] $clientData]
    set logMsg "([namespace tail $mid]) $msg"

    lappend ::message::collectedResults \
        [list $mid $logMsg $errRange]
    return $::message::collectedResults
}

# Puts --
#
#	Wrapper function for "puts" that allows us to easily redirect
#	output and catches write errors so we can exit cleanly.
#
# Arguments:
#	args	Passes arguments directoy to "puts".
#
# Results:
#	None.

proc Puts {args} {
    variable message::outChannel
    if {[lindex $args 0] == "-nonewline"} {
	set args [linsert $args 1 $outChannel]
    } else {
	set args [linsert $args 0 $outChannel]
    }
    if {[catch {
	eval puts $args
    } msg]} {
	exit 1
    }
    return
}

