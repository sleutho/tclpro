#!/usr/bin/wish -f

#
# tclx_compat.tcl
# $Id: tclx_compat.tcl,v 1.1 2000/07/14 18:00:06 welch Exp $
#

proc getclock {} {
	return [clock seconds]
}

proc fmtclock {seconds format} {
	return [clock format $seconds -format $format]
}

# csubstr
# clength
# cindex

# random in Tcl---courtesy of Don Libes, slightly hacked since then.
proc random {args} {
	global _ran

	if { [llength $args]>1 } {
		set _ran [lindex $args 1]
	} else {
		set period 233280
		if { [info exists _ran] } {
			set _ran [expr { ($_ran*9301 + 49297) % $period }]
		} else {
			set _ran [expr { [clock seconds] % $period } ]
		}
		return [expr { int($args*($_ran/double($period))) } ]
	}
}

# system
# from the Tcl test suite
proc unlink {fn} {
    global tcl_platform
    if {$tcl_platform(platform) == "macintosh"} {
	catch {rm -f $name}
    } else {
	catch {exec rm -f $name}
    }
}

proc frename {a b} {
    global tcl_platform
    if {$tcl_platform(platform) == "macintosh"} {
	catch {mv -f $a $b}
    } else {
	catch {exec mv -f $a $b}
    }
}

