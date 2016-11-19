# audit.tcl --
#
# Audit/Reporting module for the  License Server
#
# Copyright 1999-2000 Ajuba Solutions

package provide lserver 1.0

namespace eval lserver {
    namespace export auditInit audit
}

# lserver::auditInit
#	Initilise the audit/report system
#
# Arguments
#	None
#
# Side Effects
#	Open the audit file, set summary timer action

proc lserver::auditInit {logPath templatePath} {
    variable file
    set file(audit) $logPath
    set file(templates) $templatePath
    if {![catch {open $file(audit) r} in]} {
	AuditInitCounters $in
	close $in
    } else {
	lserver::log audit file $in
    }
    if {![catch {open $file(audit) a} out]} {
	set file(auditfd) $out
	lserver::log auditInit
	AuditSummary boot
    } else {
	lserver::log audit file $out
    }
}

# lserver::audit
#	Record information for reporting
#
# Arguments
#	type	Record type
#	args	List of things to write out to the file
#
# Side Effect
#	Add a record to the audit file.

proc lserver::audit {type args} {
    global Httpd
    variable file
    variable email
    variable eventlist
    if {[info exist file(auditfd)]} {
	puts $file(auditfd) [concat [list $type [lserver::TodayFixed] \
		[lserver::Time]] $args]
	flush $file(auditfd)
    }
    array set labels $eventlist
    if {[info exist labels($type)]} {
	set label $labels($type)
    } else {
	set label $type
    }
    foreach t [array names email] {
	if {"$t" == "$type"} {
	    set subject "Ajuba Solutions License Server: $label"

	    # Read the message template

	    if {[catch {
		set in [open [file join $file(templates) $type]]
		set X [read $in]
		close $in

		# Define state variables expected by the template

		set info(date) [Today]
		set info(time) [Time]
		set info(label) $label
		array set info $args

		set msg [subst $X]

		# Send the mail

		foreach addr $email($type) {
		    lserver::log email $addr $type
		    lserver::sendmail  $addr $subject "" text/plain $msg
		}
		if {[info exists email(ajuba)] && $email(ajuba)} {
		    lserver::sendmail  licenseinfo@ajubasolutions.com $subject "" text/plain $msg
		}
	    } err]} {
		lserver::log templates $type $err
		continue
	    }
	}
    }
}

# lserver::AuditInitCounters
#	Read the audit file to pre-load on-line counters of max
#	and total use for the day and week.
#
# Arguments
#	in	The open channel to the audit log
#
# Side Effect
#	Updates the "count" array

proc lserver::AuditInitCounters { in } {
    variable counter

    set today [TodayFixed]
    while {[gets $in line] >= 0} {
	if {[catch {
	    set type [lindex $line 0]
	}]} {
	    continue
	} else {
	    set date [lindex $line 1]
	    set time [lindex $line 2]
	    if {[regexp {[0-9]+:[0-9]} $time]} {
		set args [lrange $line 3 end]
	    } else {
		set time ""
		set args [lrange $line 2 end]
	    }

	    switch -- $type {
		weekly {
		    # Skip this, as they are for the previous week
		}
		daily {
		    set key [lindex $args 0]
		    set count [lindex $args 1]
		    set prod [lindex $key 0]
		    if {[string length $prod]} {
			Count weekUse-$prod $count
			if {[string compare $date $today] == 0} {
			    Count todayUse-$prod $count
			}
		    }
		}
		dailymax {
		    set prod [lindex $args 0]
		    set count [lindex $args 1]
		    if {![info exist counter($prod,weekMax)] ||
			    ($counter($prod,weekMax) < $count)} {
			set counter($prod,weekMax) $count
		    }
		    if {[string compare $date $today] == 0} {
			set counter($prod,todayMax) $count
		    }
		}
		checkout {
		    set prod [lindex $args 0]
		    Count weekUse-$prod
		    Count todayUse-$prod
		}
	    }
	}
    }
}

# lserver::AuditSummaryInner
#	Summarize the audit file
#	This is the core routine, exposed for testing.
#
# Arguments
#	how	Either "daily" or "weekly"
#
# Side Effect
#	Re-write the file so the current day's events are summarized
#	into one record.

proc lserver::/auditsummary { {how daily} } {
    lserver::AuditSummaryInner $how
}

proc lserver::AuditSummaryInner { how } {
    variable file
    variable eventlist
    variable counter
    variable inuse
    variable counter

    array set eventlabel $eventlist

    lserver::log AuditSummary $how

    if {[info exist file(auditfd)]} {
	close $file(auditfd)
	unset file(auditfd)
    }

    # Read existing log file into X

    set in [open $file(audit)]
    set X [read $in]
    close $in

    # Generate new version of the log file

    set today [TodayFixed]
    set weekago [clock scan "$today -7 days"]
    set file(auditfd) [open $file(audit) w]
    foreach line [split $X \n] {
	if {[catch {
	    set type [lindex $line 0]
	    set date [lindex $line 1]
	    set time [lindex $line 2]
	    if {[regexp {[0-9]+:[0-9]} $time]} {
		set args [lrange $line 3 end]
	    } else {
		set time ""
		set args [lrange $line 2 end]
	    }
	    if {[string length $date]} {
		set today $date
	    }

	    switch -- $type {
		checkout {
		    # Accumulate counts of individual events
		    # Assert that the date is the same on all
		    # event records, or that it is equivalent.
		    # We'll run every midnight, after all.

		    lassign $args prod userid host appname status
		    set key [list $prod $userid [Appname $appname]]
		    if {$how == "daily"} {
			Incr daily($key)
			switch -- $status {
			    overdraft	-
			    denied	{
				set stat($key) $status
			    }
			}
		    } else {
			Incr weekly($key) 1
			if {![info exist weeklystat($key)]} {
			    set weeklystat($key) {}
			}
			set ix [lsearch $weeklystat($key) $status]
			if {$ix < 0} {
			    lappend weeklystat($key) $status
			}
		    }
		}
		"" {
		    # Ignore empty records
		}
		daily {
		    if {$how == "daily"} {
			puts  $file(auditfd) $line
		    } else {
			# Accumulate daily records into a weekly one

			lassign $args key count status
			lassign $key prod user application
			Incr weekly($key) $count
			if {![info exist weeklystat($key)]} {
			    set weeklystat($key) {}
			}
			set ix [lsearch $weeklystat($key) $status]
			if {$ix < 0} {
			    lappend weeklystat($key) $status
			}
		    }
		}
		weeklymax {
		    # Pass through summary records for previous weeks
		    set sec [clock scan $date]
		    if {$sec <= $weekago} {
			puts $file(auditfd) $line
		    }
		}
		weekly {
		    # Pass through summary records

		    puts $file(auditfd) $line
		}
		dailymax {
		    # Ignore today's record and replace with a new one
		    # Pass through previous day's records
		    if {$how == "daily"} {
			if {[string compare $date $today] != 0} {
			    puts $file(auditfd) $line
			}
		    } else {
			# Drop dailymax during weekly compression
		    }
		}
		default {
		    # Count exceptional events

		    if {[info exist eventlabel($type)]} {
			set label $eventlabel($type)
		    } else {
			set label $type
		    }
		    set key [list "" "" $label]
		    Incr daily($key)
		    set stat($key) $type
		}
	    }
	} err]} {
	    lserver::log "Bad logfile record \"$line\": $err"
	}
    }

    # Summarize last day's information

    foreach key [array names daily] {
	if {[info exist stat($key)]} {
	    set status $stat($key)
	} else {
	    set status ok
	}
	puts $file(auditfd) \
	    [list daily $today $key $daily($key) $status]
    }

    # Save max concurrency information

    if {$how == "daily"} {
	foreach key [array names counter *,todayMax] {
	    regexp {^([0-9]+),} $key x prod
	    if {$counter($key) > 0} {
		puts $file(auditfd) \
		    [list dailymax $today $prod $counter($key)]
	    }
	}
    }

    if {$how == "weekly"} {
	foreach key [array names counter *,weekMax] {
	    regexp {^([0-9]+),} $key x prod
	    if {$counter($key) > 0} {
		puts $file(auditfd) \
		    [list weeklymax $today $prod $counter($key)]
	    }
	}
    }

    foreach key [array names weekly] {
	puts $file(auditfd) \
	    [list weekly $today $key $weekly($key) $weeklystat($key)]
    }
    flush $file(auditfd)

    # Reset daily counter

    foreach x [array names inuse] {
	Counter_Reset todayLicense-$x 0
	Counter_Reset todayUse-$x 0
	set counter($x,todayMax) 0
	if {"$how" == "weekly"} {
	    Counter_Reset weekLicense-$x 0
	    Counter_Reset weekUse-$x 0
	    set counter($x,weekMax) 0
	}
    }
}

# lserver::AuditSummary
#	Summarize the audit file
#
# Arguments
#	none
#
# Side Effect
#	Schedules a periodic call to itself.

proc lserver::AuditSummary { args } {
    variable file
    variable inuse
    variable email

    set now [clock seconds]
    set how daily
    if {([clock format $now -format %w] == 0 &&
	    [clock format $now -format %H] < 1) ||
	    ([clock format $now -format %w] == 6 &&
	    [clock format $now -format %H] >= 23)} {
	# It is between 23:00 on Saturday and 01:00 on Sunday,
	# the end of the week.
	set how weekly
    }

    # Hack - doing weekly summaries right when we boot up is buggy,
    # so we just don't do that

    if {[string compare [lindex $args 0] "boot"] == 0} {
	set how daily
    }

    if {[catch {
	AuditSummaryInner $how
    } err]} {
	global errorInfo
	lserver::log AuditSummary $err
	if {[info exist email(ajuba)] && $email(ajuba)} {
	    lserver::sendmail licenseinfo@ajubasolutions.com "AuditSummary failed" "" \
		text/plain "[info hostname]\n$errorInfo"
	}
    }

    # set after event to consolidate records at midnight

    set now [clock seconds]
    set next [expr {([clock scan 23:59:59 -base $now] -$now + 1000) * 1000}]
    after $next [list lserver::AuditSummary [expr {$now + ($next/1000)}]]
}

# lserver::report
#	Generate a report
#
# Arguments
#	what	What type of report
#
# Results
#	HTML report

proc lserver::report {what} {
    variable file
    variable eventlist
    variable counter

    array set eventlabel $eventlist

    if {[catch {open $file(audit) r} in]} {
	# Shared access (we are also writing this file)
	# may be an issue on windows
	return "Cannot open audit file: $in"
    }
    set lastdate -
    set lastapp -

    while {[gets $in line] >= 0} {
	if {[catch {lindex $line 0} key]} {
	    lserver::log report bad log line $line
	    continue
	}
	set date [lindex $line 1]
	set time [lindex $line 2]
	if {![regexp {[0-9]+:[0-9]+} $time]} {
	    set args [lrange $line 2 end]
	} else {
	    set args [lrange $line 3 end]
	}
	if {[string compare $lastdate "-"] != 0 &&
		![info exist dailymode] &&
		[string compare $lastdate $date] != 0} {
	    append dhtml([clock scan $lastdate]) \
			[ReportDaily $lastdate $what]
	    set lastdate $date
	}
	switch -- $key {
	    daily {
		lassign $args userinfo count status
		lassign $userinfo prod user appname
		regsub "ok" $status {} status

		Incr daily($appname) $count
		Incr weekly($appname) $count
		if {[string compare $status "ok"] != 0} {
		    set daily_stat($appname) $status
		    set weekly_stat($appname) $status
		}
		set lastdate $date
		if {$what == "weekly"} {
		    set dailymode 1
		}
	    }
	    weekly {
		if {"$what" == "weekly"} {
		    lassign $args userinfo count status
		    lassign $userinfo prod user appname
		    regsub "ok" $status {} status

		    Incr weekly($appname) $count
		    if {[string compare $status "ok"] != 0} {
			set weekly_stat($appname) $status
		    }
		    set lastdate $date
		}
	    }
	    checkout {
		lassign $args prod user host appname status
		set a [Appname $appname]
		Incr daily($a) 1
		Incr weekly($a) 1
		if {[string compare $status "ok"] != 0} {
		    set daily_stat($a) $status
		    set weekly_stat($a) $status
		}
		set lastdate $date
	    }
	    dailymax {
		lassign $args prodid max
		set dailymax($prodid) $max
	    }
	    weeklymax {
		lassign $args prodid max
		set weeklymax($prodid) $max
	    }
	    default {
		if {[info exist eventlabel($key)]} {
		    set label $eventlabel($key)
		} else {
		    set label $key
		}
		Incr daily($label)
		Incr weekly($label)
		set daily_stat($label) $key
		set weekly_stat($label) $key
		set lastdate $date

		if {0 && ("$what" == "details")} {
		    append html "<tr>\n"
		    foreach x $line {
			append html "<td>$x</td>\n"
		    }
		    append html "</tr>\n"
		}
	    }
	}
    }
    if {[string compare $lastdate "-"] != 0} {
	append dhtml([clock scan $lastdate]) [ReportDaily $lastdate $what]
    }

    append html "<p>\n"
    append html "This report shows $what usage of TclPro.\n"
    append html "The Concurrency value shows the maximum number of "
    append html "simultaneous users of TclPro tools.\n"
    append html "The Uses value shows the total number of executions "
    append html "of a TclPro application.\n"
    append html "<table>\n"
    append html "<tr><td><b>Log file</b></td><td>$file(audit)</td></tr>\n"
    append html "<tr><td><b>Current Date</b></td><td>[Today] [Time]</td></tr>\n"


    # Sort the daily or weekly records so the most recent appears first

    append html "</table>"

    append html <table>
    foreach d [lsort -integer -decreasing [array names dhtml]] {
	append html $dhtml($d)
    }
    append html </table>
    return $html
}

# lserver::ReportDaily
#	Generate a report
#
# Arguments
#	date		The date of the report
#	dailyVar	The name of the array containing data
#
# Results
#	One day (or week) worth of HTML report

proc lserver::ReportDaily {date dailyVar} {
    upvar 1 $dailyVar daily ${dailyVar}_stat stat ${dailyVar}max max
    variable eventlist

    set first 1 
    set html ""

    # Convert to current format

    set d [clock scan $date]
    set lastweek [Today [clock scan "$date -7 days"]]
    set date [Today $d]

    # Need to separate application counters from
    # system event counters

    foreach {event label} $eventlist {
	if {[info exist daily($label)]} {
	    set d2($label) $daily($label)
	    unset daily($label)
	}
    }

    set total 0
    foreach app [array names daily] {
	if {[string length $app] == 0} {
	    # This comes from other things like "boot" and "license" events
	    continue
	}
	incr total $daily($app)
    }

    if {[string compare $dailyVar "weekly"] == 0} {
	set datehtml "<th rowspan=2>$lastweek<br>$date</th>\n"
	set skip 1
    } else {
	set datehtml "<th>$date</th>\n"
	set skip 0
    }

    set hit 0
    if {[llength [array names max]]} {
	set hit 1
	append html "<tr>\n"
	append html "$datehtml"
	append html "<th>Product</th>\n"
	append html "<th align=center>Concurrency</th>\n"
	append html "</tr>\n"
    }
    foreach prod [array names max] {
	append html "<tr>\n"
	if {$skip} {
	    set skip 0
	} else {
	    append html "<th>&nbsp;</th>\n"
	}
	append html "<th>[Name $prod]</th>\n"
	append html "<th align=center>$max($prod)</th>\n"
	append html "</tr>\n"
    }
    if {$hit} {
	append html "<tr>\n"
	append html "<th>&nbsp;</th>\n"
	append html "</tr>\n"
    }

    append html "<tr>\n"
    if {!$hit} {
	append html "$datehtml"
	set hit 1
    } else {
	append html "<th>&nbsp;</th>\n"
    }
    append html "<th>Application</th>\n"
    append html "<th align=center>Uses</th>\n"
    append html "</tr>\n"

    foreach app [array names daily] {
	if {[string length $app] == 0} {
	    # This comes from other things like "boot" and "license" events
	    continue
	}
	append html "<tr>\n"
	if {$skip} {
	    set skip 0
	} else {
	    append html "<td>&nbsp;</td>\n"
	}
	append html "<td>$app</td>\n"
	append html "<td align=center>$daily($app)</td>\n"
	append html "</tr>\n"
    }
    append html "<tr>\n"
    if {$skip} {
	set skip 0
    } else {
	append html "<td>&nbsp;</td>\n"
    }
    append html "<th>Total Uses</th>\n"
    append html "<th align=center>$total</th>\n"
    append html "</tr>\n"


    append html "<tr>\n"
    append html "<th>&nbsp;</th>\n"
    append html "</tr>\n"

    set hit 0
    foreach app [array names d2] {
	if {!$hit} {
	    set hit 1
	    append html "<tr>\n"
	    append html "<th>&nbsp;</th>\n"
	    append html "<th>System Event</th>\n"
	    append html "<th>&nbsp;</th>\n"
	    append html "</tr>\n"
	}
	append html "<tr>\n"
	append html "<td>&nbsp;</td>\n"
	append html "<td>$app</td>\n"
	append html "<td align=center>$d2($app)</td>\n"
	append html "</tr>\n"
    }
    if {$hit} {
	append html "<tr>\n"
	append html "<th>&nbsp;</th>\n"
	append html "</tr>\n"
    }

    if {[info exist daily]} {
	unset daily
    }
    if {[info exist stat]} {
	unset stat
    }
    if {[info exist max]} {
	unset max
    }
    return $html
}

# lserver::reportusers
#	Generate a report about current users
#
# Arguments
#	none
#
# Results
#	HTML report

proc lserver::reportusers {args} {
    variable user
    variable inuse
    variable state
    variable max

    append html "<h4>[Today] [Time]</h4>"
    foreach prod [array names inuse] {
	append html "<h3>[lserver::Name $prod]</h3>"
	if {[llength $inuse($prod)] > 0} {
	    append html "<table border=1 cellpadding=3>\n"
	    append html "<tr><th>User</th>"
	    append html "<th>Application</th>"
	    append html "<th>Start Time</th>"
	    append html "</tr>"
	    foreach u $inuse($prod) {
		lassign $u p person
		append html "<tr><td>$person</td>"
		set first 1
		foreach token $user($u) {
		    if {$first} {
			set first 0
		    } else {
			append html "<tr><td>&nbsp;</td>"
		    }
		    append html "<td>[Appname [lindex $state($token) 2]]</td>"
		    set date [lindex $state($token) 4]
		    set d [clock scan $date]
		    append html "<td>[Today $d] [Time $d]</td>"
		    append html "</tr>\n"
		}
	    }
	    if {[llength $inuse($prod)] > $max($prod)} {
		set over "Overdraft Status"
	    } else {
		set over ""
	    }
	    append html "<tr><td colspan=3>\n"
	    append html "<table>\n"
	    append html "<tr><td>Total</td><td>[llength $inuse($prod)]</td>"
	    append html "<td>Limit</td><td>$max($prod)</td>\n"
	    append html "<td>$over</td></tr>\n"
	    append html "</table></td></tr>\n"
	    append html "</table>\n"
	} else {
	    append html "<p>No users"
	}
    }
    return $html
}

# lserver::Appname
#	Pretty-fy the application name
#
# Arguments
#	appname	Argv0 of the application
#
# Results
#	"TclPro Debugger", etc.

proc lserver::Appname {appname} {
    set vers [lindex $appname 1]
    set a [string tolower [lindex $appname 0]]
    switch -glob -- $a {
	*debug*	{ return "TclPro Debugger $vers"}
	*check*	{ return "TclPro Checker $vers"}
	*wrap*	{ return "TclPro Wrapper $vers"}
	*comp*	{ return "TclPro Compiler $vers"}
	default	{ 
	    variable eventlist
	    array set labels $eventlist
	    if {[info exist labels($a)]} {
		return $labels($a)
	    } else {
		return $appname
	    }
	}
    }
}

# lserver::sendmail
#
#	Send email.
#
# Arguments:
#
# sendto	The destination address
# subject	The message subject
# from		The from address - can be the empty string.
# type		The mime type of the content, (e.g., text/plain text/html)
# body		The content of the message

proc lserver::sendmail {sendto subject from type body} {
    global tcl_platform
    set headers  \
"To: $sendto
Subject: $subject
Mime-Version: 1.0
Content-Type: $type"
    if {[string length $from]} {
	append headers "\nFrom: $from"
    }

    set message "$headers\n\n$body"

    switch $tcl_platform(platform) {
	unix {
	    if {[catch {
		exec /usr/lib/sendmail $sendto << $message
	    } err]} {
	    lserver::log sendmail $sendto $err
	    } else {
		return "<font size=+1><b>Thank You!</font></b><p>Mailed report to <b>$sendto</b>"
	    }
	}
	default	{
	    lserver::log sendmail unsupported platform $tcl_platform(platform)
	}
    }
    return "Unable to send mail"
}

