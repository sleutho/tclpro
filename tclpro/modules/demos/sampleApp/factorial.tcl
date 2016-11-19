# factorial.tcl --
#
#  This package implements a procedure that calculates the factorial of
#  a number.
#
# Copyright (c) 1998-2000 by Ajuba Solutions.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: factorial.tcl,v 1.3 2000/10/31 23:31:11 welch Exp $

package provide factorial 1.0

namespace eval factorial {
    namespace export calculate
}

# factorial::calculate --
#
#  Calculates the factorial of a number.
#
# Arguments:
#  number	the number whose factorial we want to calculate
#
# Results:
#  Returns the factorial of the argument

proc factorial::calculate {number} {
    if {$number <= 1} {
	return 1
    }

    return [expr {$number * [calculate [expr {$number - 1}]]}]
}
