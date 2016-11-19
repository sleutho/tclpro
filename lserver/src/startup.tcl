#!/bin/sh
#
# startup.tcl
#	Startup for Ajuba Solutions License Server.
#	This is based on the TclHttpd "httpd" 
#
# Copyright (c) 1999-2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# \
exec tclsh8.0 "$0" ${1+"$@"}

# Wire in the location of the Httpd script library.
# In an unwrapped application, it comes from the workspaces.
# Config(libtml) is where the application-specific Tcl scripts are
# Config(docRoot) is where the web files are
# Config(file) is where the configuration file is
 
 
if {[catch {package require tbcload}] == 1} {
    set ::hasLoader 0
} else {
    set ::hasLoader 1
}
 
if {[info exist tcl_platform(isWrapped)] && $tcl_platform(isWrapped)} {
    set Config(docRoot) htdocs
    set Config(libtml) ""	;# root of wrapped files
} else {
    set Config(cvs) /home/welch/cvs
    set Config(docRoot) $Config(cvs)/pro1.4/lserver/htdocs
    set Config(libtml) $Config(cvs)/pro1.4/lserver/src
}
package require projectInfo

# Pick a good default for the location of the configuration file

set Config(name) prolserver
set path [file join [file dirname [info nameofexecutable]] $Config(name).conf]
if {[file exist $path]} {
    set dir [file dirname [info nameofexecutable]]
} else {
    set dir /etc
}
cd $dir

# Define the command line option processing procedure
# The options are mapped into elements of the Config array

package require cmdline

set optlist [list \
        [list port.arg.secret         2577		{Port number server is to listen on}] \
        [list host.arg.secret         [info hostname]	{Server name, should be fully qualified}] \
        [list ipaddr.arg.secret       {}		{Interface server should bind to}] \
        [list webmaster.arg.secret    webmaster@[info hostname]	{E-mail address for errors}] \
        [list uid.arg.secret          nobody		{User Id that server ans scripts are to run under}] \
        [list gid.arg.secret          daemon		{Group Id for caching templates}] \
        [list logDir.arg.secret       /var/log		{Location of License log file directory}] \
        [list httpLogDir.arg.secret       nologging	{Location of Httpd log file directory}] \
        [list homeDir.arg      $dir		{Configuration/install directory}] \
        [list install.secret      	{Prompt for configuration and install}] \
        [list batchInstall.secret      {Install based on command line options}] \
        [list reset      	{Reset administrator state}] \
        [list verbose      	{Echo startup status to standard output}] \
    ]

if {[catch {cmdline::getoptions argv $optlist} x]} {
    puts stderr $x
    exit 1
} else {
    array set Config $x
}
set verbose $Config(verbose)

lappend auto_path $Config(libtml)

package require lserver
package require lpage

# Core modules
package require httpd 1.3       ;# Protocol stack
package require httpd::version	;# Httpd_Version
package require httpd::url	;# URL dispatching
package require httpd::counter  ;# Statistics
package require httpd::mtype    ;# Mime content types
package require httpd::utils    ;# junk
package require httpd::redirect	;# URL redirection
package require httpd::auth     ;# Basic authentication
package require httpd::log      ;# Standard logging

# Standard Library dependencies
package require ncgi
package require html
package require base64

# This automatically uses Tk for image maps and
# a simple control panel.  If you have a Tcl-only shell,
# then image maps hits are done differently and you
# don't get a control panel.
# You may need to tweak
# this if your Tcl shell can dynamically load Tk
# because tk_version won't be defined, but it could be.

if {[info exists tk_version]} {
    # Use a Tk canvas for imagemap hit detection
    package require httpd::ismaptk
    # Display Tk control panel
    package require httpd::srvui
} else {
    # Do imagemap hit detection in pure Tcl code
    package require httpd::ismaptcl
}

# Stub out Thread_Respond so threadmgr isn't required

proc Thread_Respond {args} {return 0}
proc Thread_Enabled {} {return 0}

# This initializes some state, including Httpd(library),
# but doesn't start the server yet.
# Do this before loading the configuraiton file.

Httpd_Init
Mtype_ReadTypes 		[file join $Httpd(library) mime.types]

####

# These packages are required for "normal" web servers

package require httpd::doc		;# Basic file URLS
package require httpd::cgi		;# Standard CGI
package require httpd::dirlist		;# Directory listings

# These packages are for special things built right into the server

package require httpd::direct		;# Application Direct URLs
package require httpd::status		;# Built in status counters
package require httpd::mail		;# Crude email support
package require httpd::direct		;# Application Direct URLs
package require httpd::status		;# Built in status counters
package require httpd::debug		;# Debug utilites

if {[catch {
    lserver::init /srvr $Config(homeDir) $Config(reset)
    source [file join $Config(docRoot) .tml]
} err]} {
    if {$Config(install) || $Config(batchInstall)} {
	# Error is OK, fall through to install path
    } else {
	puts $auto_path
	puts "Licence Server Initialization Error\n$errorInfo"
	exit 1
    }
}

# For information about these calls, see htdocs/reference.html

Doc_Root		$Config(docRoot)
Doc_IndexFile		index.tml
Status_Url		/status
Debug_Url		/debug
#Mail_Url		/mail
#Admin_Url		/admin
Doc_TemplateInterp	{}
Doc_CheckTemplates	1
Doc_TemplateLibrary	$Config(libtml)
Doc_ErrorPage		/error.html
Doc_NotFoundPage	/notfound.html
Doc_Webmaster		$Config(webmaster)

if {[string compare $Config(httpLogDir) "nologging"] != 0} {
    Log_SetFile		[file join $Config(httpLogDir) log$Config(port)_]
    Log_FlushMinutes	0
}

####

# Self installation

if {$Config(install) || $Config(batchInstall)} {
    lappend auto_path $Config(libtml)
    if {[catch {
	package require linstall
	lserver::install Config
    } err]} {
	puts stderr $auto_path
	parray auto_index 
	puts stderr $errorInfo
	exit 1
    }
}

# Finally, start the server

if {[catch {
    Httpd_Server $Config(port) $Config(host) $Config(ipaddr)
} err]} {
    Stderr "Cannot start HTTP service on port $Config(port): $err"
    exit 1
}

if {![catch {open [file join $Config(homeDir) $Config(name).pid] w} out]} {
    puts $out [pid]
    close $out
} else {
    lserver::log pidfile cannot create $out
}

Log_Flush

# Try to change UID/GID to downgrade away from root

set code [catch {

    # Load Tclx from the statically wrapped shell.
    load {} Tclx

    if {[regexp {^[0-9]+$} $Config(gid)]} {
	id groupid $Config(gid)
    } else {
	id group $Config(gid)	;# Try string group name
    }
    if {[regexp {^[0-9]+$} $Config(uid)]} {
	id userid $Config(uid)
    } else {
	id user $Config(uid)	;# Try string user name
    }
} err]
if {$code == 0} {
    lserver::log setuid user $Config(uid) group $Config(gid)
    if {$verbose} {
	Stderr "Running as user $Config(uid) group $Config(gid)"
    }
} else {
    lserver::log setuid failed $err
    if {$verbose} {
	Stderr "Cannot change user/group id: $err"
    }
}

# Start up the user interface and event loop.

if {[info exists tk_version]} {
    SrvUI_Init "Tcl HTTPD $Httpd(version)"
}
if {1} {
    Stderr "Ajuba Solutions License Server started on port $Config(port)"
}
vwait forever
