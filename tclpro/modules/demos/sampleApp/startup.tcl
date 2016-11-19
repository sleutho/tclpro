# startup.tcl --
#
#  Startup script for the factorial wrapped application.
#
# Copyright (c) 1998-2000 by Ajuba Solutions.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: startup.tcl,v 1.3 2000/10/31 23:31:11 welch Exp $

# add factorial to the auto_path, so that the package require works

lappend auto_path factorial

package require factorial

if {[llength $argv] < 1} {
    puts "please specify a number"
    exit 1
}

set num [lindex $argv 0]
set max 100

if {![regexp {[0-9]+} $num]} {
    puts "argument must be an integer, you entered \"$num\""
    exit 1
} elseif {($num < 0) || ($num > $max)} {
    puts "argument must be an integer between 0 and $max, you entered $num"
    exit 1
}

puts "factorial($num) = [factorial::calculate $num]"

