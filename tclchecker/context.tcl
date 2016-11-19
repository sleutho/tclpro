# context.tcl --
#
#	This file contains routines for storing, combining and
#	locating context information (i.e., namespace or class path) 
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: context.tcl,v 1.3 2000/10/31 23:30:54 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

namespace eval context {
    # Known Contexts --
    # Store a list of known contexts so we can check for the 
    # existance of a context when locating absolute or relative
    # contexts.

    variable knownContext
    array set knownContext {}
    # Context Stack --
    # The context stack keeps track of the current context 
    # (e.g., namespace path or class name.)  When we enter 
    # a class body or namespace body, a new context is 
    # pushed on the stack.  This allows us to determine 
    # where commands are defined.

    variable contextStack "::"

    # Protection Stack --
    # The context stack keeps track of what the protection
    # level is for the current body being analyzed.  When
    # the public, private, or protected commands are used,
    # their protection level is pushed on the stack, and
    # popped when they finish.

    variable protectionStack "public"
}

# context::add --
#
#	Add a new context to the list of known contexts.
#
# Arguments:
#	context		A new context to add.
#
# Results:
#	None.

proc context::add {context} {
    if {$context == ""} {
	set context "::"
    }
    set context::knownContext($context) 1
}

# context::exists --
#
#	Determine if the specified context exists.
#
# Arguments:
#	context		A context to search for.
#
# Results:
#	Return 1 if the context exists, 0 if it does not.

proc context::exists {context} {
    if {$context == ""} {
	set context "::"
    }
    return [info exists context::knownContext($context)]
}

# context::locate --
#
#	Given a current context and a qualified name,
#	locate the context.
#
# Arguments:
#	context		The local context.
#	name		The qualified name to find.
#	strip		Boolean indicating if the word containing
#			the context name should have the head stripped
#			off (i.e. "proc" vs. "namespace eval")
#
# Results:
#	The absolute context if one exists or empty string
#	if the context does not exist.

proc context::locate {context name {strip 1}} {
    # There are three possible scenarios for locating a context.
    # (1) The name is absolute. (begins with ::)  In this
    #     case, only search for the context in the absolute path
    #     specified by <name>.
    # (2) The name is qualified. (<relative> is not null)
    #     The context could exist in the concatenated path of
    #  	  <context>::<relative> or ::<relative>.
    # (3) The name is not qualified.  The context could exist
    #	  in <context> or ::.
    
    if {$strip} {
	set relative [namespace qualifiers $name]
    } else {
	set relative $name
    }

    if {[string match "::*" $name]} {
	set context [context::join :: $relative]
	set searchAltPath 0
    } elseif {$relative != {}} {
	set context [context::join $context $relative]
	set searchAltPath 1
    } else {
	set searchAltPath 1
    }

    # If the context is not found and name is not global, then
    # search for the existence of the context by making the
    # relative context global.

    if {[context::exists $context]} {
	return $context
    } elseif {($searchAltPath) && [context::exists ::$relative]} {
	return "::$relative"
    } else {
	return {}
    }
}

# context::join --
#
#	Do an intelligent join of the parent and child namespaces.
#
# Arguments:
#	parent	The parent namespace.
#	child	The child namespace.
#
# Results:
#	The join of the two namespaces.

proc context::join {parent child} {
    # If the parent's context is UNKNOWN then the childs context
    # will also be unknown.  If the child path is fully qualified,
    # then return the child as the join of the two.  Otherwise
    # join the two together so the beginning of the context has "::"s
    # while the ending does not.

    if {($parent == "UNKNOWN") || ($child == {})} {
	return $parent
    } elseif {[string match "::*" $child]} {
	return $child
    } else {
	# If the parent is not the global context and does not
	# have trailing "::"s add them.  If the child has
	# leading "::"s strip them off.

	if {![string match "::" $parent] && ![string match "*::" $parent]} {
	    set parent "${parent}::"
	}
	if {[string match "*::" $child]} {
	    set child [string range $child 0 \
		    [expr {[string length $child] - 3}]]
	}
	return "${parent}${child}"
    }
}

# context::head --
#
#	Get the absolute qualifier for the context.  This is 
#	a wrapper around the "namespace qualifier" routine 
#	that turns empty strings into "::".
#
# Arguments:
#	context		A context to retrieve the head from.
#
# Results:
#	The qualified head of the context.

proc context::head {context} {
    set head [namespace qualifier $context]

    # If the head is null, and the context is fully qualified, set 
    # head to be :: so the fact that this context was fully qualified 
    # is not lost.

    if {($head == {}) && ([string match "::*" $context])} {
	set head "::"
    }
    return $head
}

# context::top --
#
#	Get the current context of the Checker.
#
# Arguments:
#	None.
#
# Results:
#	The current qualified context path.

proc context::top {} {
    return [lindex $context::contextStack end]
}

# context::push --
#
#	Set the current context of the Checker.
#
# Arguments:
#	context		The current qualified context path.
#
# Results:
#	None.

proc context::push {context} {
    lappend context::contextStack $context
    return
}

# context::pop --
#
#	Unset the current context of the Checker unless we're 
#	at the global context.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc context::pop {} {
    variable contextStack

    set len [llength $contextStack]
    if {$len > 1} {
	set contextStack [lrange $contextStack 0 [incr len -2]]
    }
    return
}

# context::topProtection --
#
#	Return the protection level on the top of the stack.
#
# Arguments:
#	None.
#
# Results:
#	The protection level on the top of the context stack or 
#	empty string if there is no context on the stack.

proc context::topProtection {} {
    return [lindex $context::protectionStack end]
}

# context::pushProtection --
#
#	Push a new context onto the context stack.  This is 
#	used to identify what type of body we are parsing and
#	which commands are valid.
#
# Arguments:
#	protection	A new protection level (public, private, or protected)
#
# Results:
#	None.

proc context::pushProtection {protection} {
    lappend context::protectionStack $protection
    return
}

# context::popProtection --
#
#	Pop the top of the protection stack.  This is called when
#	a protection command (public, protected, private) finishes.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc context::popProtection {} {
    variable protectionStack
    set len [llength $protectionStack]
    if {$len > 1} {
	set protectionStack [lrange $protectionStack 0 [incr len -2]]
    }
    return
}
