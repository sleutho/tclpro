#!/usr/local/bin/tclsh8.0
# \
exec tclsh8.0 "$O" ${1+"$@"}

lappend auto_path [file dirname [info script]]
package require lclient

source /home/welch/cvs/pro/srcs/util/licdata.tcl
package require licdata 2.0

proc Main {argc argv} {
    global env
    if {[info exist env(LOGNAME)]} {
	set user $env(LOGNAME)
    } elseif {[info exist env(USER)]} {
	set user $env(USER)
    } else {
	set user "Joe User"
    }
    set prod 2050
    set srvinfo [list pop 8003]
    puts "Using server $srvinfo"
    if {[catch {
	lclient::probe $srvinfo [info hostname]
    } status]} {
	global errorInfo
	puts $errorInfo
    }
    puts "Probe $status"
    if {[catch {
	lclient::checkout $srvinfo $prod $user [info hostname] "demo app"
    } status]} {
	global errorInfo
	puts $errorInfo
    }
    puts "Checkout $status"
    if {[info exists lclient::appinfo(org)]} {
	puts "Company $lclient::appinfo(org)"
    } else {
	puts "No Company Info"
    }
    puts "Pausing..."
    after 10000
    set info [lclient::release]
    puts "Done $info"
}
Main $argc $argv
exit 0
