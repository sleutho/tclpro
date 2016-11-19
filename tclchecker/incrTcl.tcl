# incrTcl.tcl --
#
#	This file contains type and command checkers for the incr Tcl
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: incrTcl.tcl,v 1.4 2000/05/30 22:28:50 wart Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide incrTcl 1.0

namespace eval incrTcl {
    # Class Constructor Arguments --
    # A temporary storage variable used to define the argument
    # list for a class, based on the argument list defined in 
    # its constructor.
    
    variable classArgList {}

    # Boolean value indicating if the class arg list was
    # non-literal.  This is used to determine if a class
    # should be added to the list of commands to check.

    variable validClassArgList 1

    # Body Type Stack --
    # The body type stack keeps track of what type of body
    # is being analyzed.  When we enter a class body or
    # namespace body, a new type is pushed on the stack.
    # This allows us to determine which commands are valid,
    # analyze them or flag an error.

    variable bodyStack "proc"
    
    # aliasCmds --
    # Define the set of commands that are created as aliases of the
    # corresponding itcl::* commands.  These aliases are created only 
    # for the current version incr Tcl.
    
    variable aliasCmds {
	configbody find class scope body local code delete 
    }

    # Commands To Scan --
    # Define the set of commands that need to be recursed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds1.5 {
	body		{incrTcl::addClassContext 1 {checkSimpleArgs 3  3 {
				incrTcl::checkMember checkArgList checkBody}}}
	itcl_class	{incrTcl::addClassContext 0 {incrTcl::addClass}}
    }
    variable scanCmds2.0 {
	class-TPC-SCAN		1
	configbody-TPC-SCAN	1
	destructor-TPC-SCAN	1
	import-TPC-SCAN		1
	method-TPC-SCAN		1
	private-TPC-SCAN	1
	protected-TPC-SCAN	1
	public-TPC-SCAN		1

	class		{incrTcl::addClassContext 0 {incrTcl::addClass}} 
	constructor	{incrTcl::checkBodyType {class} \
				{checkSimpleArgs 2 3 {
			    	incrTcl::addClassArgList checkBody}}}
	inherit		{addInheritCmd}
	namespace	{incrTcl::addClassContext 0 {checkSimpleArgs 1  2 {
	    			checkWord incrTcl::checkNsBody}}}
    }
    variable scanCmds3.0 {
	namespace	{checkOption {
	    {code	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {eval	    	{addContext 2 0 {} {} {checkSimpleArgs 2 -1 \
		    			{checkWord checkEvalArgs}}}}
	    {export	    	{addExportCmd}}
	    {import	    	{addImportCmd}}
	} {checkCommand}}
    }

    # checkersX.X --
    # Define the set of command-specific checkers used by this package.

    # itcl 1.5 -> Tcl 7.3
    variable checkers1.5 {
	body		{checkContext 1 1 {checkSimpleArgs 3  3 {
	    			incrTcl::checkMember checkArgList checkBody}}}
	itcl_class	{checkContext 1 0 {checkSimpleArgs 2  2 {checkWord \
				incrTcl::checkClassBody}}}
	itcl_info	{checkOption {
	    {classes	{checkSimpleArgs 0  1 {checkPattern}}}
	    {objects	{checkSwitches 1 {
		{-class {incrTcl::checkClassName}}
		{-isa   {incrTcl::checkClassName}}
	    } {checkSimpleArgs 0  1 {checkPattern}}}}
	} {}}
    }

    # itcl 2.0 -> Tcl 7.4
    variable checkers2.0 {
	class		{checkContext 1 0 {checkSimpleArgs 2  2 {checkWord \
		                incrTcl::checkClassBody}}}
	code		{checkSwitches 1 {
	    {-namespace {checkNamespace}}
	    --
	} {checkSimpleArgs 1 -1 {checkWord}}}
	common		{incrTcl::checkBodyType {class} \
				{checkSimpleArgs 1  2 {checkVarName \
					checkWord}}}
	configbody	{checkContext 1 1 {checkSimpleArgs 2  2 {
	    			incrTcl::checkMember checkBody}}}
	constructor	{incrTcl::checkBodyType {class} \
				incrTcl::checkConstructorCmd}
	delete		{checkOption {
	    {class	{checkSimpleArgs 1 -1 {incrTcl::checkClassName}}}
	    {object	{checkSimpleArgs 1 -1 {checkWord}}}
	    {namespace	{checkSimpleArgs 1 -1 {checkWord}}}
	} {}}
	destructor	{incrTcl::checkBodyType {class} \
				{checkSimpleArgs 1  1 {checkBody}}}
	import		{checkOption {
	    {add	{checkSwitches 1 {
		{-after checkNamespace} 
		{-before checkNamespace}
	    } {checkSimpleArgs 1 -1 {checkNamespace}}}}
	    {all	{checkSimpleArgs 0  1 {checkWord}}}
	    {list	{checkSimpleArgs 0  1 {checkList}}}
	    {remove	{checkSimpleArgs 1 -1 {checkWord}}}
	} {}}
	inherit		{incrTcl::checkBodyType {class} \
				{checkSimpleArgs 1 -1 {
			    	incrTcl::checkClassName}}}
	info		{checkOption {
	    {args	{checkSimpleArgs 1  1 {checkWord}}}
	    {body	{checkSimpleArgs 1  1 {checkWord}}}
	    {classes	{checkSimpleArgs 0  1 {checkPattern}}}
	    {cmdcount	{checkSimpleArgs 0  0 {}}}
	    {commands	{checkSimpleArgs 0  1 {checkPattern}}}
	    {complete	{checkSimpleArgs 1  1 {checkWord}}}
	    {context	{checkSimpleArgs 0  0 {}}}
	    {default	{checkSimpleArgs 3  3 {checkWord checkWord \
		    checkVarName}}}
	    {exists	{checkSimpleArgs 1  1 {checkVarName}}}
	    {globals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {level	{checkSimpleArgs 0  1 {checkInt}}}
	    {library	{checkSimpleArgs 0  0 {}}}
	    {loaded	{checkSimpleArgs 0  1 {checkWord}}}
	    {locals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {namespace	{checkOption {
		{all		{checkSimpleArgs 0  1 {checkNamespacePattern}}}
		{children	{checkSimpleArgs 0  1 {checkNamespacePattern}}}
		{parent		{checkSimpleArgs 0  1 {checkNamespacePattern}}}
		{qualifiers	{checkSimpleArgs 1  1 {checkNamespace}}}
		{tail		{checkSimpleArgs 1  1 {checkNamespace}}}
	    } {}}}
	    {objects	{checkSwitches 1 {
		{-class {incrTcl::checkClassName}}
		{-isa   {incrTcl::checkClassName}}
	    } {checkSimpleArgs 0  1 {checkPattern}}}}
	    {patchlevel	{checkSimpleArgs 0  0 {}}}
	    {procs	{checkSimpleArgs 0  1 {checkPattern}}}
	    {protection	{checkSwitches 1 {
		{-command checkWord}
		{-variable checkVarName}
	    } {checkSimpleArgs 1 1 {checkCommand}}}}
	    {script	{checkSimpleArgs 0  0 {}}}
	    {tclversion	{checkSimpleArgs 0  0 {}}}
	    {vars	{checkSimpleArgs 0  1 {checkPattern}}}
	    {which	{checkSwitches 1 {
		-command -variable -namespace
	    } {checkSimpleArgs 1  1 {checkWord}}}}
	} {}}
	itcl_class	{checkContext 1 0 {::analyzer::warn warnUnsupported "class" {
	    			checkSimpleArgs 2  2 {checkWord \
					incrTcl::checkClassBody}}}}
	itcl_info	{checkOption {
	    {classes	{::analyzer::warn warnUnsupported "info classes" {
		checkSimpleArgs 0  1 {checkPattern}}}}
	    {objects	{::analyzer::warn warnUnsupported "info objects" {checkSwitches 1 {
		{-class {incrTcl::checkClassName}}
		{-isa   {incrTcl::checkClassName}}
	    } {checkSimpleArgs 0  1 {checkPattern}}}}}
	} {}}
	method		{incrTcl::checkBodyType {class} \
				{checkSimpleArgs 1  3 {checkWord \
     				checkArgList incrTcl::checkMethodBody}}}
	namespace	{checkContext 1 0 {checkSimpleArgs 1  2 {
	    			checkWord incrTcl::checkNsBody}}}
	private		{incrTcl::checkBodyType {any} \
		                {incrTcl::checkProtection private}}
	protected	{incrTcl::checkBodyType {any} \
		                {incrTcl::checkProtection protected}}
	public		{incrTcl::checkBodyType {any} \
				{incrTcl::checkProtection public}}
	scope		{checkSimpleArgs 1  1 {checkWord}}
	variable	{incrTcl::checkVariableCmd 2.0}
    }

    # itcl 2.1 -> Tcl 7.5
    variable checkers2.1 {
	info		{checkOption {
	    {args	{checkSimpleArgs 1  1 {checkWord}}}
	    {body	{checkSimpleArgs 1  1 {checkWord}}}
	    {classes	{checkSimpleArgs 0  1 {checkPattern}}}
	    {cmdcount	{checkSimpleArgs 0  0 {}}}
	    {commands	{checkSimpleArgs 0  1 {checkPattern}}}
	    {complete	{checkSimpleArgs 1  1 {checkWord}}}
	    {context	{checkSimpleArgs 0  0 {}}}
	    {default	{checkSimpleArgs 3  3 {checkWord checkWord \
		    checkVarName}}}
	    {exists	{checkSimpleArgs 1  1 {checkVarName}}}
	    {globals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {hostname	{checkSimpleArgs 0  0 {}}}
	    {level	{checkSimpleArgs 0  1 {checkInt}}}
	    {library	{checkSimpleArgs 0  0 {}}}
	    {loaded	{checkSimpleArgs 0  1 {checkWord}}}
	    {locals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {nameofexecutable	{checkSimpleArgs 0  0 {}}}
	    {namespace {checkOption {
		{all		{checkSimpleArgs 0  1 {checkPattern}}}
		{children	{checkSimpleArgs 0  1 {checkPattern}}}
		{parent		{checkSimpleArgs 0  1 {checkPattern}}}
		{qualifiers	{checkSimpleArgs 1  1 {checkWord}}}
		{tail		{checkSimpleArgs 1  1 {checkWord}}}
	    } {}}}
	    {objects	{checkSwitches 1 {
		{-class {incrTcl::checkClassName}}
		{-isa   {incrTcl::checkClassName}}
	    } {checkSimpleArgs 0  1 {checkPattern}}}}
	    {patchlevel	{checkSimpleArgs 0  0 {}}}
	    {procs	{checkSimpleArgs 0  1 {checkPattern}}}
	    {protection	{checkSwitches 1 {
		{-command checkWord}
		{-variable checkVarName}
	    } {checkSimpleArgs 1 1 {checkCommand}}}}
	    {script	{checkSimpleArgs 0  0 {}}}
	    {sharedlibextension	{checkSimpleArgs 0  0 {}}}
	    {tclversion	{checkSimpleArgs 0  0 {}}}
	    {vars	{checkSimpleArgs 0  1 {checkPattern}}}
	    {which	{checkSwitches 1 {
		-command -variable -namespace
	    } {checkSimpleArgs 1  1 {checkWord}}}}
	} {}}
    }

    # itcl 2.2 -> Tcl 7.6
    variable checkers2.2 {
    }

    # itcl 3.0 -> Tcl 8.0
    variable checkers3.0 {
	delete		{checkOption {
	    {class	{checkSimpleArgs 1 -1 {incrTcl::checkClassName}}}
	    {object	{checkSimpleArgs 1 -1 {checkWord}}}
	    {namespace	{::analyzer::warn warnUnsupported "namespace delete" {checkWord}}}
	} {}}
	find		{checkOption {
	    {classes	{checkSimpleArgs 0 1 {checkPattern}}}
	    {objects	{::incrTcl::checkFindObjs}}
	} {}}
	import		{::analyzer::warn warnUnsupported "namespace import" \
		{checkCommand}}
	info		{checkOption {
	    {args	{checkSimpleArgs 1  1 {checkWord}}}
	    {body	{checkSimpleArgs 1  1 {checkWord}}}
	    {classes	{::analyzer::warn warnUnsupported "find classes" {checkPattern}}}
	    {cmdcount	{checkSimpleArgs 0  0 {}}}
	    {commands	{checkSimpleArgs 0  1 {checkPattern}}}
	    {complete	{checkSimpleArgs 1  1 {checkWord}}}
	    {context	{::analyzer::warn warnUnsupported "namespace current" {checkWord}}}
	    {default	{checkSimpleArgs 3  3 {checkWord checkWord \
		    checkVarName}}}
	    {exists	{checkSimpleArgs 1  1 {checkVarName}}}
	    {globals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {hostname	{checkSimpleArgs 0  0 {}}}
	    {level	{checkSimpleArgs 0  1 {checkInt}}}
	    {library	{checkSimpleArgs 0  0 {}}}
	    {loaded	{checkSimpleArgs 0  1 {checkWord}}}
	    {locals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {nameofexecutable	{checkSimpleArgs 0  0 {}}}
	    {namespace	{checkOption {
		{children	{::analyzer::warn warnUnsupported "namespace children" \
		    		    {checkWord}}}
		{parent		{::analyzer::warn warnUnsupported "namespace parent" \
		    		    {checkWord}}}
		{qualifiers	{::analyzer::warn warnUnsupported "namespace qualifiers" \
		    		    {checkWord}}}
		{tail		{::analyzer::warn warnUnsupported "namespace tail" \
		    		    {checkWord}}}
	    } {::analyzer::warn incrTcl::warnUnsupported {} {checkWord}}}}
	    {objects	{::analyzer::warn warnUnsupported "find objects" {checkWord}}}
	    {patchlevel	{checkSimpleArgs 0  0 {}}}
	    {procs	{checkSimpleArgs 0  1 {checkPattern}}}
	    {protection	{::analyzer::warn incrTcl::warnUnsupported {} {checkWord}}}
	    {script	{checkSimpleArgs 0  0 {}}}
	    {sharedlibextension	{checkSimpleArgs 0  0 {}}}
	    {tclversion	{checkSimpleArgs 0  0 {}}}
	    {vars	{checkSimpleArgs 0  1 {checkPattern}}}
	    {which	{::analyzer::warn warnUnsupported "string match" {checkWord}}}
	} {}}
	namespace	{checkOption {
	    {children		{checkSimpleArgs 0 2 \
		    		    {checkNamespace checkNamespacePattern}}}
	    {code	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {current	    	{checkSimpleArgs 0 0 {}}}
	    {delete	    	{checkSimpleArgs 0 -1 {checkNamespace}}}
	    {eval	    	{checkContext 2 0 {checkSimpleArgs 2 -1 \
		    			{checkNamespace checkEvalArgs}}}}
	    {export	    	{checkSwitches 0 {
	    		    	    -clear
				} {checkSimpleArgs 0 -1 \
					{checkExportPattern}}}}
	    {forget	    	{checkSimpleArgs 0 -1 {checkNamespacePattern}}}
	    {import	    	{checkSwitches 0 {
	    		    	    -force
				} {checkSimpleArgs 0 -1 \
					{checkNamespacePattern}}}}
	    {inscope	    	{checkSimpleArgs 2 -1 \
		    		   	{checkNamespace checkWord}}}
	    {origin	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {parent	    	{checkSimpleArgs 0 1 {checkNamespace}}}
	    {qualifiers	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {tail	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {which	    	{checkSwitches 0 {
	    		    	    -command -variable
				} {checkSimpleArgs 1  1 {checkWord}}}}
	} {::analyzer::warn warnDeprecated {namespace eval} {checkCommand}}}
	private		{incrTcl::checkBodyType {class} \
				{incrTcl::checkProtection private}}
	protected	{incrTcl::checkBodyType {class} \
                  		{incrTcl::checkProtection protected}}
	public		{incrTcl::checkBodyType {class} \
				{incrTcl::checkProtection public}}
	itcl_info	{checkOption {
	    {classes	{::analyzer::warn warnUnsupported "find classes" {checkPattern}}}
	    {objects	{::analyzer::warn warnUnsupported "find objects" {checkWord}}}
	} {}}
	variable	{incrTcl::checkVariableCmd 3.0}
    }

    # itcl 3.1 -> Tcl 8.2
    variable checkers3.1 {
    }

    # messages --
    # Define the set of message types and their human-readable translations. 

    array set messages {
	incrTcl::classNumArgs	{"wrong # args for class constructor: \"%1$s\"" err}
	incrTcl::procOutScope	{"proc only defined in class \"%1$s\"" err}
	incrTcl::procProtected	{"calling %1$s proc: \"%2$s\"" err}
	incrTcl::badMemberName	{"missing class specifier for body declaration" err}
	incrTcl::classOnly	{"command \"%1$s\" only defined in class body" err}
	incrTcl::warnUnsupported	{"command deprecated and is no longer valid" err}
	incrTcl::nsOnly		{"command \"%1$s\" only defined in namespace body" err}
	incrTcl::nsOrClassOnly	{"command \"%1$s\" only defined in class or namespace body" err}
    }
}

# incrTcl::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc incrTcl::init {ver} {
    foreach name [lsort [info vars ::incrTcl::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::incrTcl::scanCmds$ver"} {
	    break
	}
    }
    foreach name [lsort [info vars ::incrTcl::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::incrTcl::checkers$ver"} {
	    break
	}
    }

    # Add aliased checkers.  Only do this for incr Tcl 3.0 or greater.
    # Alias the standard incr Tcl commands so the namespace qualifier 
    # appears in the comand name.

    set aliases {}
    if {$ver >= 2.0} {
	foreach name $::incrTcl::aliasCmds {
	    if {[analyzer::topChecker $name] != {}} {
		lappend aliases itcl::$name [analyzer::topChecker $name]
	    }
	}
	analyzer::addCheckers $aliases
    }

    return
}

# incrTcl::getMessage --
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

proc incrTcl::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# incrTcl::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc incrTcl::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# incrTcl::topBody --
#
#	Return the body on the top of the stack.
#
# Arguments:
#	None.
#
# Results:
#	The body on the top of the body stack or 
#	empty string if there is no body on the stack.

proc incrTcl::topBody {} {
    return [lindex $incrTcl::bodyStack end]
}

# incrTcl::pushBody --
#
#	Push a new body type onto the body type stack.  This is 
#	used to identify what type of body we are parsing and
#	which commands are valid.
#
# Arguments:
#	body		A new body type string (class, ns, method)
#
# Results:
#	None.

proc incrTcl::pushBody {body} {
    lappend incrTcl::bodyStack $body
    return
}

# incrTcl::popBody --
#
#	Pop the top of the body stack.  This is called when
#	a body has completed parsing.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc incrTcl::popBody {} {
    variable bodyStack
    set len [llength $bodyStack]
    if {$len > 1} {
	set bodyStack [lrange $bodyStack 0 [incr len -2]]
    }
    return
}

# incrTcl::addClassContext --
#
#	Wrapper around the analyzer::addContext that specifies
#	which commands to call when verifying and checking user
#	procs defined inside incr Tcl.
#
# Arguments:
#	strip		Boolean indicating if the word containing
#			the context name should have the head stripped
#			off (i.e. "proc" vs. "namespace eval")
#	chainCmd	The chain command to eval in the new context.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc incrTcl::addClassContext {strip chainCmd tokens index} {
    return [analyzer::addContext 1 $strip \
	    incrTcl::verifyClassProc \
	    incrTcl::checkClassProc \
	    $chainCmd $tokens $index]
}

# incrTcl::addClass --
#
#	Add the class to the list of valid "procs" in the user proc
#	database.  This routine should be called during the initial 
#	scanning phase and passed a token tree and current index, 
#	where the index is the name of the proc being defined and the
#	remaining tokens define the class.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.  The
#	class name will be added to the list of procs to check
#	for valid number of arguments.

proc incrTcl::addClass {tokens index} {
    variable classArgList
    variable validClassArgList

    set word  [lindex $tokens $index]
    if {![getLiteral $word className]} {
	return [checkCommand $tokens $index]
    }

    # Set the global vars used to gather an argList for the
    # constructor of this class.  Set the argList to empty string
    # and the valid flag to true.  If there is no constructor then
    # these values are valid.  If there is a constructor and the
    # argList is a literal, then the classArgList will be set.  If
    # the argList is a non-literal, then the valid flag will be set
    # to false.

    set classArgList {}
    set validClassArgList 1

    # Now recurse into the class body.

    incr index
    set index [checkClassBody $tokens $index]
    
    # If the valid flag is true (no constructor found or a valid list
    # was found) then add the class to the list of valid procs.

    if {$validClassArgList} {
	uproc::addUserProc [context::top] class

	# Specify the initial value for the min and max number of 
	# arguments taken for this class.  Every class has an 
	# optional argument; that is the object's name.

	uproc::addArgList $classArgList 0 1
    }

    return $index
}

# incrTcl::addClassArgList --
#
#	Parse the token list extracting the argument list for
#	the definition of a class.  This routine should be called
#	when a constructor for a class is encountered.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.  The 
#	class argument list variable will be set if this is a 
#	literal string.  The literal class arg varible will be
#	set indicating if the class arg list var was set.

proc incrTcl::addClassArgList {tokens index} {
    set word [lindex $tokens $index]
    if {[getLiteral $word argList]} {
	set incrTcl::validClassArgList 1
	set incrTcl::classArgList $argList
    } else {
	set incrTcl::validClassArgList 0
    }
    return [incr index]
}

# incrTcl::addIncrProcCmd --
#
#	Parse the token list extracting the information necessary to
#	define a proc info type for this proc.  This is defined as
#	an individual proc so it can be pushed and popped on the
#	list of commands to check when entering and leaving class
#	bodies.  This routine should be called when a class proc is
#	encountered.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

proc incrTcl::addIncrProcCmd {tokens index} {
    return [incrTcl::addClassContext 1 {checkSimpleArgs 1 3 {
	analyzer::addUserProc analyzer::addArgList checkBody}} $tokens $index]
}

# incrTcl::verifyClassProc --
#
#	Verify the information contained in the proc info type
#	is enough to check a class proc.
#
# Arguments:
#	pInfo	The proc info opaque type.
#
# Results:
#	Return a boolean, 1 if there is enough data, 0 otherwise.

proc incrTcl::verifyClassProc {pInfo} {
    set name [uproc::getName $pInfo]
    set def  [uproc::getDef  $pInfo]
    return [expr {($name != {}) && $def}]
}

# incrTcl::checkClassProc --
#
#	Check the class proc for the correct number of arguments,
#	protection level and inheritance.  This routine should be
# 	called during the final analyzing phase of checking, after
#	the proc names have been found.
#
# Arguments:
#	pInfo		The proc info type of the proc to check.
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the commands to call to log an error if this
#	user proc failed.  Otherwise, return empty string if
#	the user proc passed.

proc incrTcl::checkClassProc {pInfo tokens index} {
    # Search through the pInfoList and try to find a pInfo
    # type that satisfies the number of args passed to this
    # proc, the protection level and type.  Only flag
    # an error if none of the pInfo's match.

    set argc [llength $tokens]
    set tCtx [context::top]

    set min   [uproc::getMin  $pInfo]
    set max   [uproc::getMax  $pInfo]
    set prot  [uproc::getProt $pInfo]
    set type  [uproc::getType $pInfo]
    set name  [uproc::getName $pInfo]
    set nCtx  [namespace qualifier $name]

    set argsOK 0
    set protOK 0
    set typeOK 0

    # Check for the correct number of arguments.
    
    if {($argc >= ($min + $index)) \
	    && (($max == -1) || ($argc <= ($max + $index)))} {
	set argsOK 1
    }
	
    # If the protection level is private or protected verify the
    # current context is the same as the procs context.  Otherwise
    # the protection is public, so it should always pass.
    
    if {((($prot == "private") || ($prot == "protected")) \
	    && ($tCtx == $nCtx)) || ($prot == "public")} {
	set protOK 1
    }

    # If the type is "inherit" and the contexts are the same
    # or the type is not inherit, then let it pass.
    
    if {(($type == "inherit") && ($tCtx == $nCtx)) \
	    || ($type != "inherit")} {
	set typeOK 1
    }
    
    # If the number of args, protection level and inheritance 
    # context pass their tests, then this is a valid user proc.
    # Return an empty string indicating this is a valid call.
    
    if {$argsOK && $protOK && $typeOK} {
	return {}
    }

    # The test failed for one or more reasons.  Append the logError
    # command calls needed to report all errors and return this list.

    set result {}
    if {!$argsOK} {
	if {$type == "class"} {
	    lappend result [list logError incrTcl::classNumArgs {} $name]
	} else {
	    lappend result [list logError procNumArgs {} $name]
	}
    }
    if {!$protOK && $typeOK} {
	lappend result [list logError incrTcl::procProtected {} $prot $name]
    }
    if {!$typeOK} {
	lappend result [list logError incrTcl::procOutScope {} $nCtx]
    }
    return $result
}

# Checkers for specific commands --
#
#	Each checker is passed the tokens for the arguments to the command.
#	The name of each checker should be of the form incrTcl::check<Name>,
#	where <name> is the command being checked.
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.


# incrTcl::checkClassBody --

proc incrTcl::checkClassBody {tokens index} {
    # Push the class body type onto the body stack, push
    # the proc checker (valid only in class bodies) onto 
    # the analyzer's checker, and parse the class body.
    # When that is complete, pop the body type and special
    # proc checker.
    
    if {[analyzer::isScanning]} {
	pushChecker proc incrTcl::addIncrProcCmd
    } else {
	pushChecker proc incrTcl::checkIncrProcCmd
	uproc::isRedefined [context::top] class
    }
    incrTcl::pushBody class
    set index [checkBody $tokens $index]
    popChecker proc
    incrTcl::popBody
    return $index
}

# incrTcl::checkNsBody --

proc incrTcl::checkNsBody {tokens index} {
    # Push the namespace body type onto the body stack, and 
    # parse the namespace body.  When that is complete, pop 
    # the body.

    incrTcl::pushBody ns
    set index [checkBody $tokens $index]
    incrTcl::popBody
    return $index
}

# incrTcl::checkIncrProcCmd --

proc incrTcl::checkIncrProcCmd {tokens index} {
    return [checkContext $index 1 { \
	    checkSimpleArgs 1 3 \
	    {checkRedefined checkArgList incrTcl::checkMethodBody}} \
	    $tokens $index]
}

# incrTcl::checkVariableCmd --

proc incrTcl::checkVariableCmd {itclVersion tokens index} {
    # Depending on the context, perform the correct check.

    set body [incrTcl::topBody]
    set protection [context::topProtection]
	
    switch $body {
	class {
	    switch $protection {
		public {
		    return [checkSimpleArgs 1 3 {
			checkVarName checkWord checkBody} \
				$tokens $index] 
		}
		default {
		    return [checkSimpleArgs 1 2 {checkVarName checkWord} \
			    $tokens $index] 
		}
	    }

	}
	default {
	    if {$itclVersion >= 3.0} {
		return [coreTcl::checkVariableCmd $tokens $index]
	    }
	    return [checkSimpleArgs 1 2 {checkVarName checkWord} \
		    $tokens $index] 
	}
    }
}

# incrTcl::checkConstructorCmd --

proc incrTcl::checkConstructorCmd {tokens index} {
    set argc [expr {[llength $tokens] - $index}]
    if {$argc == 2} {
	set index [checkArgList $tokens $index]
	return [checkBody $tokens $index]
    } elseif {$argc == 3} {
	set index [checkArgList $tokens $index]
	set index [checkBody $tokens $index]
	return [checkBody $tokens $index]
    } else {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
}

# incrTcl::checkMethodBody --
#
# Pushes the body of "method" onto the context's body stack,
# as well as handlers for constructor and destructor.
# Then checks the remaining arguments.  This is important
# thus far only for the "variable" command, which is an
# incrTcl command in a class body, but a coreTcl command
# in a method/common body.
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names.
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Returns index to next token, as for all checker commands

proc incrTcl::checkMethodBody {tokens index} {
    incrTcl::pushBody method
    pushChecker constructor {checkCommand}
    pushChecker destructor {checkSimpleArgs 0 0 {}}
    set index [checkBody $tokens $index]
    popChecker constructor
    popChecker destructor
    incrTcl::popBody
    return $index
}

# incrTcl::checkProtection --
#
# This command is used to check any of the [incr Tcl] protection
# commands: public, protected, and private.  It pushes the
# new protection level on the protectStack.  It then
# calls checkScript on its arguments, either directly
# or by calling checkBody based on the number of args.

proc incrTcl::checkProtection {protection tokens index} {
    set argc [expr {[llength $tokens] - $index}]
    if {$argc == 0} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    
    # Check the command that follows.  If it is a literal with 
    # only one argument, then it is a body that needs to be 
    # parsed.  If it is a literal with > 1 arg, then check the 
    # first argument as a command, and pass it the remaining 
    # arguments.  Note: This is like eval, but without an additional
    # round of substitution.

    switch $protection {
	public -
	private -
	protected {

	}
	default {
	    error "bad protection in incrTcl::checkProtection: $protection"
	}
    }

    context::pushProtection $protection

    if {[getLiteral [lindex $tokens $index] cmdName]} {
	if {$argc == 1} {
	    set index [checkBody $tokens $index]
	} else {
	    set word  [lindex $tokens $index]
	    set start [lindex [lindex $word 1] 0]
	    
	    set lastWord [lindex $tokens end]
	    set length [expr {[lindex [lindex $lastWord 1] 0] \
		    + [lindex [lindex $lastWord 1] 1] \
		    - $start}]

	    set range [list $start $length]
	    analyzer::checkScript $range
	    set index [llength $tokens]
	}
    } else {
	set index [checkWord $tokens $index]
    }

    context::popProtection
    return $index
}


# incrTcl::checkClassName --

proc incrTcl::checkClassName {tokens index} {
    # For now this is a no-op until we get a 2-pass
    # analyzer to do snazzier checks.

    return [checkWord $tokens $index]
}

# incrTcl::checkMember --

proc incrTcl::checkMember {tokens index} {
    # Verifies the member function or member variable is 
    # correctly qualified.
    
    set word [lindex $tokens $index]
    if {[getLiteral $word literal] == 1} {
	if {![regexp {[^:]::} $literal]} {
	    logError incrTcl::badMemberName [getTokenRange $word]
	}
    }
    return [checkWord $tokens $index]
}

# incrTcl::checkBodyType --
#
#	Verify that the command is being executed in the 
#	correct context.
#
# Arguments:
#	validBodies	A list of valid bodies.
#	checkCmd	The command to execute after the 
#			context is checked.
#	tokens		The list of word tokens after the initial
#			command and subcommand names.
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.

proc incrTcl::checkBodyType {validBodies checkCmd tokens index} {
    set valid   0
    set nsOK    0
    set classOK 0
    set currentBody [incrTcl::topBody]
    foreach body $validBodies {
	if {[string compare $body any] == 0} {
	    set valid 1
	    break
	} elseif {[string compare $body $currentBody] == 0} {
	    set valid 1
	    break
	}
	set ${body}OK 1
    }
    if {!$valid} {
	if {$classOK && $nsOK} {
	    set mid incrTcl::nsOrClassOnly
	} elseif {$classOK} {
	    set mid incrTcl::classOnly
	} elseif {$nsOK} {
	    set mid incrTcl::nsOnly
	}
	set word [lindex $tokens [expr {$index - 1}]]
	getLiteral $word cmdName
	logError $mid [getTokenRange $word] $cmdName
    }
    return [eval $checkCmd {$tokens $index}]
}

# incrTcl::checkFindObjs --
#
#	Verify that the args are interlaced <option> <className>
#	args, where the option is either -class, -isa, or non-literal,
#	followed an optional pattern (word).  Currently, the pattern
#	arg cannot preceed the options (although this is legal itcl code).
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names.
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.

proc incrTcl::checkFindObjs {tokens index} {
    set max [llength $tokens]

    while {$index < $max} {
	
	set next [expr {$index + 1}]

	if {$next < $max} {

	    set word [lindex $tokens $index]

	    if {[getLiteral $word literal]} {
		checkOption {
		    {-class {incrTcl::checkClassName}}
		    {-isa {incrTcl::checkClassName}}
		} {} $tokens $index
	    } else {
		checkWord $tokens $index
		incrTcl::checkClassName $tokens $next
	    }
	    incr index 2
	} else {
	    set index [analyzer::checkPattern $tokens $index]
	}
    }
    return $index
}
