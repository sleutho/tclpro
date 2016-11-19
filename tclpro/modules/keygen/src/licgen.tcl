# licgen.tcl --
#
#	Scriptics License Key Management.
#	This file implements the key generator functions.
#
# Copyright (c) 1998 Scriptics Corporation
#
# This is proprietary source code.
#
# RCS: @(#) $Id: licgen.tcl,v 1.1 2000/06/21 00:06:44 welch Exp $

package provide licgen 1.1

package require licdata 2.0

namespace eval licgen {
    namespace export genkey
}

# licgen::genkey --
#
#	Generate a key based on the customer ID, product ID, version number
#	and expiration date.
#
# Arguments:
#	custid	Customer ID
#	prodid	Product ID
#	version	Version, in the format N.N[ab.]N
#	expire	Expiration date, or 0 for never expires
#
# Results:
#	Return the human readable license key

proc licgen::genkey {custid prodid version expire} {

    # Prepare for licdata::packInt
    licdata::init $version
    global ::licdata::size

    # The first field is the key-type ID, which is 1 for this version.
    
    licdata::packInt 1           $size(K)
    licdata::packInt  $custid	$size(C)
    licdata::packInt  $prodid	$size(P)
 
    set parts [split $version {[ab.]}]
    for {set n 0} {$n < 3} {incr n} {
	set v [lindex $parts $n]
	;# expect major.minor.bugfix, starting at 1.0.0
	licdata::packInt  $v $size(V1)
	if {$v >= 32} {
			error "key format expires at version 32"
	}
    }

    # Time includes 12-bits of years, invalid after 4095

    if {$expire != 0} {
     	set day [string trimleft [clock format $expire -format "%d"] 0]
	set month [string trimleft [clock format $expire -format "%m"] 0]
    	set year [clock format $expire -format "%Y"]
    } else {
    	set day 33
    	set month 13
    	set year 3915
 
    }
    licdata::packInt $month $size(M)
    licdata::packInt $day   $size(D)
    licdata::packInt $year  $size(Y)

    # A little noise makes the checksum harder to predict
   	
    licdata::packInt [clock clicks] $size(Z)

    # Insert one bit of the checksum into each character,
    # then return a human-readable form of the result
    
    licdata::spreadCheck
    return [licdata::key2String]
}

# licgen::gennetkey --
#
#	Generate a network license key based on the customer name,
#	number seats, product ID, version number and expiration date.
#
# Arguments:
#	seats	Number of licenses
#	prodid	Product ID
#	version	Version, in the format N.N[ab.]N
#	expire	Expiration date, or 0 for never expires
#
# Results:
#	Return the human readable license key

proc licgen::gennetkey {seats prodid version expire} {

    # Prepare for licdata::packInt
    licdata::init $version
    global ::licdata::size

    # The first field is the key-type ID, which is 2 for this version.
    
    licdata::packInt 2           $size(K)

    if {0} {
	# Hash the customer name
	# I18N - should respect unicode character class

	set custname [string tolower $custname]
	regsub -all {[^0-9a-z]} $custname {} custname
	set x 0
	foreach c [split $custname {}] {
	    scan $c %c ord
	    set x [expr {(($x + $ord) * 9301 + 49297) % 233280}]
	}

	licdata::packInt  $x	$size(SX)
    }

    licdata::packInt  $seats	$size(ST)
    licdata::packInt  $prodid	$size(P)

    ;# expect major.minor.bugfix, starting at 1.0.0
    set parts [split $version {[ab.]}]
    for {set n 0} {$n < 3} {incr n} {
	set v [lindex $parts $n]
	if {[string length $v] == 0} {
	    set v 0
	}
	if {$v >= 32} {
			error "key format expires at version 32"
	}
	licdata::packInt  $v $size(V1)
    }

    # Get "a", "b", or "." into release
    # Pack a code for this into one "character"

    regexp {[0-9]+\.[0-9]+([ab\.])[0-9]+} $version x release
    array set map {a 0 b 1 . 2}
    licdata::packInt  $map($release) $licdata::nbits

    # Time includes 12-bits of years, invalid after 4095

    if {$expire != 0} {
     	set day [string trimleft [clock format $expire -format "%d"] 0]
	set month [string trimleft [clock format $expire -format "%m"] 0]
    	set year [clock format $expire -format "%Y"]
    } else {
    	set day 33
    	set month 13
    	set year 3915
 
    }
    licdata::packInt $month $size(M)
    licdata::packInt $day   $size(D)
    licdata::packInt $year  $size(Y)

    # A little noise makes the checksum harder to predict
   	
    licdata::packInt [clock clicks] $size(Z2)

    # Insert one bit of the checksum into each character,
    # then return a human-readable form of the result
    
    licdata::spreadCheck
    return [licdata::key2String]
}

