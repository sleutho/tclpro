# License Server Installation
#
# This does OS-specific installation of the license server

package provide lserver 1.0
package require linstall

namespace eval lserver {

    variable myname prolserver

    namespace export install

}

# lserver::install
#	Install the License Server
#	This gets configuration parameters from:
#	the command line, passed in via the Config array
#	from terminal input
#	or from HTML forms.
#
# Arguments
#	Config	The command line configuration options

proc lserver::install {aname} {
    upvar 1 $aname Config
    global tcl_platform

    lserver::log install [array get Config]

    for {set try 0; set port $Config(port)} {$try < 100} {incr try; incr port} {
	if {![catch {
	    Httpd_Server $port $Config(host) $Config(ipaddr)
	} x]} {
	    puts "Started HTTP service on port $port"
	    # puts "You may connect to http://$Config(host):$port/install/"
	    # puts "to complete the installation process"
	    break
	}
    }
    if {$try == 100} {
	puts "Unable to start HTTP on ports $Config(port) through $port"
    } else {
	set Config(port) $port
    }
    set x {
	"HTTP port"	port
	"Host name"	host
	"Install directory"	homeDir
	"Log file directory"	logDir
    }
    if {"$tcl_platform(platform)" == "unix"} {
	lappend x \
	    "Server user ID" uid \
	    "Server group ID" gid
    }
    set max 0
    foreach {blurb var} $x {
	if {[string length $blurb] > $max} {
	    set max [string length $blurb]
	}
    }
    while {1} {
	puts "\nCurrent Ajuba Solutions License Server Configuration"
	foreach {blurb var} $x {
	    puts [format "%-*s %s" $max $blurb $Config($var)]
	}
	if {[info exists Config(batchInstall)]} {
	    set answer no
	} else {
	    Prompt "\nChange this configuration? (yes|no|cancel)"
	    GetAnswer answer yes
	}
	switch -- [string tolower [string trim $answer]] {
	    no {break}
	    web {
		# puts "You may connect to http://$Config(host):$port/install/"
		# puts "to complete the installation process"
		vwait ::lserver::installDone
		Quit
	    }
	    cancel {
		Quit
	    }
	    yes -
	    default {
		foreach {blurb var} $x {
		    Prompt "$blurb ($Config($var))"
		    GetAnswer Config($var) $Config($var)
		}
	    }
	}
    }
    if {[info exist Config(batchInstall)]} {
	set answer yes
    } else {
	Prompt "\nInstall? (yes|no)"
	GetAnswer answer yes
    }
    if {[string match y* [string tolower $answer]]} {
	lserver::DoInstall Config puts return
    }
    Quit
}

# lserver::/install
#	Install the License Server via URL
#	This gets configuration parameters from form data.
#
# Arguments
#	Config	The command line configuration options

proc lserver::/install {homeDir logDir port uid pid} {
    global tcl_platform
    set params {homeDir port} 
    if {$tcl_platform(platform) == "unix"} {
	lappend params uid gid
    }
    foreach x $params {
	if {[string length [set $x]] == 0} {
	    append errors "<p>Please supply $x"
	}
    }
    if {[info exists errors]} {
	set html "\
	    <title>Install Parameters Missing</title>\n\
	    <h1>Install Parameters Missing</h1>\n\
	    $errors
	    "
	return $html
    }
    array set Config [list homeDir $homeDir port $port \
	uid $uid gid $gud logDir $logDir]
    set html "\
	<title>Installation Log</title>\n\
	<h1>Installation Log</h1>\n"
    append html <pre>
    append html [lserver::DoInstall Config "append html" {return $html}]
    append html </pre>
    return $html
}

# lserver::DoInstall
#	Do the install based on previously gathered parameters.
#
# Arguments
#	aname	The name of the configuration array
#	logCmd	The logging command
#	doneCmd	A callback made when the installation is complete.

proc lserver::DoInstall {aname logCmd doneCmd} {
    global tcl_platform
    upvar 1 $aname Config
    variable myname


    eval $logCmd {"The following command launches Ajuba Solutions' License Server:"}
    eval $logCmd {"[file join $Config(homeDir) $myname] -homeDir $Config(homeDir)"} 

    eval $logCmd {[linstall::bootScripts $Config(homeDir)]}

    eval $logCmd {"Installing license server program"}
    linstall::DoCmd file copy -force [info nameofexecutable] [file join $Config(homeDir) $myname]

    eval $logCmd {[linstall::configFile $Config(homeDir) $Config(logDir) \
		$Config(port) $Config(uid) $Config(gid)]}

    eval $doneCmd
}

# lserver::Prompt
#	puts to stdout
#
# Arguments
#	string	What to puts

proc lserver::Prompt {string} {
    puts -nonewline "$string "
    flush stdout
}

# lserver::GetAnswer
#	Read an answer using event driven I/O
#
# Arguments
#	varName	Name of result variable
#	default	Default value if input is empty

proc lserver::GetAnswer {varName default} {
    upvar 1 $varName answer
    fileevent stdin readable ::lserver::ReadAnswer
    vwait ::lserver::answer
    set answer [string trim $lserver::answer]
    if {[string length $answer] == 0} {
	set answer $default
    }
}

# lserver::ReadAnswer
#	Read an answer using event driven I/O
#
# Side Effects
#	Read into lserver::answer

proc lserver::ReadAnswer {} {
    if {[eof stdin]} {
	Quit
    }
    gets stdin ::lserver::answer
}

# lserver::Quit
#	Halt the server process
#
# Arguments
#	none

proc lserver::Quit {} {
    exit 1
}
