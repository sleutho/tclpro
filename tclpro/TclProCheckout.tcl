#
# Tcl Pro checkout script
#
#
set compression "-z3"
set anonuser "anonymous@cvs.tclpro.sourceforge.net"
set logfile "TclProCheckout.log"
set no_dups 0	;# No repeat checkouts
set no_action 0	;# Just echo commands - don't  do anything

#
# log - log a message to a file and to standard output
#
proc log {message} {
    global logfp logfile

    if {![info exists logfp]} {
	set logfp [open $logfile a]
    }
    puts stdout $message
    puts $logfp "[clock format [clock seconds] -format {%Y/%m/%m %T}] $message"
    flush $logfp
}

#
# tryexec - exec a command.  catch nonzero exits and return 1 on success, 0 on
# failure, logging the results.
#
proc tryexec-orig {args} {
    log "executing $args"
    if {[catch {eval exec $args} result] == 1} {
	if {[string match *Updating* $result]} {
	    # Probably OK
	    log "$result"
	} else {
	    log "exec error: $result"
	    return 0
	}
    }
    return 1
}

proc tryexec {args} {
    global no_action
    if {$no_action} {
	log $args
	return 1
    }
    log "executing $args"
    set fp [open "| $args " r]
    set ok 0
    while {[gets $fp line] >= 0} {
	log ">> $line"
	if {[string match *U* $line]} {
	    set ok 1
	}
    }
    if {[catch {close $fp} result] == 1} {
	if {[string match *Updating* $result]} {
	    # Probably OK
	    log "$result"
	    set ok 1
	} else {
	    if {!$ok} {
		log "exec error: $result"
	    }
	    return $ok
	}
    }
    return 1
}

#
# _checkout - checkout a module from a package
#	This takes everything explicitly, and is shared
#	by the anonymous and regular checkout procedures.
#
proc _checkout {user package module directory tag} {
    global compression

    set logmsg "$user checking out package '$package', module '$module'"

    set cmd [list tryexec cvs $compression -d${user}:/cvsroot/$package co]
    if {$directory != ""} {
	lappend cmd -d $directory
	append logmsg " directory $directory"
    }
    if {$tag != ""} {
	lappend cmd -r $tag
	append logmsg " tag $tag"
    }
    lappend cmd $module
    log $logmsg

    return [eval $cmd]
}

#
# anoncvscheckout - checkout a module from a package, anonymously
#
proc anoncvscheckout {package module {directory ""} {tag ""}} {
    global anonuser 

    _checkout :pserver:${anonuser} $package $module $directory $tag
}

#
# cvscheckout - checkout a module from a package as you -- you must have
# read/write access or this will fail
#
proc cvscheckout {package module {directory ""} {tag ""}} {
    global user

    _checkout $user $package $module $directory $tag
}

# checkout - checkout all specified modules of a given package.
# If modules aren't specified, there is one module, the same as the package.

proc checkout {package {modules ""} {directory ""} {tag ""}} {
    global anonuser no_dups

    if {$modules == ""} {
	set modules $package
    }

    set failed 0
    foreach module $modules {
	# If we simply reset directory to be modules at this point,
	# there will be a redundant -d added to the cvs cmd ...
	if {$directory == ""} {
	    set dir $module
	} else {
	    set dir $directory
	}
	if {$no_dups && [file isdirectory $dir]} {
	    log "*** package '$package', module '$module' already checked out"
	} else {
	    if {!$failed &&
		[cvscheckout $package $module $directory $tag] && [file isdirectory $dir]} {
		log "*** package '$package', module '$module' checked out read/write"
	    } else {
		if {!$failed} {
		    log "checkout failed, attempting anonymous checkout"
		    tryexec cvs -d:pserver:${anonuser}:/cvsroot/$package login
		    set failed 1
		}
		if {[anoncvscheckout $package $module $directory $tag]} {
		    log "*** package '$package', module '$module' checked out read only"
		} else {
		    log "*** package '$package', module '$module' anonymous checkout also failed"
		}
	    }
	}
    }
}

# Make sure the config module is included everywhere
# This is done forcibly because modules like itcl and tclwrapper
# can end up with old or empty config directories.

proc spread_config {} {
    foreach dir [glob *] {
	if {[file isdirectory $dir]} {
	    if {![file exists $dir/config]} {
		log "linking ../config to $dir/config"
		tryexec ln -s ../config $dir/config
	    } elseif {[file type $dir/config] != "link"} {
		log "Nuking non-link $dir/config"
		file delete -force $dir/config
		log "linking ../config to $dir/config"
		tryexec ln -s ../config $dir/config
	    }
	}
    }
}

# mclistbox isn't anywhere yet

#
# checkoutall - checkout all the modules
#
proc checkoutall {} {
    global argv0

    log "Starting $argv0"

    checkout tclpro {buildenv buildutil config infozip license 
			     lserver proshells tbcload tclchecker 
			     tclcompiler tcldebugger tclparser tclpro 
			     tclwrapper winutil}

    foreach package {tclhttpd tcllib } {
	checkout $package
    }

    # The installer-builder expects to find source directories
    # under specific versions.

    checkout tcl tcl tcl8.3.2 core-8-3-2
    checkout tktoolkit tk tk8.3.2 core-8-3-2
    checkout incrtcl incrTcl itcl3.2 itcl-3-2-0
    checkout tclx tclx tclx8.3 TCLX_8_3_0
    checkout expect expect expect5.32 expect-5-32-2

    spread_config
}

# Update stuff, once its all been checked out.
proc cvsupdate {} {
    global argv0

    log "Starting $argv0 Update"

    set pwd [pwd]
    foreach dir {buildenv buildutil config infozip license 
		 lserver proshells tbcload tclchecker 
		 tclcompiler tcldebugger tclparser tclpro 
		 tclwrapper winutil tclhttpd tcllib 
		 tcl8.3.2 tk8.3.2
		 tclx8.3 expect5.32 itcl3.2} {
	if {![file isdirectory $dir]} {
	    puts stderr "Skipping $dir - does not exist"
	} else {
	    log $dir
	    cd $dir
	    tryexec cvs update
	    cd $pwd	;# avoid .. because of symlinks 
	}
    }
}

set action checkoutall
set user welch
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
	-checkout {set action checkoutall}
	-update	  {set action cvsupdate}
	-no_dups  {set no_dups 1}
	-no_action  {set no_action 1}
	-user	{incr i ; set user [lindex $argv $i]}
    }
}
set user "$user@cvs.tclpro.sourceforge.net"

if {!$tcl_interactive} {
    $action
}
