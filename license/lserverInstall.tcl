# lserverInstall.tcl
#
# Core API to do
# OS-specific installation of the license server
#
# Copyright (c) 1998-2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: lserverInstall.tcl,v 1.3 2000/08/02 05:02:19 welch Exp $

package provide linstall 1.0

namespace eval linstall {

    variable myname prolserver		;# Name of the application

    # This template must be inside the wrapped application
    # This is dependent on the wrap command line in the
    # genImage.tcl installer creator.

    variable template lserver/src/tclhttpd.etc.init

    namespace export bootScripts configFile

}

# linstall::bootScripts
#	Install the /etc/init.d boot scripts.
#	The exact location is os-specific, but each platform foloows
#	the same general strategy.  A general start/stop script is
#	put into /etc/init.d, and symlinks are made to this script
#	that either start or stop the service as the system enters
#	different "run levels".
#	
#	A copy is placed elsewhere in case the user
#	cannot write to /etc.
#
# Arguments
#	installDir	The name of the general installation directory

proc linstall::bootScripts {installDir} {
    global Config
    variable myname
    variable template
    global tcl_platform

    set result "Installed boot script in "
    switch -- $tcl_platform(os) {
	SunOS {
	    append result "/etc/init.d/$myname"
	    set shell /sbin/sh
	    set dir /etc/init.d
	    set Sdir /etc/rc2.d
	    set Kdir {/etc/rc0.d /etc/rc1.d}
	}
	Linux {
	    # There are two flavors of boot scripts.
	    # In SuSE there are both S* and K* links in the
	    # same directory.  In this configuration the 0 runlevel
	    # just has a S*halt script and nothing else.
	    # In RedHat there are S* links in some runlevels,
	    # and K* links in the others.

	    set shell /bin/sh
	    set dir /etc/rc.d/init.d
	    append result "$dir/$myname"
	    if {[llength [glob -nocomplain /etc/rc.d/rc0.d/K*]] == 0} {
		# SuSE style
		set Sdir {/etc/rc.d/rc3.d}
		set Kdir {/etc/rc.d/rc3.d}
	    } else {
		# RedHat style
		set Sdir {/etc/rc.d/rc3.d /etc/rc.d/rc4.d /etc/rc.d/rc5.d}
		set Kdir {/etc/rc.d/rc0.d /etc/rc.d/rc1.d /etc/rc.d/rc2.d /etc/rc.d/rc6.d}
	    }
	}
	IRIX {
	    append result "/etc/init.d/$myname"
	    set shell /sbin/sh
	    set dir /etc/init.d
	    set Sdir /etc/rc2.d
	    set Kdir {/etc/rc0.d /etc/rc1.d}
	}
	HP-UX {
	    append result "/sbin/init.d/$myname"
	    set shell /sbin/sh
	    set dir /sbin/init.d
	    set Sdir /sbin/rc2.d
	    set Kdir {/sbin/rc0.d /sbin/rc1.d}
	}
	default {
	    set result "Unknown OS - Cannot create boot script"

	    # fall through with no "dir" variable so first open fails
	}
    }

    # Re-write the /etc startup script to contain startup parameters

    set prog [file join $installDir $myname]
    set dolink 1

    if {[info exist dir]} {
	set path [file join $dir $myname]
    }
    if {[catch {open $path w} out]} {
	if {[User] != "root"} {
	    set result "Warning: Not running as root: cannot create boot script"
	} else {
	    set result "Warning: cannot create boot script"
	}
	if {[info exist path]} {
	    append result " $path"
	}
	set path [file join $installDir $myname.boot]
	set dolink 0
	if {[catch {open $path w} out]} {
	    return $result
	} else  {
	    append result "\nCreated reference boot script in $path"
	}
    }

    # out is either boot or reference script

    if {[catch {
	set in [open $template]
	while {[gets $in line] >= 0} {
	    switch -exact -- $line {
		SHELL {
		    puts $out "#!$shell"
		}
		CONFIG {
		    puts $out "name=$myname"
		    puts $out "homeDir=$installDir"
		}
		default {
		    puts $out $line
		}
	    }
	}
	close $in
	close $out
	file attributes $path -permissions 0755
	if {$dolink} {
	    append result "\nSymlinks for kernel runlevels:"
	    foreach d $Sdir {
		set file [file join $d S90$myname]
		file delete -force $file
		DoCmd exec ln -s $path $file
		append result "\n\tln -s $path $file"
	    }
	    foreach d $Kdir {
		set file [file join $d K20$myname]
		file delete -force $file
		DoCmd exec ln -s $path $file
		append result "\n\tln -s $path $file"
	    }
	}
    } err]} {
	append result "\nWarning, error while creating $path\n$err"
    }
    append result \n
    return $result
}

# linstall::configFile
#	Create initial versions of the configuration and log files.
#
# Arguments
#	installDir	The install directory.  Default should be /etc.
#	logDir		The log directory.  Default should be /var/log
#	port		The HTTP listening port
#	user		User name of account that will own lserver files
#	group		Group name of account that will own lserver files
#
# Results:
#	Information about the install.

proc linstall::configFile {installDir logDir port user group} {
    variable myname

    set path [file join $installDir $myname.conf]
    if {[file exists $path]} {
	if {[catch {
	    set out [open $path.new w]
	    set in [open $path]
	    while {[gets $in line] >= 0} {
		switch -glob -- $line {
		    "Uid*" -
		    "Log*" -
		    "Gid*" -
		    "Port*" {
			# Skip old info
		    }
		    default {
			puts $out $line
		    }
		}
	    }
	    puts $out [list Uid $user]
	    puts $out [list Gid $group]
	    puts $out [list Port $port]
	    puts $out [list LogDir $logDir]
	    close $in
	    close $out
	    file rename -force $path $path.old
	    file rename -force $path.new $path
	    file attributes $path -permissions 0750 -owner $user -group $group
	    set result "Updated configuration file $path\n"
	} err]} {
	    set result "Warning: error while updating configuration file $path\n$err\n"
	}
    } else {
	if {[catch {
	    set out [open $path w]
	    puts $out "# Ajuba Solutions License Server Configuration \n\
		       # Uid	Effective User Name or ID of the process \n\
		       # Gid	Effective Group Name or ID of the process \n\
		       # Port	HTTP listening port of the process \n\
		       # LogDir	Directory for log file \n\
		       # License	TclPro license keys \n"
	    puts $out [list Uid $user]
	    puts $out [list Gid $group]
	    puts $out [list Port $port]
	    puts $out [list LogDir $logDir]
	    close $out
	    file attributes $path -permissions 0750 -owner $user -group $group
	    append result "Installed configuration file $path\n"
	} err]} {
	    append result "Warning: error while installing configuration file $path\n$err\n"
	}
    }

    append result \n

    set path [file join $installDir $myname.state]
    if {[catch {
	if {![file exist $path]} {
	    close [open $path w]
	    append result "Created state file $path\n"
	}
	file attributes $path -permissions 0750 -owner $user -group $group
    } err]} {
	append result "Warning: error while creating state file $path\n$err\n"
    }

    append result \n

    set path [file join $logDir $myname.$port.log]
    if {[catch {
	if {![file exist $path]} {
	    close [open $path w]
	    append result "Created log file $path\n"
	}
	file attributes $path -permissions 0750 -owner $user -group $group
    } err]} {
	append result "Warning: error while creating log file $path\n$err\n"
    }

    return $result
}

# linstall::DoCmd
#	Execute a command and echo it through the logging command.
#	This catches errors.
#
# Arguments
#	args	The command to execute
#
# Results
#	Echo the command and append any errors.

proc linstall::DoCmd {args} {
    regsub {^exec } $args {} result
    if {[catch $args err]} {
	append result "Error: $err"
    }
    return $result
}

# linstall::User
#	Return the user name.
#
# Arguments
#	none
#
# Results
#	The user name

proc linstall::User {} {
    global env
    if {[info exist env(USER)]} {
	return $env(USER)
    }
    if {[info exist env(LOGNAME)]} {
	return $env(LOGNAME)
    }
    return "(unknown user)"
}


