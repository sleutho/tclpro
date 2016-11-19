# licdata.tcl --
#
#	Ajuba Solutions License Key Management.
#	This file  has the basic data definitions that are
#	shared between the key generator and the parser.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# This is proprietary source code.
#
# RCS: @(#) $Id: licdata.tcl,v 1.3 2000/08/01 01:49:54 welch Exp $

package provide licdata 2.0

proc Append {args} {
    eval {append string} $args
    return $string
}

namespace eval licdata {
	
    # char - The "characters" of the key are kept here during processing
    # i - The current index into this array
    
    variable char
    variable i
    	
    # The checksum is a  hash of the characters
    
    variable check
    
    # Encode key data in 5-bit words so we can use a 32 char encoding alphabet
    # that is single case. 0-9, A-Z, excluding I, L, O and Q
	
    variable map		;# map value to printing letter
    variable unmap		;# map printing letter to value
    set i 0
    foreach c {0 1 2 3 4 5 6 7 8 9 A B C D E F G H J K M N P R S T U V W X Y Z} {
	set map($i) $c
	set unmap($c) $i
	incr i
    }  
    array set unmap {
	L	1
	I	1
	O	0
	Q	0
    }
    
    # These are a function of the size of the word
    
    variable nbits 4
    variable mask 0xF
    
    # Key Fields: 2 key formats, one for single user, two for floating licensE
    #	1-CCCCCC-PPP-V.V.V-M-DD-YYY-Z
    #	2-SXXXX-ST-PPP-V.V.V-R-M-DD-YYY-Z2
    #
    # There must be at least 18 "characters" in the key in order to
    # spread the complete hash signature value over them.
    #
    # C - customer ID
    # SX - hash over customer name.  This must be at least 18 bits
    #		to cover the hash function we use
    # ST - number of seats
    # P - product ID
    # V - version number
    # R - release: 0=a, 1=b, 2=.
    # M - month
    # D - day of month
    # Y - year
    # Z - noise
    # Z2 - more noise

    # It doesn't work to make the sizes non-multiples of the char size (nbits)
    # because of the way packInt is implemented.

    variable size 
    array set size {
	K  4
	C 24
	SX 20
	ST 8
	P 12
	V1 4
	V2 4
	V3 4
	R  4
	M  4
	D  8
	Y 12
	Z  4
	Z2 16
    }

    # The Windows registry key or Unix filename where the license
    # information is stored and retrieved from.

    variable fileName 

    namespace export *
}

# licdata::init --
#
#	This routine has two functions:
#
#	1. Create the Windows registry key name or the
#	Unix filename needed to retrieve the license
#	data.  This is computed based on the version.
#
#	2. Prepare for key generation by initializing the state machine.
#
# Arguments:
#	version		The version of the application.
#
# Results:
#	None.  Side effect is that namespace "keys" are initialized.

proc licdata::init {version} {
    variable i
    variable check
    variable char

    # Reset pack/unpack state variables

    set i 0
    set check 0
    if {[info exist char]} {
	unset char
    }

    # Some utility scripts don't have the version module

    if {![info exist projectInfo::prefsLocation]} {
	return
    }

    set licdata::fileName [generateLicenseFilename $projectInfo::prefsLocation]

    return
}

# licdata::generateLicenseFilename --
#
#	Calculates the location of the license file for either a
#	windows based machine or other type of OS.
#
# Arguments:
#	prefLoc	The value of the prefsLocation.  Defaults to the current
#		value of $projectInfo::prefsLocation
#
# Results:
#	Returns either a filename or a Windows registry entry
#	

proc licdata::generateLicenseFilename {{prefLoc {}}} {
    global   tcl_platform

    if {[string length $prefLoc] == 0} {
	set prefLoc $projectInfo::prefsLocation
    }

    switch -- $tcl_platform(platform) {
	windows {
            return "$projectInfo::prefsRoot\\$prefLoc"
	}
	default {
	    return [file join $projectInfo::prefsRoot $prefLoc License]
	}
    }
}

# licdata::packInt --
#
#	Store an integer value into a given number of bits.
#	This calculates the checksum as we go along
#
# Arguments:
#	int	the value to pack
#	bits	the width of this value.  This should be a multiple of nbits.
#
# Side Effects:
#	check	compute the running checksum.
#	char	store the results here
#	i	keep track of where we are

proc licdata::packInt {int {bits 32}} {
    variable char
    variable i
    variable check
    variable mask
    variable nbits

    set m $mask
    set j 0
    set limit [expr {$i + ($bits / $nbits)}]
    while {$i < $limit} {
	set char($i) [expr {($int & $m) >> ($j * $nbits)}]
	set m [expr {$m << $nbits}]
	set check [expr {(($check + $char($i)) * 9301 + 49297) % 233280}]
	incr i
	incr j
    }
}

# licdata::checkString --
#
#	Compute a proprietary hash/checksum over a string.
#
# Arguments:
#	string	the value to hash
#
# Results:
#	The hash value

proc licdata::checkString {string} {
    set check 0
    foreach c [split $string {}] {
	set n [scan $c %c x]
	if {$n != 1}  {
	    # If scan cannot handle nulls,  n is -1, not 0 here!
	    set x 0
	}
	set check [expr {(($check + $x) * 9301 + 49297) % 233280}]
    }
    return $check
}

# licdata::packString --
#
#	Store a string value into the encoding array.
#	This calculates the checksum as we go along
#
# Arguments:
#	string	the value to pack
#
# Side Effects:
#	check	compute the running checksum.
#	char	store the results here
#	i	keep track of where we are

proc licdata::packString {string} {
    variable check
    variable char
    variable i
    variable map

    # I18N - this assumes 8-bit characters

    if {[info exist char]} {
	unset char
    }
    set char(0) 15
    set i 1
    set check 0
    foreach c [split $string {}] {
	set n [scan $c %c x]
	if {$n != 1}  {
	    # If scan cannot handle nulls,  n is -1, not 0 here!
	    set x 0
	}
	set char($i) [expr {($x & 0xF)}]
	incr i
	set char($i) [expr {($x & 0xF0) >> 4}]
	incr i
	set check [expr {(($check + $x) * 9301 + 49297) % 233280}]
    }
    spreadCheck
    set result {}
    for {set j 0} {$j < $i} {incr j} {
	append result $map($char($j))
    }
    return $result
}

# licdata::unpackString --
#
#	Extract the encoded string and verify its checksum
#
# Arguments:
#	code		The coded string
#
# Results:
#	This raises an error if the checksum fails.
#	Otherwise the original input string is returneD

proc licdata::unpackString {code} {
    variable char
    variable i
    global ::licdata::mask
    global ::licdata::unmap
    
    set shift 0
    set check2 0
    set check 0
    catch {unset char}
    set result {}
    set type [string index $code 0]
    if {[string compare $type "F"] != 0} {
	error invalidCodedString
    }
    foreach {c1 c2} [split [string range $code 1 end] ""] {
	if {![info exist unmap($c1)] || ![info exist unmap($c2)]} {
	    error invalidCodedString
	}
	set x1 $unmap($c1)
	set x2 $unmap($c2)

	# The original bits are split 4 bits into each word,
	# but left-shifted by one bit to leave room for the checksum.
	# This gets the orginal character code.
	
	set x [expr {(($x1 & 0x1E) >> 1) | (($x2 & 0x1E) << 3)}]
	append result [format %c $x]

	# Get one bit of the checksum


	if {$shift < 20} {
	    set check [expr {$check | (($x1 & 0x1) << $shift)}]
	    incr shift
	    set check [expr {$check | (($x2 & 0x1) << $shift)}]
	    incr shift

	} else {
	    # May want to check second checksum in the rest of the code
	}
	# Compute a second checksum from the character values
	set check2 [expr {(($check2 + $x) * 9301 + 49297) % 233280}]
    }

    if {($check != $check2) || ($code == {})} {
	error invalidCodedString
    }	
    return $result
}

# licdata::spreadCheck --
#
#	Put one bit of the checksum into each word of the key
#
# Side Effects:
#	char	modifies all but the very first key-ID word

proc licdata::spreadCheck {} {
    variable check
    variable i
    variable char

    # Or one bit of the checksum into each char
    # but skip the leading key-type char

    set m 1
    set j 1
    while {$j < $i} {
	if {$check & $m} {
	    set char($j) [expr {($char($j) << 1) | 1}]
	} else {
	    set char($j) [expr {($char($j) << 1) | 0}]
	}
	set m [expr {$m << 1}]
	incr j
	if {($j % 32) == 0} {
	    # Continue to add noise to the coded string
	    set check [expr {($check * 9301 + 49297) % 233280}]
	    set m 1
	}
    }
}

# licdata::key2String --
#
#	Generate a human-readable form of the key
#
# Results:
#	The key

proc licdata::key2String {} {
    variable char
    variable i
    variable map

    # break defines when we break up the long sequence with -
    
    for {set j 0} {$j < $i} {incr j} {
	if {$j > 0 && ($j % 4) == 0} {
	    append key -
	}
	append key $map($char($j))
    }
    return $key
}

# licdata::unpack --
#
#	Extract the characters from a key and verify its checksum
#
# Arguments:
#	key		The human-readable form of the key
#
# Side Effects:
#	This raises an error if the key checksum fails.
#	The characters of the key are put into the char array.

proc licdata::unpack {key} {
    variable char
    variable i
    global ::licdata::mask
    global ::licdata::unmap
    
    set j 0
    set shift 0
    set check2 0
    set check 0
    catch {unset char}
    foreach c [split [string trim [string toupper $key]] ""] {
    	if {[string compare $c -] == 0 || [string compare $c " "] == 0} {
	    continue
    	}
    	
	if {![info exist unmap($c)]} {
	    error invalidKey
	}
	set x $unmap($c)
	if {$j > 0} {
	    # Get one bit of the checksum
		
	    set check [expr {$check | (($x & 0x1) << $shift)}]
	    incr shift

	    # Get a character without the checksum bit
	    
	    set char($j) [expr {($x >> 1) & $mask}]
	} else {
	    # We don't fiddle with the leading key-type character
		
	    set char($j) $x
	}
	# Compute a second checksum from the character values
		
	set check2 [expr {(($check2 + $char($j)) * 9301 + 49297) % 233280}]
	incr j
    }

    if {($check != $check2) || ($key == {})} {
	error invalidKey
    }	

    # prepare for getInt calls

    set i 0
}

# licdata::getInt --
#
#	Extract a field from the key characters.  Call this after the key
#	characters have been unpacked with licdata::unpack.  Successive calls
#	to getInt return successive fields.
#
# Arguments:
#	bits	The size of the field to extract
#
# Side Effects:
#	i		This is updated to point to the next field

proc licdata::getInt {bits} {
    variable char
    variable i
    global ::licdata::nbits
    global ::licdata::mask

    set shift 0
    set m $mask
    set result 0
    set limit [expr {$i + ($bits / $nbits)}]
    while {$i < $limit} {
	set result [expr {$result | (($char($i) & $mask) << $shift)}]
	incr shift $nbits
	incr i
    }
    return $result
}


