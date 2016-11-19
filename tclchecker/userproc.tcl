# userproc.tcl --
#
#	This file contains routines for storing and retrieving
#	user-defined procs.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# SCCS: %Z% %M% %I% %E% %U%

package require analyzer 1.0
namespace import -force ::analyzer::*

namespace eval uproc {
    # User Proc Info --
    # Stores the set of procedures defined by the users.  The 
    # fully qualified proc or class name is the array entry and
    # the value is a list of proc info data types that contains
    # information about max and min number of args, protection
    # level, type data, etc.  Note: Duplicate entries are removed
    # so the collation step and checking for redefined procs are
    # handled correcly.

    variable userProc
    array set userProc {}

    # User Proc Counter --
    # Store the number of times a class or proc is redefined.
    # This is used by the isRedefined routine to determine if
    # a proc or class was redefined.  The llength of the entry
    # in the userProc array cannot be used because duplicates
    # are removed from the list.

    variable userProcCount
    array set userProcCount {}

    # Proc Info Stack --
    # Store a stack of user procs being defined.  As a new proc
    # is defined, add info to the current proc type as the command
    # is defined.

    variable procInfoStack {}
}

# uproc::add --
#
#	Called after a complete user defined proc has been defined.
#
# Arguments:
#	pInfo	The fully specified proc info type.
#
# Results:
#	None.  The proc info is added to the user proc database,
#	the user proc counter is incremented for the proc name 
#	and the context is added to the context database.

proc uproc::add {pInfo strip} {
    variable userProc
    variable userProcCount

    # Add the proc info is the exact pInfo type does not already
    # exist in the database.

    set name [uproc::getName $pInfo]
    if {[uproc::IndexProcInfo $name $pInfo] < 0} {
	lappend userProc($name) $pInfo
    }

    # Keep track of how many times this command is redefined.
    # This is used by the isRedefined routine to log warnings
    # if a class or proc defined more than once.

    if {![info exists userProcCount($name)]} {
	set userProcCount($name) 1
    } else {
	incr userProcCount($name)
    }

    # Add the context to the list of known contexts.

    if {$strip} {
	context::add [context::head $name]
    } else {
	context::add $name
    }
    return
}

# uproc::addUserProc --
#
#	Add the user proc info to the current procInfo type on the stack.
#
# Arguments:
#	name		A fully qualified class or proc name.
#	type		A literal string that describes the proc info type.  
#
# Results:
#	None.  The proc name is added to the proc info stack.

proc uproc::addUserProc {name type} {
    # Add the proc info type to the userProc array if the pInfo
    # type is a unique entry.

    set pInfo [uproc::popProcInfo]
    set pInfo [uproc::setName $pInfo $name]
    set pInfo [uproc::setType $pInfo $type]
    uproc::pushProcInfo $pInfo
    return
}

# uproc::addArgList --
#
#	Parse the argList and add the user proc info to the stack.
#
# Arguments:
#	argList		The argument list to parse.
#	min		Specify an initial minimum value.
#	max		Specify an initial maximum value.
#
# Results:
#	None.  The proc info is added to the user proc stack.
#	the user proc counter is incremented for the proc name 
#	and the context is added to the context database.

proc uproc::addArgList {argList {min 0} {max 0}} {
    # Parse each arg in argList.  If the arg has a length of two, then 
    # it is a defaulted argument.  The min value stays fixed after this.
    # If the "args" keyword is the last argument in the argList, then
    # set max to "-1" indiacting that any number of args > min is valid.

    set def 0
    foreach arg $argList {
	if {[llength $arg] >= 2} {
	    set def 1
	}
	if {!$def} {
	    incr min
	}
	incr max
    }
    if {[string compare [lindex $argList end] "args"] == 0} {
	incr min -1
	set max -1
    }
    
    set pInfo [uproc::popProcInfo]
    set pInfo [uproc::setMin $pInfo $min]
    set pInfo [uproc::setMax $pInfo $max]
    set pInfo [uproc::setDef $pInfo 1]
    uproc::pushProcInfo $pInfo
    return
}

# uproc::copyUserProc --
#
#	Copy proc info from one context to another.
#
# Arguments:
#	impCmd		The fully qualified command name to import.
#	expCmd		The fully qualified command name to export.
#	type		A descriptor type for the new proc.
#
# Results:
#	Return 1 if a proc was imported, return 0 if the exact
#	proc info already existed.

proc uproc::copyUserProc {impCmd expCmd {type {}}} {
    variable userProc
    variable userProcCount

    # If no info exists for the exported proc, then the exported
    # proc has not been defined.  Return 0 and do nothing.

    if {![info exists userProc($expCmd)]} {
	return 0
    }

    set new 0
    foreach pInfo $userProc($expCmd) {
	# Update the pInfo so the info reflects it's new name and
	# scope.  If <type> is not empty then copy the new type
	# into the pInfo.  Then, replace the qualified exported 
	# name with the qualified imported name and the base name
	# with the exported name.

	if {$type != {}} {
	    set pInfo [uproc::setType $pInfo $type]
	}
	set pInfo [uproc::setName $pInfo $impCmd]
	set pInfo [uproc::setBase $pInfo [context::head $expCmd]]

	# If the pInfo type does not currently exist in the import 
	# context, copy the pInfo type from the export context to 
	# the import context.

	if {[uproc::IndexProcInfo $impCmd $pInfo] < 0} {
	    lappend userProc($impCmd) $pInfo
	    set new 1
	}

	# Keep track of how many times this command is redefined.
	# This is used by the isRedefined routine to log warnings
	# if a class or proc defined more than once.  Only do this
	# if this is a newly copied command, because the algorithm
	# for collating will call this twice to perform the transitive
	# closure of all imports, inherits and renames.

	if {$new} {
	    if {![info exists userProcCount($impCmd)]} {
		set userProcCount($impCmd) 1
	    } else {
		incr userProcCount($impCmd)
	    }
	}
    }
    return $new
}

# uproc::checkUserProc --
#
#	Check the user-defined proc for the correct number
#	of arguments.  For procs that have been multiply 
#	defined, check all of the argLists before flagging
#	an error.  This routine should be called during the
#	final analyzing phase of checking, after the proc
#	names have been found.
#
# Arguments:
#	uproc		The name of the proc to check.
#	pInfoList	A list of procInfo types for the the procedure.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc uproc::checkUserProc {uproc pInfoList tokens index} {
    # Search through the pInfoList and try to find a pInfo
    # type that satisfies the number of args passed to this
    # proc, the protection level and type.  Only flag
    # an error if none of the pInfo's match.

    set eCmds {}
    foreach pInfo $pInfoList {
	# Evaluate the check command for this user proc.  If the
	# return is an empty string, then this proc is valid.  
	# Break out of the loop.  Otherwise this check failed.
	# Continue checking the remaining pInfo types.

	set eCmds [[uproc::getCheckCmd $pInfo] $pInfo $tokens $index]
	if {$eCmds == {}} {
	    break
	}
    }

    # If none of the user procs passed, then check to see if this
    # proc is defined by a system proc checker.  If there is one
    # we stop checking the user procs and use the system proc 
    # checker.  Any error message reported will come from this
    # checker not from any of the user proc checkers.

    # First make sure the uproc name does not have leading 
    # ::'s because the user proc table does not match absolute
    # names.

    regexp -- {::([:]+)?(.*)} $uproc x x uprco

    if {($eCmds != {}) && [info exists analyzer::checkers($uproc)]} {
	set cmd [topChecker $uproc]
	return [eval $cmd {$tokens $index}]
    }

    # At this point we have finished checking the list of proc
    # info types.  If no matches were found, report the error
    # of the last checked proc info type.  For common cases
    # there will only be one proc info type, so in general,
    # this should be OK.
    
    foreach cmd $eCmds {
	eval $cmd
    }

    # Make sure to check each word in the command.

    return [checkCommand $tokens $index]
}

# uproc::isRedefined --
#
#	Check to see if the proc has been defined more than once.  If
#	so, then log an error.  This can happen if; there are multiple
#	definiions of the same proc or class; a class has the same 
#	name as a proc; or procs are imported, renamed or inherited.
#
# Arguments:
#	name		The fully qualified class or proc name.
#	thisType	The type of proc being defined (proc or class)
#
# Results:
#	None.  An error is logged if there are multiple definitions
#	for the same class or proc name.

proc uproc::isRedefined {name thisType} {
    variable userProc
    variable userProcCount

    # This is a tricky algorithm.  We want to report exactly why the
    # proc or class was redefined to provide the best feedback.  For 
    # example, was the proc redefined because an identically named 
    # proc was imported from another namespace or renamed to the same
    # name.  The only context we have is that this is a new proc or
    # class about to be defined.  We cannot determine which pInfo 
    # type in the list this proc is referring to.  So to provide the
    # best feedback possible we have the following heuristic:
    # (1) Do not report this proc or class is redefined by itself, so
    #     skip the first pInfo type that matches thisType.
    # (2) Do not report redefinitions for inherited commands.  This
    #     is standard behavior for incr Tcl.
    # (3) Report all other types.

    if {[info exists userProcCount($name)] && ($userProcCount($name) > 1)} {
	set skipped  0
	set thisFile [analyzer::getFile]
	set thisLine [analyzer::getLine]

	foreach pInfo $userProc($name) {
	    set type [uproc::getType $pInfo]
	    set file [uproc::getFile $pInfo]
	    set line [uproc::getLine $pInfo]

	    if {($type == $thisType) && ($file == $thisFile) \
		    && ($line == $thisLine) && (!$skipped) \
		    && ([llength $userProc($name)] > 1)} {
		set skipped 1
		continue
	    }
	    switch $type {
		inherit {
		    continue
		}
		class {
		    logError warnRedefine {} $thisType $name "class" \
			    $file $line
		}
		renamed -
		imported {
		    logError warnRedefine {} $thisType $name "$type proc" \
			    $file $line
		}
		default {
		    logError warnRedefine {} $thisType $name "proc" \
			    $file $line
		}
	    }		    
	}
    }
    return
}

# uproc::searchThisContext --
#
#	Search the user-defined proc database for the
#	existence of context and pattern, where pattern
#	will only match procs in the current context.
#
# Arguments:
#	context		The base context to begin looking.
#	pattern		The pattern to query in this context only.
#
# Results:
#	The entries in the database that exist.

proc uproc::searchThisContext {context pattern} {
    variable userProc

    set result {}
    foreach name [array names userProc [context::join $context $pattern]] {
	if {![string match [context::join $context *::*] $name]} {
	    lappend result [list $name]
	}
    }
    return $result
}

# uproc::exists --
#
#	Determine if the procName exists at the current context
#	or any parent of the current context.  If so set the 
#	infoVar variable to contain the list of procInfo types.
#
# Arguments:
#	context		The base context to begin looking.
#	name		The name of the user proc.
#	pInfoVar	The variable that will contain the procInfo
#			list, if it exists.
#
# Results:
#	Boolean, 1 if the proc exists.

proc uproc::exists {context name pInfoVar} {
    variable userProc
    upvar 1 $pInfoVar pInfo

    # Attempt to locate the proc by looking in the concatenated 
    # context of the <context> and any context defined in <name>.

    set context [context::locate $context $name]
    if {$context != {}} {
	set proc [context::join $context [namespace tail $name]]
	if {[info exists userProc($proc)]} {
	    set pInfo $userProc($proc)
	    return 1
	}
    }

    # The concatenated context does not exist or the proc does 
    # not exist in that context, look in the global context.
    
    set proc [context::join :: $name]
    if {[info exists userProc($proc)]} {
	set pInfo $userProc($proc)
	return 1
    } else {
	# The user proc is not defined in the local or global context.
	return 0
    }
}

# uproc::IndexProcInfo --
#
#	Find the index of pInfo in the list of pInfo types.
#
# Arguments:
#	name	The fully qualified name of the proc or class.
#	pInfo	The associated pInfo type.
#
# Results:
#	Return an index into the list if a match is found or
#	-1 if no match is found.

proc uproc::IndexProcInfo {name pInfo} {
    variable userProc
    if {[info exists userProc($name)]} {
	return [lsearch $userProc($name) $pInfo]
    } else {
	return -1
    }
}

# uproc::newProcInfo --
#
#	Create a new proc info type.  Note: Much of the info that
#	composes a pInfo is retrieved from the system.  The 
#	context protection stack, current file and current line
#	number must be up to date and accessable.
#
# Arguments:
#	None.
#
# Results:
#	Return a new proc info opaque type.

proc uproc::newProcInfo {} {
    return [list {} {} 0 -1 -1 \
	    [context::topProtection] proc \
	    [analyzer::getFile] [analyzer::getLine] \
	    analyzer::verifyUserProc analyzer::checkUserProc]
}

# uproc::getName --
#
#	Get the fully qualified name of the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	The name of the proc.

proc uproc::getName {pInfo} {
    return [lindex $pInfo 0]
}

# uproc::setName --
#
#	Set the fully qualified name for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	name	The new proc name.
#
# Results:
#	Return the new pInfo list.

proc uproc::setName {pInfo name} {
    return [lreplace $pInfo 0 0 $name]
}

# uproc::getBase --
#
#	Get the fully qualified base context where this 
#	proc originated from.  This will be an empty 
#	string unless the proc was renamed, imported or
#	inherited.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	The name of the base context of empty string if one doesnt exist.

proc uproc::getBase {pInfo} {
    return [lindex $pInfo 1]
}

# uproc::setBase --
#
#	Set the base context for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	base	The new proc name.
#
# Results:
#	Return the new pInfo list.

proc uproc::setBase {pInfo base} {
    return [lreplace $pInfo 1 1 $base]
}

# uproc::getDef --
#
#	Get the boolean indicating if the argList was defined.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return the boolean value to determine if the argList was defined.

proc uproc::getDef {pInfo} {
    return [lindex $pInfo 2]
}

# uproc::setDef --
#
#	Set the defined boolean indicating if the args list was validly
#	defined for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	def	The new defined boolean.
#
# Results:
#	Return the new pInfo list.

proc uproc::setDef {pInfo def} {
    return [lreplace $pInfo 2 2 $def]
}

# uproc::getMin --
#
#	Get the minimum number of args allowable for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	The minimum number of args for this proc.

proc uproc::getMin {pInfo} {
    return [lindex $pInfo 3]
}

# uproc::setMin --
#
#	Set the minimum number of args allowable for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	min	The minimum number of allowable args.
#
# Results:
#	Return the new pInfo list.

proc uproc::setMin {pInfo min} {
    return [lreplace $pInfo 3 3 $min]
}

# uproc::getMax --
#
#	Get the maximum number of args allowable for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	The maximum number of args for this proc.

proc uproc::getMax {pInfo} {
    return [lindex $pInfo 4]
}

# uproc::setMax --
#
#	Set the maximum number of args allowable for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	max	The maximum number of allowable args.
#
# Results:
#	Return the new pInfo list.

proc uproc::setMax {pInfo max} {
    return [lreplace $pInfo 4 4 $max]
}

# uproc::getProt --
#
#	Get the protection level for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return either public, protected or private.

proc uproc::getProt {pInfo} {
    return [lindex $pInfo 5]
}

# uproc::setProt --
#
#	Set the protection level for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	prot	The new protection level.
#
# Results:
#	Return the new pInfo list.

proc uproc::setProt {pInfo prot} {
    return [lreplace $pInfo 5 5 $prot]
}

# uproc::getType --
#
#	Get the type descriptor for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return either tcl, class or inherit.

proc uproc::getType {pInfo} {
    return [lindex $pInfo 6]
}

# uproc::setType --
#
#	Set the type descriptor for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	type	The new type.
#
# Results:
#	Return the new pInfo list.

proc uproc::setType {pInfo type} {
    return [lreplace $pInfo 6 6 $type]
}

# uproc::getFile --
#
#	Get the file name for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return the current file being checked.

proc uproc::getFile {pInfo} {
    return [lindex $pInfo 7]
}

# uproc::setFile --
#
#	Set the file name for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	file	The new file name.
#
# Results:
#	Return the new pInfo list.

proc uproc::setFile {pInfo file} {
    return [lreplace $pInfo 7 7 $file]
}

# uproc::getLine --
#
#	Get the line number for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return the line number.

proc uproc::getLine {pInfo} {
    return [lindex $pInfo 8]
}

# uproc::setLine --
#
#	Set the line number for the userProc.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	line	The new line number.
#
# Results:
#	Return the new pInfo list.

proc uproc::setLine {pInfo line} {
    return [lreplace $pInfo 8 8 $line]
}

# uproc::getVerifyCmd --
#
#	Get the callback command needed to verify there is enough
#	info in the proc info type to append this type onto the list
#	of defined user procs.  This command should take one arg,
#	pInfo, which is the proc info type to verify.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return the verify command for this pInfo type.

proc uproc::getVerifyCmd {pInfo} {
    return [lindex $pInfo 9]
}

# uproc::setVerifyCmd --
#
#	Set the callback command needed to verify there is enough
#	info in the proc info type to append this type onto the list
#	of defined user procs.  This command should take one arg,
#	pInfo, which is the proc info type to verify.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	vcmd	The new verifying command type.
#
# Results:
#	Return the new pInfo list.

proc uproc::setVerifyCmd {pInfo vcmd} {
    return [lreplace $pInfo 9 9 $vcmd]
}

# uproc::getCheckCmd --
#
#	Get the callback command needed to check the calling of a
#	user-defined proc.  This command should take one arg,
#	pInfo, which is the proc info type to verify.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#
# Results:
#	Return the checker command for this pInfo type.

proc uproc::getCheckCmd {pInfo} {
    return [lindex $pInfo 10]
}

# uproc::setCheckCmd --
#
#	Set the callback command needed to check the calling of a
#	user-defined proc.  This command should take one arg,
#	pInfo, which is the proc info type to verify.
#
# Arguments:
#	pInfo	A procInfo opaque type.
#	ccmd	The new verifying command type.
#
# Results:
#	Return the new pInfo list.

proc uproc::setCheckCmd {pInfo ccmd} {
    return [lreplace $pInfo 10 10 $ccmd]
}

# uproc::topProcInfo --
#
#	Get the current proc info type currently being defined.
#
# Arguments:
#	None.
#
# Results:
#	The current proc info type.

proc uproc::topProcInfo {} {
    return [lindex $uproc::procInfoStack end]
}

# uproc::pushProcInfo --
#
#	Set the current proc info type currently being defined.
#
# Arguments:
#	pInfo		The current qualified context path.
#
# Results:
#	None.

proc uproc::pushProcInfo {pInfo} {
    lappend uproc::procInfoStack $pInfo
    return
}

# uproc::popProcInfo --
#
#	Unset the current proc info type currently being defined.
#
# Arguments:
#	None.
#
# Results:
#	The current proc info type.

proc uproc::popProcInfo {} {
    variable procInfoStack

    set top [lindex $procInfoStack end]
    set len [llength $procInfoStack]
    set procInfoStack [lrange $procInfoStack 0 [incr len -2]]
    return $top
}



