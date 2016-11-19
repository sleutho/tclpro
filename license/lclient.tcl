# lclient.tcl
#
#	License Server Client Interface
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# All rights reserved.
# 
# RCS: @(#) $Id: lclient.tcl,v 1.3 2000/08/24 21:56:50 welch Exp $

# This prototype hardwires the server location
# It needs platform-specific code to find that information

package provide lclient 1.0
package require http 2.1

namespace eval lclient {

    # server - license manager host

    variable server

    # port - licence manager port

    variable port

    # appinfo - information about the user and application
    #		This is initialized during checkout and used again
    #		during refresh and release operations.

    variable appinfo

    # url - the direct url that accesses the license manager

    variable url /srvr

    # refreshTime - long running applications should check in with
    #	the license manager before this time.
    #	Remember to keep this less than default(timeout) in lserver.tcl

    variable refreshTime 180000	;# 3 minutes

    namespace export checkout release probe
}

# lclient::probe
#	Probe the license manager.
#
# Arguments
#	server	Server location information
#
# Results
#	The company name associated with the license server.
#	Or an error is raised

proc lclient::probe {srvinfo host} {
    variable server
    variable port
    variable appname

    set server [lindex $srvinfo 0]
    set port [lindex $srvinfo 1]
    set noise1 [clock clicks]

    array set info [Request probe host $host noise1 $noise1]
    if {[info exist info(org)]} {
	set appname(org) $info(org)
	return $info(org)
    } else {
	return $info(time)
    }
}


# lclient::checkout
#	Contact the license manager for a license
#
# Arguments
#	server	Server location information
#	prod	Product ID
#	user	User identification
#	host	Host identification
#	appname	Aplication identification
#
# Results
#	A status string, which is either
#		"ok"
#		errorNoServer
#		warnOverdraft $N
#	where N is the number of overdraft days left

proc lclient::checkout {srvinfo prod userid host appname} {
    variable server
    variable port
    variable appinfo
    variable refreshTime

    # Construct the request message
    
    set server [lindex $srvinfo 0]
    set port [lindex $srvinfo 1]
    set noise1 [clock clicks]
    set list [list prod $prod userid $userid host $host \
		    appname $appname noise1 $noise1]

    # Save the parameters for use with refresh and release.

    array set appinfo $list

    # Send the request

    if {[catch {
	array set info [eval {Request checkout} $list]
    } err]} {
	return errorNoServer
    }

    if {![info exist info(status)]} {
	# Unexpected response
	return errorNoServer
    }

    if {[string match error* $info(status)]} {
	# e.g., errorDenied
	return $info(status)
    }

    if {![info exist info(noise1)] || $info(noise1) != $noise1} {
	return errorNoServer
    }
    if {![info exist info(token)] || ![info exist info(org)]} {
	return errorNoServer
    }

    # Save server token for release and refresh

    set appinfo(token) $info(token)
    set appinfo(org) $info(org)

    # Start a periodic refresh (i.e., heartbeat)

    after $refreshTime [list lclient::Refresh $refreshTime]

    return $info(status)
}

# lclient::release
#	Release a license obtained from the license manager
#
# Arguments
#	None

proc lclient::release {} {
    variable appinfo

    if {[info exist appinfo(token)]} {
	RequestAsync release token $appinfo(token) noise1 [clock clicks]
    }
    return ""
}

# lclient::Refresh
#	Refresh a license obtained from the license manager
#
# TODO - worry about errors, ought to callback to the application
#	and try to regain the license.
#
# Arguments
#	None - everything comes from namespace variables
#
# Side Effects
#	Keeps the timer going
#
# Results
#	Status, but just for testing purposes.

proc lclient::Refresh {{after {}}} {
    variable appinfo

    if {[catch {
	RequestAsync refresh token $appinfo(token) noise1 [clock clicks]
	if {[string length $after]} {
	    after $after [list lclient::Refresh $after]
	}
    } err]} {
	return [list error $err]
    } else {
	return [list status ok]
    }
}

# lclient::Request
#	Make a request to the license manager.  This code implements
#	the request using HTTP.  The arguments and results are
#	encoded name, value lists.
#
# Arguments
#	op	The operation code, which maps to a direct URL
#	args	Name, value list of arguments for the op.
#
# Results
#	A name, value list of the results, suitable for array set.
#	This may raise an error for any number of reasons.
proc lclient::Request {op args} {
    variable server
    variable port
    variable url

    set code [licdata::packString $args]
    set x [http::geturl $server:$port$url/$op \
	    -query [http::formatQuery value $code] \
	    -timeout 15000]
    http::wait $x
    switch -- [http::status $x] {
	ok {
	    set result [http::data $x]
	    unset $x

	    # Check return parameters

	    if {[catch {array set info [licdata::unpackString $result]} err]} {
		error "unexpected result from server"
	    }
	    if {[info exist info(error)]} {
		error $info(error)
	    }
	    return [array get info]
	}
	default {
	    set result [http::status $x]
	    unset $x
	    error $result
	}
    }
}

# lclient::RequestAsync
#	Make a request to the license manager, but don't wait for
#	the response.
#
# Arguments
#	op	The operation code, which maps to a direct URL
#	args	Name, value list of arguments for the op.
#
# Results
#	None.

proc lclient::RequestAsync {op args} {
    variable server
    variable port
    variable url

    set code [licdata::packString $args]

    # This -command callback does two things:
    # It lets the request run under the application's event loop.
    # It throws away the state array with the unset

    catch {
	set x [http::geturl $server:$port$url/$op \
	    -query [http::formatQuery value $code] \
	    -timeout 15000 -command unset]
	
	# This gets us through the event loop enough times to
	# let the HTTP POST request get out on the wire.  Added when
	# http 2.3 was in use

	update ; update
    }
    return
}

