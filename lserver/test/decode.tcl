#!/usr/local/bin/tclsh8.0
# \
exec tclsh8.0 "$O" ${1+"$@"}

set home [file dirname [info script]]
lappend auto_path $home [file join $home ../util]
package require lclient
package require licdata 2.0

if {$argc >= 1} {
    set path [lindex $argv 0]
} else {
    set path /etc/prolserver.state
}

proc Main {path} {
    set in [open $path]
    while {[gets $in line] >= 0} {
	set line [string trim $line]
	if {[string length $line] == 0 || [string match #* $line]} {
	    continue
	}
	set key [lindex $line 0]
	set code [lindex $line 1]
	if {[string compare $key "Commit"] == 0} {
	    continue
	}
	puts "$key:"
	foreach {name value}  [licdata::unpackString $code] {
	    puts \t[list $name $value]
	}
    }
}
Main $path
exit 0
