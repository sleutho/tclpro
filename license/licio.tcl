# licio.tcl --
#
#	This file contains soem I/O routines to read and write key and
#	server information.  Supports Windows registry as well as UNIX
#	file-based stores for this information.  The procedures in this
#	file are part of the "lic::" namespace that is officially defined
#	in "srcs/util/licparse.tcl".
#
#	These procedures are put aside so that the UNIX installers can
#	use these routines to access the license information files in
#	the same way "prolicense" and "prolicensetty" access these
#	routines.
#
# Copyright (c) 1998-2000 by Ajuba Solutions.
# All rights reserved.
# 
# RCS: @(#) $Id: licio.tcl,v 1.3 2000/08/01 01:49:54 welch Exp $

package provide lic 1.1

namespace eval lic {
    namespace export *
}

# lic::Registry --
#
#	Wrapper around "registry" command to elminiate most procheck warnings.
#
# Arguments:
#	Those of the registry command
#
# Results:
#	Those of the registry command

proc lic::Registry {args} {
    eval registry $args
}

# lic::savePersonalKey --
#
#	Save a license key in the appropriate place.
#
# Arguments:
#	key	The human readable license key to be saved.
#
# Results:
#	None.

proc lic::savePersonalKey {key} {
    global tcl_platform

    switch -- $tcl_platform(platform) {
	windows {
	    Registry set $::licdata::fileName license $key
	}
	default {
	    SaveValueToFile $::licdata::fileName key $key
	}
    }
}

# lic::saveServerInfo --
#
#	Save the license server location.  This attempts to save it in
#	the shared file.  It also stores it locally for backup.
#
# Arguments:
#	host	Host of the server
#	port	Port of the server
#
# Results:
#	None.

proc lic::saveServerInfo {host port} {
    variable config
    if {[info exist config(-site)] && $config(-site)} {
	lic::saveServerGlobal $host $port \
		[file dirname [file dirname \
			[file dirname [info nameofexecutable]]]] 
    } else {
	lic::saveServerLocal $host $port
    }
}

# lic::saveServerLocal --
#
#	Save the license server location in a per-user place
#
# Arguments:
#	host	Host of the server
#	port	Port of the server
#
# Results:
#	None.

proc lic::saveServerLocal {host port} {
    global tcl_platform

    switch -- $tcl_platform(platform) {
	windows {
	    Registry set $::licdata::fileName lmgr [list $host $port]
	}
	default {
	    SaveValueToFile $::licdata::fileName lmgr [list $host $port]
	}
    }
}

# lic::saveServerGlobal --
#
#	Save the license server location in a per-installation place
#
# Arguments:
#	host	Host of the server
#	port	Port of the server
#
# Results:
#	None.

proc lic::saveServerGlobal {host port dir} {
    set path [file join $dir .license]
    SaveValueToFile $path lmgr [list $host $port]
}

# lic::getServerInfo --
#
#	Return the location (host/port) of the license server.
#
# Arguments:
#	None
#
# Results:
#	Empty string, or a list of $host $port

proc lic::getServerInfo {} {
    
    # Try the local file first, then fall back to global info
    # If the binary is
    #	mumble/TclPro/solaris-sparc/bin/appname
    # Then the shared location is
    #  mumble/TclPro/.license

    if {[catch {getKeyServerLocal} info]} {
	return [getKeyServerSite]
    }
    return $info
}

# lic::saveCompanyName --
#
#	Save the company name.  This attempts to save it in
#	the shared file.  It also stores it locally for backup.
#
# Arguments:
#	company		a non-empty string
#
# Results:
#	None.

proc lic::saveCompanyName {company} {
    global tcl_platform

    switch -- $tcl_platform(platform) {
	windows {
	    Registry set $::licdata::fileName company $company
	}
	default {
	    SaveValueToFile $::licdata::fileName company $company
	}
    }
}

# lic::GetCompany --
#
#	Retrieve the company name from platform-specific storage.
#
# Arguments:
#	None.
#
# Results:
#	The company name (or an empty string if one was never entered).

proc lic::GetCompany {{unregisteredName {}}} {
    global tcl_platform

    if {[catch {
	if {$tcl_platform(platform) == "windows"} {
	    set company [Registry get $licdata::fileName company]
	} else {
	    set company [GetValueFromFile $licdata::fileName company]
	}
    } error]} {
	set company $unregisteredName
    }
    return $company
}

# lic::GetKey --
#
#	Retrieve the license key from platform-specific storage.
#
# Arguments:
#	licFilename     The license filename holding our key
#
# Results:
#	The human readable license key.

proc lic::GetKey {{licFilename {}}} {
    global tcl_platform

    if {[string length $licFilename] == 0} {
	set licFilename $licdata::fileName
    }

    set key {}

    catch {
	if {$tcl_platform(platform) == "windows"} {
	    set key [Registry get $licFilename license]
	} else {
	    set key [GetValueFromFile $licFilename key]
	}
    }
    return $key
}

# lic::getKeyServerSite --
#
#	Return the location (host/port) of the license server from
#	the site file for the TclPro installation (if it exists).
#
# Arguments:
#	None
#
# Results:
#	Empty string, or a list of $host $port

proc lic::getKeyServerSite {} {
    
    set path [file join [file dirname [file dirname [file dirname \
	    [info nameofexecutable]]]] .license]	
    if {[catch {GetValueFromFile $path lmgr} info]} {
	# No information about the license manager
	return {}
    }
    return $info
}

# lic::getKeyServerLocal --
#
#	Retrieve the license server location from platform-specific storage.
#
# Arguments:
#	None.
#
# Results:
#	A list of host and port for the server

proc lic::getKeyServerLocal {} {
    global tcl_platform

    if {[catch {
	if {$tcl_platform(platform) == "windows"} {
	    set info [Registry get $licdata::fileName lmgr]
	} else {
	    set info [GetValueFromFile $licdata::fileName lmgr]
	}
    }]} {
	error "noServer"
    }
    if {[string length [join $info ""]] == 0} {
	error "noServer"
    }
    return $info
}

# lic::GetValueFromFile --
#
#	Read a "set" command out of a file.
#
# Arguments:
#	file	The name of the file
#	varname	The name of the variable to find in the file
#
# Results:
#	Returns the value from the file, if present
#	Otherwise it raises an error.

proc lic::GetValueFromFile {file varName} {
    # Read the file, which should define the local variable $varName
    # Do not use "source" to prevent attacks

    set in [open $file]
    while {[gets $in line] >= 0} {
	set line [string trim $line]

	# The following regexps match lines of the following form:
	#	set var {value}
	#	set var "value"
	#	set var value

	if  {     ([regexp {set[ ]+([^ ]+)[ ]+\{(.*)\}$} $line x var value]
		|| [regexp {set[ ]+([^ ]+)[ ]+\"(.*)\"$} $line x var value]
		|| [regexp {set[ ]+([^ ]+)[ ]+(.*)$}     $line x var value])
		&& [info exist var]
		&& [info exist value]
		&& ($var == $varName)} {
	    break
	}
	catch {unset var}
	catch {unset value}
    }
    close $in
    if {![info exist value]} {
	error "missing value $varName"
    }
    return $value
}

# lic::SaveValueToFile --
#
#	Add a "set" command of a file.
#
# Arguments:
#	file	The name of the file
#	varname	The name of the variable to define in the file
#	value	The value for the variable
#
# Results:
#	None
#	Raises an error if it cannot write the file

proc lic::SaveValueToFile {file varName newValue} {
    file mkdir [file dirname $file]

    set how Created

    if {![catch {open $file} in]} {
	# Read out any other values we need to preserve
	# into the "save" array

	while {[gets $in line] >= 0} {
	    set line [string trim $line]

	    # The following regexps match lines of the following form:
	    #	set var {value}
	    #	set var "value"
	    #	set var value

	    if  {     ([regexp {set[ ]+([^ ]+)[ ]+\{(.*)\}$} $line x var value]
		    || [regexp {set[ ]+([^ ]+)[ ]+\"(.*)\"$} $line x var value]
		    || [regexp {set[ ]+([^ ]+)[ ]+(.*)$}     $line x var value])
		    && [info exist var]
		    && [info exist value]} {
	        set save($var) $value
	    }
	    catch {unset var}
	    catch {unset value}
	}
	close $in
	set how Modified
    }

    # Update the new value to store

    set save($varName) $newValue

    # Write everything to the file

    set out [open $file w]
    puts $out "# Ajuba Solutions key file"
    puts $out "# $how [clock format [clock seconds]]"
    foreach {var value} [array get save] {
	puts $out "set $var \{$value\}"
    }
    close $out

    return
}

# lic::promoteLicense --
#
#	Copy an older license key forward if one doesn't currently
#	exist.  Does nothing if a license for the current version
#	is installed.
#
# Arguments:
#	none
#
# Results:
#	Might create a new license file for the current version.

proc lic::promoteLicense {} {
    # We only want to promote a License if we don't currently have one.


    if {[lic::FileExists $licdata::fileName]} {
	return
    }

    set curPrefsLocation \
	    [projectInfo::getPreviousPrefslocation $projectInfo::prefsLocation]

    # bestKey(duration) can have several values:
    # 0 == invalid or expired key
    # -1 == never key
    # positive value == time left on temporary key.   For now this
    # is set to 1 and we just accept the first temporary key found.

    set bestKey(licFilename) {}
    set bestKey(duration) 0

    while {[string length $curPrefsLocation] != 0} {
	set licFilename [licdata::generateLicenseFilename $curPrefsLocation]
	if {[lic::FileExists $licFilename]} {

	    copyLicenseFile $licFilename

	    # Get a key and determine how long the key will last

	    set status [lic::getMsg text {} srvMsg blah regMsg]

            # Possible status values:  errorNoKey, errorInvalid,
            # warnTempKey, ok

            if {$status == "ok"} {
                # As soon as we find a never key, we don't need to
                # search any more.

		set bestKey(licFilename) $licFilename
		set bestKey(duration) -1
		break
            } elseif {$status == "warnTempKey"} {
                # Remember only the first temp key found, but keep searching
                # for a never key.

		if {$bestKey(duration) == 0} {
		    set bestKey(licFilename) $licFilename
		    set bestKey(duration) 1
		}
            } else {
		# Invalid key found.  Do nothing.
            }
	}

	# Cleanup

	removeLicenseFile $licdata::fileName

	set curPrefsLocation \
		[projectInfo::getPreviousPrefslocation $curPrefsLocation]
    }

    if {[string length $bestKey(licFilename)] != 0} {
	copyLicenseFile $bestKey(licFilename)
    }
}

# lic::FileExists --
#
#	Locate the license file in a system specific manner.
#
# Arguments:
#	file	The file or registry key.
#
# Results:
#	Return a boolean, 1 if the file exists.

proc lic::FileExists {file} {
    global tcl_platform

    if {$tcl_platform(platform) == "windows"} {
	set result [expr ![catch {Registry keys $file}]]
    } else {
	set result [file exists $file]
    }
    return $result
}

# lic::copyLicenseFile --
#
#	Copy an existing license file to replace/act as the current
#	license file.  This is usually done when promoting an older
#	license.
#
# Arguments:
#	srcLicFilename	The location of the other license file to install
#
# Results:
#	Might create a new license file for the current version.
#       Returns without doing anything if the source license file
#       could not be found.

proc lic::copyLicenseFile {srcLicFilename} {
    if {![FileExists $srcLicFilename]} {
        return
    }

    set oldLicFilename $licdata::fileName
    set licdata::fileName $srcLicFilename

    set key [GetKey]
    set company [GetCompany]
    set serverInfo [getServerInfo]

    set licdata::fileName $oldLicFilename

    savePersonalKey $key
    saveCompanyName $company
    if {[llength $serverInfo] == 2} {
	saveServerInfo [lindex $serverInfo 0] [lindex $serverInfo 1]
    }
}

# lic::removeLicenseFile --
#
#	Remove an existing licene file/registry entry
#
# Arguments:
#	licFilename	The location of the license file to delete
#
# Results:
#       A registry entry or file on disk could be deleted

proc lic::removeLicenseFile {licFilename} {
    global tcl_platform

    if {![file exists $licFilename]} {
        return
    }

    if {$tcl_platform(platform) == "windows"} {
	registry delete $licFilename
    } else {
	file delete -force $licFilename
    }
}

proc lic::Debug {args} {
    variable config
    if {[info exist config(-debug)] && $config(-debug)} {
	puts stderr [join $args]
    }
}

