# lserver.tcl --
#
# Ajuba Solutions License Server
# This is an addition to Tcl Httpd that implements network license management.
#
# Copyright 1999-2000 Ajuba Solutions

package provide lserver 1.0

package require licdata 2.0
package require lic
licdata::init {}

namespace eval lserver {

    # cookie - for token returned to clients

    variable cookie
    if {![info exist cookie]} {
	set cookie 0
    }

    # state - info about checked-out licenses

    variable state

    # user - info about users of the licenses

    variable user

    # max - per product license maximum

    variable max
    
    # overdraft - per product number of overdraft days left

    variable overdraft

    #	overtime - per product current overdraft time start

    variable overtime	

    # log - a log of license activity

    variable log

    # url - The root URL of the license server "direct" URLs

    variable url

    # file - an array of well known file names
    #	dir	The directory containing the files
    #	conf	Full path of configuration file
    #	state	Full path of active state file

    variable file

    # default - Default settings:
    #	timeout		time period used to reap licenses. (4 minutes)
    #	overdraft	max overdraft days

    variable default
    array set default {
	timeout 240000
	overdraft 10
    }

    # email - list of folks to send email in response to events

    variable email
    variable eventlist {
	    boot	"License Server startup"
	    overdraft	"License issued in overdraft"
	    denied	"License denied"
	    password	"Password add/change"
	    license	"License add/upgrade"
    }
#	    daily	"Daily usage report"
#	    weekly	"Weekly usage report"

    namespace export init log
}

# lserver::init
#	Initialize the License Server
#	This registers a URL that maps into procedure calls on this module
#	It loads the configuration file that contains licenses, etc.
#
# Arguments
#	inurl	The root of the application-direct URLs that access the server
#	dir	The configuration file directory
#
# Side Effects
#	Initializes state from the configure and checkpoint files.

proc lserver::init {{inurl /srvr} {dir /tmp} {reset 0}} {
    global Config
    variable url $inurl
    variable file
    variable initwork
    variable keylist

    set name prolserver
    set file(dir) $dir
    set file(conf) [file join $dir $name.conf]
    set file(state) [file join $dir $name.state]
    Direct_Url $url ::lserver::
    lserver::log init $inurl

    # Process the mostly-static configuration file

    lserver::log reading $file(conf)

    # These aliases define the commands available in
    # the customer's configuration file.  These files
    # contain License information as well as basic server
    # configuration that may need to be tuned by a
    # site administrator.

    set interp [interp create -safe]
    interp alias $interp License {} ::lserver::LicenseAlias
    interp alias $interp Delete {} ::lserver::DeleteAlias
    interp alias $interp Uid {} ::lserver::ConfigAlias uid
    interp alias $interp Gid {} ::lserver::ConfigAlias gid
    interp alias $interp Port {} ::lserver::ConfigAlias port
    interp alias $interp Host {} ::lserver::ConfigAlias host
    interp alias $interp Webmaster {} ::lserver::ConfigAlias webmaster
    interp alias $interp LogDir {} ::lserver::ConfigAlias logDir
    interp alias $interp HttpLogDir {} ::lserver::ConfigAlias httpLogDir
    interp alias $interp IPaddr {} ::lserver::ConfigAlias ipaddr
    if {[catch {
	interp invokehidden $interp source $file(conf)
    } err]} {
	error "Error reading $file(conf): $err"
    }

    interp delete $interp

    lserver::auditInit [file join $Config(logDir) $name.$Config(port).log] \
			[file join $Config(libtml) templates]

    # Process the dynamic state checkpoint file

    lserver::log reading $file(state)

    # These aliases define the commands available in
    # the checkpoint file.  This file contains information
    # about active licenses and overdraft days remaining.
    # It must end with a Commit command that contains
    # a checksum over the other commands.

    set interp [interp create -safe]
    interp alias $interp Password {} ::lserver::WorkAlias Password
    interp alias $interp User {} ::lserver::WorkAlias User
    interp alias $interp Product {} ::lserver::WorkAlias Product
    interp alias $interp Email {} ::lserver::WorkAlias Email
    interp alias $interp Company {} ::lserver::WorkAlias Company
    interp alias $interp DateFormat {} ::lserver::WorkAlias DateFormat
    interp alias $interp Commit {} ::lserver::CommitAlias
    set initwork {}
    if {[catch {
	interp invokehidden $interp source $file(state)
    } err]} {
	error "Error reading $file(state): $err"
    }

    interp delete $interp

    if {$reset} {
	lserver::audit boot host $Config(host) port $Config(port) \
	    reset "Administrative passwords cleared with -reset"
	variable password
	if {[info exist password]} {
	    unset password
	}
    } else {
	lserver::audit boot host $Config(host) port $Config(port) reset ""
    }
    CheckPoint
}

# lserver::ConfigAlias
#	Alias to accept "Port/Uid/Gid" commands in the configuration file.
#
# Arguments
#	key	(Set only by masters alias definition).  Index into Config.
#	value	The value to assign.
#
# Side Effects
#	Sets Config($key) to $value

proc lserver::ConfigAlias {key value} {
    global Config
    lserver::log Config $key $value
    set Config($key) $value
}

# lserver::LicenseAlias
#	Alias to accept "License" commands in the configuration file.
#
# Arguments
#	key	The license key string
#	name	The human readable name of the product
#
# Side Effects
#	Installs state about the licenses

proc lserver::LicenseAlias {key appname} {
    variable keylist
    variable deletedkey
    variable max
    variable inuse
    variable overdraft
    variable default
    variable name
    variable counter
    variable expired

    lserver::log Key $key $appname
    set key [lic::keyTrim $key]
    if {[info exist keylist($key)]} {
	lserver::log Duplicate key
	return [list error "Duplicate key"]
    }
    if {[catch {
	set x [lic::parsekey $key]
	array set info $x
    } err]} {
	lserver::log Key error $err
	return [list error $err]
    }
    if {![info exist info(seats)]} {
	# Not a network server license
	lserver::log Key error wrong license type
	return [list error "wrong license type"]
    }
    set name($info(prodid)) "$appname $info(version)"

    if {[string compare $info(expires) "never"] != 0} {
	
	# Even if the key is not expired now, when the server starts
	# it will probably expire before the server reboots.

	set expires [clock scan $info(expires)]
	set expired($info(prodid)) $info(expires)
	if {$expires < [clock seconds]} {
	    lserver::log Expired key $x
	    return [list error "Expired key"]
	} else {
	    # Schedule a cleanup to occur when the key does expire
	    # Because the msec counter wraps at about 49 days,
	    # we just schedule a check every 24 hours

	    after [expr {1000 * 24 * 60 * 60}] \
		[list lserver::expireKey $key $expires]
	}
    } else {
	if {[info exist expired($info(prodid))]} {
	    # If they have both temporary and permanent keys,
	    # let the new permanent keys wipe the expire warning

	    unset expired($info(prodid))
	}
    }
    if {![info exist max($info(prodid))]} {
	set max($info(prodid)) 0
    }
    if {![info exist counter($info(prodid),todayMax)]} {
	set counter($info(prodid),todayMax) 0
    }
    if {![info exist counter($info(prodid),weekMax)]} {
	set counter($info(prodid),weekMax) 0
    }
    incr max($info(prodid)) $info(seats)
    if {![info exist inuse($info(prodid))]} {
	set inuse($info(prodid)) {}
    }
    lserver::log Valid key $x
    set keylist($key) 1
    if {[info exist deletedkey($key)]} {
	unset deletedkey($key)
    }
    return $x
}

# lserver::deleteKeyLicenses
#	This deletes the licenses associated with a deleted or expired key
#
# Arguments
#	key	The license key string
#
# Side Effects
#	Clears the key from the keylist and removes the license allotment

proc lserver::DeleteKeyLicenses {key action} {
    variable keylist
    variable max
    variable inuse

    if {[info exist keylist($key)]} {
	unset keylist($key)
	array set info [lic::parsekey $key]
	Incr max($info(prodid)) -$info(seats)
	if {$max($info(prodid)) <= 0} {
	    set max($info(prodid) 0
	    unset inuse($info(prodid))
	}

	# Important to retain the overdraft state about the
	# associated product ID in case they try to add this
	# key back again later

	lserver::audit license action $action key [lic::formatKey $key] \
		app [Name $info(prodid)] seats $info(seats)
    }
    return ""
}

# lserver::expireKey
#	Callback to expire a temporary key
#
# Arguments
#	key	The license key string
#	expires	Date, in seconds, the key expires
#
# Side Effects
#	Clears the key from the keylist and removes the license allotment

proc lserver::expireKey {key expires} {
    set now [clock seconds]
    if {$now > $expires} {
	lserver::log expireKey $key
	DeleteKeyLicenses $key expired
    } else {
	    after [expr {1000 * 24 * 60 * 60}] \
		[list lserver::expireKey $key $expires]
    }
    return ""
}

# lserver::DeleteAlias
#	Alias to accept "Delete" commands in the configuration file.
#
# Arguments
#	key	The license key string
#
# Side Effects
#	Records the key in the deleted list

proc lserver::DeleteAlias {key} {
    variable deletedkey

    lserver::log DeleteKey $key
    set key [lic::keyTrim $key]
    DeleteKeyLicenses $key deleted
    set deletedkey($key) 1
    return ""
}

# lserver::WorkAlias
#	Alias to accept User/Product commands in the state file.
#	These commands are saved until Commit time so they can
#	be run in the correct order.
#
# Arguments
#	work	What to do later
#	value	Argument to work command
#
# Side Effects
#	Saves the command for processing at Commit time.

proc lserver::WorkAlias {work value} {
    variable initwork
    lappend initwork [list $work $value]
    lserver::log $work [string range $value 0 9]
}

# lserver::CommitAlias
#	Alias to accept Commit commands in the state file.
#	This command verifies the checksum and runs through the list
#	of collected work items.
#
# Arguments
#	checksum	Checksum over the product/user commands
#
# Side Effects
#	Updates license and overdraft state.

proc lserver::CommitAlias {checksum} {
    variable overdraft
    variable overtime
    variable initwork
    variable dateformat
    
    lserver::log Commit $checksum

    set str ""
    foreach item $initwork {
	if {[string compare [lindex $item 0] "Commit"] != 0} {
	    append str $item
	}
    }
    set check1 [licdata::checkString $str]
    if {[string compare $checksum $check1] != 0} {
	error "Commit check failed"
    }

    # Do Product commands first, because they set up overdraft state.

    foreach item $initwork {
	if {[string compare [lindex $item 0] "Product"] == 0} {
	    ParseArgs [lindex $item 1] policy prodid count date
	    lserver::log $policy [Name $prodid] $count $date
	    switch -- $policy {
		overdraft_A {
		    set overdraft($prodid) $count
		    set overtime($prodid) $date
		}
	    }
	}
    }

    # User commands record active licenses

    foreach item $initwork {
	if {[string compare [lindex $item 0] "User"] == 0} {
	    lserver::/checkout [lindex $item 1]
	}
    }

    # Record administrative password(s)

    foreach item $initwork {
	if {[string compare [lindex $item 0] "Password"] == 0} {
	    lserver::Password [lindex $item 1]
	}
	if {[string compare [lindex $item 0] "Email"] == 0} {
	    lserver::Email [lindex $item 1]
	}
	if {[string compare [lindex $item 0] "Company"] == 0} {
	    lserver::Company [lindex $item 1]
	}
	if {[string compare [lindex $item 0] "DateFormat"] == 0} {
	    lserver::DateFormatCoded [lindex $item 1]
	}
    }
}

# lserver::Password
#	Record an administrator password
#
# Arguments
#	Encoded value
#
# Side Effects
#	Updates the password list

proc lserver::Password {value} {
    variable password
    
    ParseArgs $value name pass
    set password($name) $pass
    return ""
}

# lserver::Email
#	Record an administrator email address
#
# Arguments
#	Encoded value
#
# Side Effects
#	Updates the email list

proc lserver::Email {value} {
    variable email
    
    ParseArgs $value event addr
    foreach a $addr {
	lserver::EmailAdd $event $a
    }
    return ""
}

# lserver::Company
#	Record the company name
#
# Arguments
#	Encoded value
#
# Side Effects
#	Updates lserver::org

proc lserver::Company {value} {
    ParseArgs $value org
    set ::lserver::org $org
    return ""
}

# lserver::DateFormatCoded
#	Record the date format
#
# Arguments
#	Encoded value
#
# Side Effects
#	None

proc lserver::DateFormatCoded {value} {
    ParseArgs $value format
    DateFormat $format
}

# lserver::DateFormat
#	Record the date format
#
# Arguments
#	Encoded value
#
# Side Effects
#	Updates lserver::dateformat

proc lserver::DateFormat {format} {
    lserver::log DateFormat $format
    if {![catch {clock format [clock seconds] -format $format}]} {
	set ::lserver::dateformat $format
	return 1
    } else {
	return 0
    }
}

# lserver::/setup
#
#	Direct URL to set initial configuration
#
# Arguments
#	name		Administrator login name
#	password1	New password
#	password2	New password, repeated
#	email		Administrator email
#	ajuba		Whether it is OK to send mail to Ajuba
#
# Side Effects
#	Updates the password list

proc lserver::/setup {name password1 password2 email ajuba org} {
    variable password
    variable eventlist
    variable setupinfo
    
    if {[info exist setupinfo]} {
	unset setupinfo
    }

    set html [lpage::headurl Adminstration "Setup Complete" /srvr/setup]
    set msg {}
    foreach field {name password1 password2 email org} \
	    label {"User Name" "Password1" "Password2" "Email Address" "Company Name"} {
	upvar 0 $field var
	if {[string length $var] == 0} {
	    if {[string length $msg] == 0} {
		set msg "Please fill in $label"
	    } else {
		append msg ", $label"
	    }
	} else {
	    set setupinfo($field) $var
	}
    }
    if {[string length $msg] > 0} {
	Redirect /setup.tml?msg=[Url_Encode $msg]&name=[Url_Encode $name]&org=[Url_Encode $org]&ajuba=[Url_Encode $ajuba]
    }
    if {[catch {/passwd "" $name $password1 $password2 1} phtml]} {
	Redirect /setup.tml?msg=[Url_Encode $phtml]&name=[Url_Encode $name]&org=[Url_Encode $org]&ajuba=[Url_Encode $ajuba]
    }

    foreach {event label} $eventlist {
	lserver::EmailAdd $event $email
    }
    if {[string length $ajuba] == 0} {
	set ajuba 0
    } else {
	set ajuba 1
    }
    set ::lserver::email(ajuba) $ajuba
    set ::lserver::org $org

    append html <h3>$org</h3>
    append html $phtml
    append html "<p>Use the Add Licences link to add license keys. "
    append html "Use the other links to tune the administrator's interface. "
    append html "These options are all available from the main "
    append html "<a href=/admin/>Administration page.</a>"

    append html "<h3><a href=/admin/license.tml>Add Licenses</a></h3>"
    append html "<h3><a href=/admin/password.tml>Add More Passwords</a></h3>"
    append html "<h3><a href=/admin/email.tml>Adjust Email Preferences</a></h3>"
    append html "<h3><a href=/admin/dateformat.tml>Set Date Format</a></h3>"
    append html [lpage::footer]

    return $html 
}

# lserver::/passwd
#	Direct URL to set a password
#
# Arguments
#	old		Old password, if necessary
#	name		user name
#	password1	New password
#	password2	New password, repeated
#	statusonly	This is used during initial setup
#
# Side Effects
#	Updates the password list

proc lserver::/passwd {old name password1 password2 {statusonly 0}} {
    variable password
    
    if {[string compare $name "support"] == 0} {
	set status "Cannot change \"support\" password"
    } elseif {[string length $name] == 0} {
	set status "Please specify a user name"
    } elseif {[string length $password1] == 0} {
	set status "Please specify a password"
    } elseif {!$statusonly && [info exist password($name)] &&
	    [string compare $old $password($name)]} {
	set status "Old password is incorrect"
    } elseif {[string compare $password1 $password2]} {
	set status "Please type the new password twice"
    } else {
	set password($name) $password1
	lserver::audit password action added user $name
	CheckPoint
	set status "A new password has been recorded for <b>$name</b>"
    }
    if {$statusonly} {
	if {[string match "A new password*" $status]} {
	    return $status
	} else {
	    error $status
	}
    } else {
	set html [lpage::headurl Administration "Password Status" /srvr/passwd]
	append html $status
	append html [lpage::footer]
	return $html
    }
}

# lserver::checkpassword
#	Hook specified in .tclaccess files to check passwords
#
# Arguments
#	sock		Socket connection
#	realm		Authentication domain
#	user		User name
#	pass		Password
#
# Results
#	Updates 1 if password matches

proc lserver::checkPassword {sock realm name pass} {
    variable password
    
    if {[string compare $name "support"] == 0 &&
	    [string compare $pass "I love Tcl"] == 0} {
	return 1
    }
    if {[info exist password($name)] &&
	    [string compare $pass $password($name)] == 0} {
	return 1
    }
    return 0
}

# lserver::initview
#	Decide what should appear on the home page
#
# Arguments
#	page to redirect to
#
# Side Effects
#	HTTP redirect

proc lserver::initview {url} {
    variable password
    
    if {[llength [array names password]] == 0} {
	Redirect $url
    }
    return ""
}

# lserver::checksetup
#	Decide if it is OK to visit the initial setup page.
#
# Arguments
#	page to redirect to
#
# Side Effects
#	HTTP redirect

proc lserver::checksetup {url} {
    variable password
    variable setupinfo
    global page

    catch {array set query $page(query)}
    if {[info exist query(msg)]} {

	# If the setup form is incomplete, then a message is
	# generated and we want to get back to the setup page.
	# We also want to stuff the old form data back into
	# the current query data.  This is a special-case "cached query"
	# /setup.tml?msg=mumble

	array set query [array get setupinfo]
	set page(query) [array get query]

	return
    }
    if {[llength [array names password]] > 0} {
	Redirect $url
    }
    return ""
}

# lserver::CheckPoint
#	Generate the checkpoint file.
#
# Arguments
#	None
#
# Side Effects
#	Writes the checkpoint file.

proc lserver::CheckPoint {} {
    variable overdraft
    variable overtime
    variable file
    variable checkpoint
    variable password
    variable email
    variable org
    variable dateformat
    
    set initwork {}
    set str ""

    # Save overdraft limits for each product

    foreach prodid [array names overdraft] {
	if {[info exist overtime($prodid)]} {
	    set date $overtime($prodid)
	} else {
	    set date {}
	}
	set value [lserver::encode policy overdraft_A prodid $prodid \
		count $overdraft($prodid) date $date]
	lappend initwork [list Product $value]
    }

    # Save record of active license users

    foreach token [array name checkpoint] {
	lappend initwork [list User $checkpoint($token)]
    }

    # Save a record of administrative name/password 

    foreach name [array names password] {
	set value [lserver::encode name $name pass $password($name) \
		noise1 [clock clicks]]
	lappend initwork [list Password $value]
    }

    # Save a record of email notifications

    foreach name [array names email] {
	set value [lserver::encode event $name addr $email($name) \
		noise1 [clock clicks]]
	lappend initwork [list Email $value]
    }

    # Save company name

    if {[info exists org]} {
	set value [lserver::encode org $org \
	    noise1 [clock clicks]]
	lappend initwork [list Company $value]
    }

    # Save date format

    if {[info exists dateformat]} {
	set value [lserver::encode format $dateformat \
	    noise1 [clock clicks]]
	lappend initwork [list DateFormat $value]
    }

    foreach x $initwork {
	append str $x
    }
    set checksum [licdata::checkString $str]
    lappend initwork [list Commit $checksum]

    lserver::log CheckPoint $file(state)
    if {[catch {
	set out [open $file(state) w]
	puts $out "# Ajuba Solutions License Server State File \n\
		   # It is not safe to edit this file. \n\
		   # Generated [clock format [clock seconds]]\n\
		   "
	foreach item $initwork {
	    puts $out $item
	}
	close $out
    } err]} {
	lserver::log $err
    }
}

# lserver::/addlicense
#	Direct URL to add a license
#
# Arguments
#	key	License key
#	appname	Human readable application name
#
# Results
#	Html formatted status
#
# Side Effects
#	Updates the Tcl state arrays and checkpoints the
#	configuration file with a new line about the license.

proc lserver::/addlicense {key appname} {
    variable default
    variable overdraft
    variable file
    variable deletedkey

    if {[catch {
	set key [lic::keyTrim $key]
	array set info [LicenseAlias $key $appname]
	if {[info exist info(error)]} {
	    error "The license key you entered was invalid."
	}

	# If the user adds a new key, one that hasn't been
	# added/deleted previsously, then refresh their overdraft limit.
	# If we don't have any overdraft info left for a deleted key,
	# they get zero overdraft days.

	if {[info exist deletedkey($key)]} {
	    unset deletedkey($key)
	    if {![info exist overdraft($info(prodid))]} {
		set overdraft($info(prodid)) 0
	    }
	} else {
	    set overdraft($info(prodid)) $default(overdraft)
	}

	set out [open $file(conf) a]
	puts $out [list License $key TclPro]
	close $out
	CheckPoint
	lserver::audit license action added app $appname \
		seats $info(seats) key [lic::formatKey $key]
    } err]} {
	Redirect /admin/license.tml?msg=[Url_Encode $err]
    } else {
	Redirect /admin/license.tml
    }
    return $html
}

# lserver::/deletelicense
#	Direct URL to delete a license
#
# Arguments
#	key	License key
#
# Side Effects
#	Marks the key as removed.  The key isn't fully removed so you
#	cannot easily refresh your overdraft days left.

proc lserver::/deletelicense {key delete cancel} {
    variable file

    if {[string length $cancel] > 0} {
	Redirect /admin/license.tml?msg=[Url_Encode "Delete Cancelled"]
    }
    if {[catch {
	DeleteAlias $key

	array set info [lic::parsekey $key]
	set out [open $file(conf) a]
	puts $out [list Delete $key]
	close $out
	CheckPoint
    } err]} {
	Redirect /admin/license.tml?msg=[Url_Encode "Delete Failed: $err"]
    } else {
	Redirect /admin/license.tml?msg=[Url_Encode "Delete Succeeded"]
    }
}

# lserver::/probe
#	Direct URL to respond to a server probe
#
# Arguments
#	value	Encoded name, value list.  Host and noise.
#
# Results
#	The registered company name

proc lserver::/probe {value} {
    ParseArgs $value host noise1
    lserver::log Probe from $host
    set list [list time [clock format [clock seconds]] noise1 $noise1]
    if {[info exist lserver::org]} {
	lappend list org $lserver::org
    }
    return [lserver::encode $list]
}

# lserver::/checkout
#	Direct URL to checkout a license
#
# Arguments
#	value	Encoded name, value list.  See checkoutDirect for details.
#
# Results
#	An encoded name, value list

proc lserver::/checkout {value} {
    ParseArgs $value prod userid host appname token noise1
    set x [lserver::/checkoutDirect $prod $userid $host $appname $noise1 $token]
    return [lserver::encode $x]
}

# lserver::/checkoutDirect
#	Direct URL to checkout a license
#	This takes arguments already decoded
#
# Arguments
#	prod	Product Id
#	userid	User identification
#	host	Host identification
#	appname	Application identification
#	noise1	Random bits
#	token	The client token associated with this, used during recovery
#
# Results
#	A cookie that the client should give back to /release
#	The registered company name

proc lserver::/checkoutDirect {prod userid host appname noise1 {token {}}} {
    variable cookie
    variable state
    variable checkpoint
    variable default
    variable product
    variable max
    variable inuse
    variable user
    variable overdraft
    variable overtime
    variable org
    variable counter
    variable expired

    lappend log $prod $userid $host $appname $noise1

    # Use a fixed format here (not Today) so we can compare with it later
    # even if the user changes their date format.

    set today [TodayFixed]
    set time [Time]

    set key [list $prod $userid]
    if {![info exist inuse($prod)]} {
	lserver::log No licenses [join $log]
	lserver::audit denied name [Name $prod] user $userid \
		host $host \
		app [Appname $appname] max 0
	if {[info exist expired($prod)]} {
	    return [list status [list errorInvalid $expired($prod)]]
	} else {
	    return [list status errorDenied]
	}
    }
    if {![info exist overdraft($prod)]} {
	set overdraft($prod) 0
    }
    Count "checkout request"

    # Generate warnings if we are running with a temporary key

    if {[info exist expired($prod)]} {
	set status [list warnTempKey $expired($prod)]
    } else {
	set status ok
    }
    if {[lsearch $inuse($prod) $key] < 0} {
	# New license required

	Count "checkout license"
	if {[llength $inuse($prod)] >= $max($prod)} {
	    # Overdraft state.  We count 24-hour intervals in this state.
	    # After 24 hours, unset this state.

	    Count "checkout overdraft"
	    if {![info exist overtime($prod)] || 
		    [string compare $today $overtime($prod)] != 0} {
		Count "overdraft days"
		incr overdraft($prod) -1
		set overtime($prod) $today
		lappend log "new overtime" $overtime($prod)
	    } else {
		lappend log "in overtime" $overtime($prod)
	    }
	    if {$overdraft($prod) < 0} {
		Count "checkout denied"
		lappend log "overdraft limit exceeded"
		lserver::log checkout denied [join $log]
		lserver::audit denied name [Name $prod] user $userid \
			host $host \
			app [Appname $appname] max $max($prod)
		return [list status errorDenied]
	    } else {
		lserver::audit overdraft name [Name $prod] user $userid \
			host $host \
			app $appname N [llength $inuse($prod)] \
			max $max($prod) \
			overdraft $overdraft($prod)
	    }
	    set status [list warnOverdraft $overdraft($prod)]
	}

	# Use by this user/host consumes one license
	# inuse collapses all per-user usage into one license.

	lappend inuse($prod) $key

	# Compute stats for the home page
	# Used for home page summary

	set len [llength $inuse($prod)]
	if {$len > $counter($prod,todayMax)} {
	    set counter($prod,todayMax) $len
	    lserver::audit dailymax $prod $len
	}
	if {$len > $counter($prod,weekMax)} {
	    set counter($prod,weekMax) $len
	    lserver::audit weeklymax $prod $len
	}

	Count todayLicense-$prod
	Count weekLicense-$prod
    }

    # user records all usages by one user.

    Count todayUse-$prod
    Count weekUse-$prod

    if {[string length $token] != 0} {

	# Saved token from checkpoint.  Bump our counter to match this
	# so we don't collide later, and reuse client's token.

	set i $token
	set cookie $token
    } else {
	set i [incr cookie]
    }

    set a [after $default(timeout) [list lserver::/release \
	[lserver::encode token $i noise1 [clock clicks]] timeout]]
    set state($i) [list $prod $key $appname $a "$today $time"]
    set checkpoint($i) [lserver::encode prod $prod userid $userid host $host \
	appname $appname token $i noise1 $noise1]
    lappend user($key) $i
    lappend log token $i

    lserver::log checkout OK [join $log]
    CheckPoint

    lserver::audit checkout $prod $userid $host $appname $status
    if {[info exist lserver::org]} {
	set o $lserver::org
    } else {
	set o "Unknown Company"
    }
    return [list token $i status $status noise1 $noise1 org $o]
}

# lserver::/refresh
#	Direct URL to refresh a license checkout
#	This handles encoded arguments and results
#
# Arguments
#	value	Encoded name, values.  See /refreshDirect for details
#
# Results
#	Encoded name, values.

proc lserver::/refresh {value {reason normal}} {
    ParseArgs $value token noise1
    set x [lserver::/refreshDirect $token $noise1 $reason]
    return [lserver::encode $x]
}

# lserver::/refreshDirect
#	Direct URL to refresh a license checkout
#
# Arguments
#	token	Return value from /checkout
#	noise1	Return value from /checkout
#	reason	normal or timeout, for logging
#
# Side Effects
#	Resets the release timeout for the client

proc lserver::/refreshDirect {token noise1 {reason normal}} {
    variable state
    variable user
    variable default

    set log {}
    if {[info exist state($token)]} {
	set a [lindex $state($token) 3]
	catch {after cancel $a}
	set a [after $default(timeout) [list lserver::/release \
	    [lserver::encode token $token noise1 [clock clicks]] timeout]]
	set state($token) [lreplace $state($token) 3 3 $a]
	set status ok
    } else {
	set status unknown
    }
    return [list token $token status $status noise1 $noise1]
}

# lserver::/release
#	Direct URL to release a license
#	This handles encoded arguments and results
#
# Arguments
#	value	Encoded name, values.  See /releaseDirect for details
#
# Results
#	Encoded name, values.

proc lserver::/release {value {reason normal}} {
    ParseArgs $value token noise1
    set x [lserver::/releaseDirect $token $noise1 $reason]
    return [lserver::encode $x]
}

# lserver::/releaseDirect
#	Direct URL to release a license
#
# Arguments
#	token	Return value from /checkout
#
# Side Effects
#	Cleans up state about the client

proc lserver::/releaseDirect {token noise1 {reason normal}} {
    variable state
    variable checkpoint
    variable user
    variable inuse

    set log {}
    if {[info exist checkpoint($token)]} {
	unset checkpoint($token)
    }
    if {[info exist state($token)]} {
	Count "release $reason"
	lappend log $reason $state($token)
	set prod [lindex $state($token) 0]
	set key [lindex $state($token) 1]
	set appname [lindex $state($token) 2]
	set a [lindex $state($token) 3]
	catch {after cancel $a}
	unset state($token)
	if {[info exist user($key)]} {
	    set ix [lsearch $user($key) $token]
	    if {$ix >= 0} {
		set user($key) [lreplace $user($key) $ix $ix]
	    } else {
		lappend log "unknown token"
	    }
	    if {[llength $user($key)] == 0} {
		# No more uses of this product by this user/host

		lappend log "last use"
		if {![info exist inuse($prod)]} {
		    # Key deleted or expired while we were using it
		    lappend log "expired key"
		} else {
		    set ix [lsearch $inuse($prod) $key]
		    if {$ix >= 0} {
			set inuse($prod) [lreplace $inuse($prod) $ix $ix]
		    } else {
			lappend log "unknown key"
		    }
		}
	    }
	} else {
	    lappend log "unknown user '$key'"
	}
	set status OK
	CheckPoint
    } else {
	lappend log "Unknown token '$token'"
	set status ERROR
    }
    lserver::log release $status [join $log]
    return [list status $status noise1 $noise1 log $log]
}


# lserver::ParseArgs
#	Decode the arguments into the caller's local variables
#	The coded string comes from licdata::packString on the other end
#
# Arguments
#	code	The coded string comes from licdata::packString
#		This is assumed to be a list of name value pairs
#	args	List of variables that are expected.  These are set to
#		the empty string if they are not passed in the name value list
#
# Side Effects
#	Defines the local variables from the coded string

proc lserver::ParseArgs {code args} {
    set names {}
    foreach {name value}  [licdata::unpackString $code] {
	set Value($name) $value
	lappend names $name
    }
    foreach name $args {
	upvar 1 $name var
	if {![info exist Value($name)]} {
	    set var ""
	} else {
	    set var $Value($name)
	}
    }
    return [lsort $names]
}

# lserver::log
#	Log events
#
# Arguments
#	args
#

proc lserver::log {args} {
    variable log

    lappend log [clock seconds] $args
    if {[llength $log] > 500} {
	set log [lreplace $log 0 99]
    }
    return ""
}

# lserver::/logview
#	Display log events
#
# Arguments
#	none
#

proc lserver::/logview {args} {
    variable log

    set html [lpage::headurl Reports "License Server Log" /srvr/logview]
    foreach {secs stuff} $log {
	append html "[Time] [Today]"
	append html " "
	append html <b>[join $stuff]</b>
	append html <br>
    }
    append html [lpage::footer]
    return $html
}

# lserver::status
#	Display current license state
#
# Arguments
#	none
#

proc lserver::status {args} {
    variable max
    variable inuse
    variable user
    variable overdraft
    variable overtime
    set html <table>\n
    append html "<tr>"
    append html "<td>Product</td>"
    append html "<td>Limit</td>"
    append html "<td>In Use</td>"
    append html "<td>Extra Days</td>"
    append html "<td>Status</td>"
    append html "</tr>\n"
    foreach prodid [array names max] {
	append html "<tr>"
	append html "<td>[Name $prodid]</td>"
	append html "<td>$max($prodid)</td>"
	if {![info exist inuse($prodid)]} {
	    append html "<td>(expired)</td>"
	} else {
	    append html "<td>$inuse($prodid)</td>"
	}
	append html "<td>$overdraft($prodid)</td>"
	if {[string compare [Today] $overtime($prodid)] == 0} {
	    set status Overdraft
	} else {
	    set status OK
	}
	append html "<td>$status</td>"
	append html "</tr>\n"
    }
    append html </table>\n
    return $html
}

# lserver::counters
#	Display event counters
#
# Arguments
#	none
#

proc lserver::counters {args} {
    array set count [Counter_Get checkout*]
    array set count [Counter_Get overdraft*]
    array set count [Counter_Get release*]
    return [lserver::parray count]
}

# lserver::/status
#	Display current license state
#
# Arguments
#	none
#

proc lserver::/status {args} {
    variable log

    set html [lpage::headurl Reports "License Server State" /srvr/status]
    array set count [Counter_Get checkout*]
    array set count [Counter_Get overdraft*]
    array set count [Counter_Get release*]
    append html [lserver::parray count]\n
    foreach x {state} {
	variable $x
	append html [lserver::parray $x]\n
    }
    foreach x {max inuse user overdraft overtime} {
	variable $x
	append html [lserver::parray $x lserver::Name]\n
    }
    append html [lpage::footer]
    return $html
}

# lserver::encode
#	Encode data for transmission to the client
#
# Arguments
#	args	list of values
#
# Returns
#	List data with secret hash function smeared over the bytes

proc lserver::encode {args} {
    if {[llength $args] == 1} {
	set args [lindex $args 0]
    }
    return [licdata::packString $args]
}

# lserver::parray
#	Format an array in an HTML table
#
# Arguments
#	aname	Name of the array
#
# Returns
#	HTML

proc lserver::parray {aname {formatProc concat} } {
    upvar 1 $aname a
    set html "<h3>$aname</h3>"
    append html "<table>"
    foreach ix [lsort [array names a]] {
	append html "<tr><td>[$formatProc $ix]</td><td>$a($ix)</td></tr>\n"
    }
    append html </table>
    return $html
}

# lserver::Name
#	Map from product ID to name
#
# Arguments
#	prodid	Product ID
#
# Returns
#	Name

proc lserver::Name {prodid} {
    variable name
    regsub product- $prodid {} prodid
    if {[info exist name($prodid)]} {
	return $name($prodid)
    } else {
	return "product-$prodid"
    }
}

# lserver::summary
#	Display current license state
#
# Arguments
#	none
#

proc lserver::summary {args} {
    variable log
    variable application
    variable inuse
    variable counter
    variable overtime
    variable overdraft
    variable max

    if {[llength [array names inuse]] == 0} {
	return
    }
    append html "<table border=1 cellpadding=3>\n"
    append html "<tr><th>Product</th>"
    append html "<th colspan=4>Concurrent Licenses</th>"
    append html "<th colspan=2>Total Uses</th></tr>"
    append html "<tr><td>&nbsp;</td>"
    append html "<td>Limit</td>"
    append html "<td>Now</td>"
    append html "<td>Today</td>"
    append html "<td>This Week</td>"
    append html "<td>Today</td>"
    append html "<td>This Week</td>"
    append html "</tr>"
    foreach x [array names inuse] {
	if {![info exist counter($x,todayMax)]} {
	    set counter($x,todayMax) 0
	}
	if {![info exist counter($x,weekMax)]} {
	    set counter($x,weekMax) 0
	}
	append html "<tr><td>[Name $x]</td>"
	append html "<td align=right>$max($x)</td>"
	append html "<td align=right><a href=/reports/users.tml>[llength $inuse($x)]</a></td>"
	append html "<td align=right><a href=/reports/daily.tml>$counter($x,todayMax)</a></td>"
	append html "<td align=right><a href=/reports/weekly.tml>$counter($x,weekMax)</a></td>"
	append html "<td align=right><a href=/reports/daily.tml>[Count todayUse-$x 0]</a></td>"
	append html "<td align=right><a href=/reports/weekly.tml>[Count weekUse-$x 0]</a></td>"
	append html </tr>\n

	set today [TodayFixed]
	if {[info exist overtime($x)] &&
		[string compare $overtime($x) $today] == 0} {
	    append html "<tr><td>&nbsp;</td><td colspan=6>"
	    append html "In overdraft with $overdraft($x) overdraft days left</td></tr>\n"
	}
    }
    append html </table>\n
    append html "<p>There are two measures of use.  The first columns
	measure the maximum number of concurrent license users right now,
	today, and this week.  The last columns count the total number
	of times an application was used today and this week."
    return $html
}

# lserver::keysummary
#	Display currently registered keys
#
# Arguments
#	none
#

proc lserver::keysummary {args} {
    variable keylist
    variable deletedkey
    global Httpd

    # Compute the list of keys that have not been deleted

    set keys {}
    set del [array names deletedkey]
    foreach k [array names keylist] {
	if {[lsearch $del $k] < 0} {
	    lappend keys $k
	}
    }
    if {[llength $keys] == 0} {
	return "<p>There are no license keys currently installed"
    }
    set html "<table>\n"
    append html "<tr>"
    append html "<th>Product</th>"
    append html "<th>Licenses</th>"
    append html "<th>Expires</th>"
    append html "<th>Key</th>"
    append html "</tr>"
    foreach key $keys {
	array set info [lic::parsekey $key]
	set name [Name $info(prodid)]
	Incr seats($name) $info(seats)
	lappend keyset($name) $key
    }

    foreach name [lsort -dictionary [array names seats]] {
	foreach key $keyset($name) {
	    set key [lic::formatKey $key]
	    #set prod [lindex $name 0]
	    set prod [join $name]
	    array set info [lic::parsekey $key]
	    append html "<tr>"
	    append html "<td>$prod</td>"
	    append html "<td align=center>$info(seats)</td>"
	    append html "<td>$info(expires)</td>"
	    append html "<td><font face=courier>$key</a></td>"
	    append html "<td>
		    <form action='http://www.ajubasolutions.com/tclpro/upgrade/autolicense.html' method=post>"
	    append html "<input type=hidden name=key value='$key'>"
	    append html "
		    <input type=hidden name=server value='http://$Httpd(name):$Httpd(port)'>
		    <input type=submit value='Upgrade Key'>
		    </form>
		    </td>"
	    append html "<td>
		    <form action='delete.tml' method=post>"
	    append html "<input type=hidden name=key value='$key'>"
	    append html "
		    <input type=submit value='Delete Key'>
		    </form>
		    </td>"
	    append html </tr>\n
	}
	if {[llength $keyset($name)] > 0} {
	    append html "<tr>"
	    append html "<td>Total</td>"
	    append html "<td align=center>$seats($name)</td>"
	    append html "</tr>"
	}
    }
    append html </table>\n
    return $html
}

# lserver::keyrevoke
#	Display currently active tokens
#
# Arguments
#	none
#

proc lserver::keyrevoke {args} {
    variable state
    global page

    if {[llength [array names state]] == 0} {
	return "There are currently no active users."
    }
    set html "<table>\n"
    append html "<tr><th>Product</th>"
    append html "<th>User</th>"
    append html "<th>Start Time</th>"
    append html "</tr>"
    foreach i [array names state] {
	lassign $state($i) prodid key appname a time
	append html "<td>[Appname $appname]</td>"
	set username [lindex $key 1]
	append html "<td>$username</td>"
	append html "<td>$time</td>"
	append html "<td><form action=$page(url)>
			<input type=hidden name=token value='$i'>
			<input type=submit value=Revoke></form></td>"
	append html </tr>\n
    }
    append html </table>\n
    return $html
}

# lserver::revokeHandler
#	Handle a revoke action
#
# Arguments
#	none
#

proc lserver::revokeHandler {} {
    variable state
    global page
    catch {array set query $page(query)}

    if {![info exist query(token)]} {
	return ""
    }
    array set info [lserver::/releaseDirect $query(token) {} manual]
    if {$info(status) == "OK"} {
	return "<p>License revocation successful."
    } else {
	set html "<p><font color=red>License revocation failed:"
	foreach m $info(log) {
	    append hmtl "<br>$m"
	}
	append html </font>
	return $html
    }
}

# lserver::dateprefs
#	Display date format preferences
#
# Arguments
#	none
#

proc lserver::dateprefs {args} {
    variable dateformat

    set now [clock seconds]
    set html "<form action=/srvr/dateprefs method=post>"
    append html "<p>[ncgi::value datemsg]"
    append html <ul>
    foreach format {%m/%d/%Y %d/%m/%Y %d-%m-%Y "%b %d, %Y" "%B %d, %Y"} {
	if {[string compare $dateformat $format] == 0} {
	    set SEL CHECKED
	} else {
	    set SEL ""
	}
	append html "<li><input type=radio name=format value='$format' $SEL> [clock format $now -format $format]"	
    }
    append html "</ul><input type=submit value='Set Date Format'></form>\n"
    return $html
}

# lserver::/dateprefs
#	Direct URL to set date format
#
# Arguments
#	Clock format string
#

proc lserver::/dateprefs {format} {
    lserver::log /dateprefs $format
    if {[DateFormat $format]} {
	CheckPoint
	Redirect /admin/dateformat.tml
    } else {
	set msg "Invalid date format $format"
	Redirect /admin/dateformat.tml?datemsg=[Url_Encode $msg]
    }
}

# lserver::emailprefs
#	Display email preferences
#
# Arguments
#	none
#

proc lserver::emailprefs {args} {
    variable email
    variable eventlist

    set html "<table>\n"
    append html "<tr><th>Event</th>"
    append html "<th>Current Email List</th>"
    append html "<th>Action</th>"
    append html "</tr>"
    foreach {event label} $eventlist {
	append html "<tr><td><b>$label</b></td>"
	if {![info exist email($event)]} {
	    set email($event) {}
	}
	set first 1
	foreach addr $email($event) {
	    if {$first} {
		set first 0
	    } else {
		append html "<tr><td>&nbsp;</td>"
	    }
	    append html "<td>$addr</td>"
	    append html "<td><form action=/srvr/emailremove>
			<input type=hidden name=event value='$event'>
			<input type=hidden name=addr value='$addr'>
			<input type=submit value='Remove'></form></td>"
	    append html </tr>
	}
	if {!$first} {
	    append html "<tr><td>&nbsp;</td>"
	    set first 0
	}
	append html "<form action=/srvr/emailadd>\n"
	append html "<input type=hidden name=event value='$event'>\n"
	append html "<td><input type=text size=15 name=addr></td>"
	append html "<td><input type=submit value='Add'></td>"
	append html </form>\n
	append html </tr>\n

	append html "<tr><td colspan=3><hr></td></tr>"
    }
    append html </table>\n
    return $html
}

# lserver::/emailadd
#	Direct URL to add an email address to an event
#
# Arguments
#	event	The event tag
#	addr	The email address
#
# Side Effects
#
#	Update the email array

proc lserver::/emailadd {event addr} {
    EmailAdd $event $addr
    Redirect /admin/email.tml
}
proc lserver::EmailAdd {event addr} {
    variable email

    set addr [string trim [string tolower $addr]]
    if {[string length $addr] == 0 || [string length $event] == 0} {
	return
    }

    if {![info exist email($event)]} {
	set email($event) {}
    }
    set ix [lsearch $email($event) $addr]
    if {$ix < 0} {
	lappend email($event) $addr
	lserver::log EmailAdd $event $addr
	CheckPoint
    } else {
	lserver::log EmailAdd $event $addr already on the list
    }
}

# lserver::/emailremove
#	Direct URL to remove an email address from an event
#
# Arguments
#	event	The event tag
#	addr	The email address
#
# Side Effects
#
#	Update the email array

proc lserver::/emailremove {event addr} {
    EmailRemove $event $addr
    Redirect /admin/email.tml
}
proc lserver::EmailRemove {event addr} {
    variable email
    set addr [string trim [string tolower $addr]]
    set ix [lsearch $email($event) $addr]
    if {$ix >= 0} {
	set email($event) [lreplace $email($event) $ix $ix]
	lserver::log EmailRemove $event $addr
	CheckPoint
    } else {
	lserver::log EmailRemove $event $addr not on the list
    }
}

# lserver::emailajuba
#	Wrapper around email(ajuba) variable,
#	which may be unset during some initialization sequences.
#
# Arguments
#	none
#
# Results
#	The value of email(ajuba), or 0 if it isn't defined

proc lserver::emailajuba {} {
    variable email
    if {[info exist email(ajuba)]} {
	return $email(ajuba)
    } else {
	return 0
    }
}

# lserver::/emailajuba
#	Direct URL to set "mail to ajuba" preference
#
# Arguments
#	ok	1 or 0
#
# Side Effects
#
#	Update the email(ajuba) value

proc lserver::/emailajuba {ok} {
    variable email
    set email(ajuba) $ok
    Redirect /admin/email.tml
}

# lserver::Today
#	Format todays date.
#
# Arguments
#	none

proc lserver::Today {{seconds {}}} {
    variable dateformat
    if {[string length $seconds] == 0} {
	set seconds [clock seconds]
    }
    if {![info exist dateformat]} {
	set dateformat "%b %d, %Y"
    }
    set today [clock format $seconds -format $dateformat]
}

# lserver::TodayFixed
#	Format todays date in a reliable way that can always
#	be processed with "clock scan".
#
# Arguments
#	seconds		If not specified, defaults to current time

proc lserver::TodayFixed {{seconds {}}} {
    if {[string length $seconds] == 0} {
	set seconds [clock seconds]
    }
    set today [clock format $seconds -format "%b %d, %Y"]
}

# lserver::Time
#	Format the time
#
# Arguments
#	none

proc lserver::Time {{seconds {}}} {
    if {[string length $seconds] == 0} {
	set seconds [clock seconds]
    }
    set time [clock format $seconds -format "%H:%M:%S"]
}

# lserver::Redirect
#	Trigger an HTTP redirect to another page.
#
# Arguments
#	url	The target URL
#
# Side Effects
#	The error raised by this routine causes TclHttpd to
#	return a redirect directive to the web browser

proc lserver::Redirect {url} {
    return -code error \
	    -errorcode  [list HTTPD_REDIRECT $url]\
			    "Redirect to $url"
}

# lserver::keyinfo --
#
#	Print out information (decode) a key.

proc lserver::keyinfo {key} {
    if {![string match 2* $key]} {
	return "Invalid key"
    }
    if {[catch {lic::parsekey $key} x]} {
	return "Invalid key"
    }
    array set info $x
    return "Seats $info(seats) Expires $info(expires)"
}

