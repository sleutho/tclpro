# expect.tcl --
#
#	Expect demo that executes rlogin but with current DISPLAY.
#
# Example:
#
#    protclsh80 <TclProReleaseDir>/demos/expect.tcl <remote host>
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: expect.tcl,v 1.2 2000/10/31 23:31:07 welch Exp $

package require Expect

# Grab the hostname from the argv list.

if {[string compare [lindex $argv 0] -d] == 0} {
    # Skip debug flag
    set host [lindex $argv 1]
} else {
    set host [lindex $argv 0]
}

if {[string length $host] == 0} {
    puts "usage: protclsh80 expect.tcl ?-d? <remotehost>"
    exit
}

# Set the expect prompt, attempt to use the environment settings, 
# otherwise set a default prompt.

if {[info exists env(EXPECT_PROMPT)]} {
    set prompt $env(EXPECT_PROMPT)
} else {
    set prompt "(%|#|\\$) $"
}

# By setting the timeout to -1, the expect command will wait forever.

set timeout -1

# Spawn the rlogin command and wait for it login to the remotehost.  The
# login is complete when the expect command sees the predetermined prompt.
# Set the DISPLAY environment variable, and begin interaction with the 
# remote shell and expect.

# For login/password processing we do two things:
# Turn on and off "stty echo" so when they are typing the password
# it isn't echoed
# Turn log_user off so we can control what gets displayed to the
# user.  Otherwise they may see their login name twice, once
# as it is echoed to our script, and another when the remote
# machine echoes it.

log_user 0
eval exp_spawn rlogin $argv
expect {
    eof exit
    "assword: " {
	# Untrusted account, we got a password prompt

	send_user "Password: "
	stty -echo
	expect_user "*\n" { 
	    exp_send $expect_out(0,string)
	    send_user \n
	}
	stty echo
	log_user 0
	exp_continue
    }
    "\nlogin: " {
	send_user [string trimleft $expect_out(buffer) \ \r\n]
	expect_user "*\n" {
	    exp_send $expect_out(0,string)
	}
	exp_continue
    }
    -re $prompt {
	# done - we got our prompt
	send_user [string trimleft $expect_out(buffer) \ \r\n]
	log_user 1
    }
}

if {[string match "unix:0.0" $env(DISPLAY)]} {
	set env(DISPLAY) "[exec hostname].[exec domainname]:0.0\r"
}
exp_send "setenv DISPLAY $env(DISPLAY)\r"
exp_interact
