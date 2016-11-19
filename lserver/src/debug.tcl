# License Server Debug Interface
#
# This provides low level access to the license server and
# should not be shipped :-)

package provide lserver 1.0

namespace eval lserver {
    # create namespace for pkg_mkIndex
    namespace export handleform /passwd*
}

# lserver::/setvar
#	Direct URL to set a variable in this namespace
#
# Arguments
#	varname	The variable
#	value	The value
#
# Side Effect
#	Set the variable

proc lserver::/setvar {varname value} {
    regsub {\(.*\)} $varname {} name
    variable $name
    set $varname $value
}

# lserver::/reset
#	Direct URL to reset the license server state
#
# Arguments
#	none
#
# Side Effects
#	Releases all licenses

proc lserver::/reset {} {
    variable state
    variable user
    variable inuse

    lserver::log RESET
    foreach x [array names state] {
	lserver::log state($x) $state($x)
	set a [lindex $state($x) 3]
	catch {after cancel $a}
	unset state($x)
    }
    if {[info exist user]} {
	unset user
    }
    foreach x [array names inuse] {
	set inuse($x) {}
    }
    lserver::init
    return Reset
}

# lserver::handleform
#	Process /debug.html form data
#
# Arguments
#	none
#
# Side Effects
#	Updates parameters

proc lserver::handleform {} {
    global page
    variable state
    variable user
    variable inuse
    variable max
    variable overdraft

    if {![info exist page(query)]} {
	return
    }
    array set query $page(query)

    if {[info exist query(newmax)] && [string length $query(newmax)]} {
	set max($prod) $query(newmax)
    }
    if {[info exist query(newover)] && [string length $query(newover)]} {
	set overdraft($prod) $query(newover)
    }
    return ""
}

# lserver::/passwd/reset
#	Direct URL to clear all passwords
#
# Arguments
#	None
#
# Side Effects
#	Updates the password list

proc lserver::/passwd/reset {} {
    variable password
    
    unset password
    CheckPoint
    return "Password list cleared"
}

# lserver::/password/dump
#	Direct URL to dump all passwords
#
# Arguments
#	None
#
# Side Effects
#	Updates the password list

proc lserver::/passwd/dump {} {
    variable password
    
    set html <table>
    foreach name [array names password] {
	append html "<tr><td>$name</td><td>$password($name)</td></tr>"
    }
    append html </table>
}

