# genhelp.tcl --
#
#	This script is used to generate the Windows helpfile from
#	the nroff manual pages.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: genhelp.tcl,v 1.4 2000/10/31 23:31:14 welch Exp $


# This file is insensitive to the directory from which it is invoked.

source [file join [file dir [info script]] ../projectInfo/projectInfo.tcl]
source [file join [file dir [info script]] ../util/util.tcl]

namespace eval genhelp {
    # stageDir --
    #
    # This variable points to the directory containing the source trees.

    variable stageDir

    # toolsDir --
    #
    # This variable points to the platform specific tools directory.

    variable toolsDir
}

# genhelp::init --
#
#	This is the main entry point.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc genhelp::init {} {
    variable toolsDir
    variable stageDir

    set saveDir [pwd]
    cd [file dir [info script]]
   
    if {[llength $::argv] != 2} {
	puts stderr "usage: $::argv0 <stageDir> <toolsDir>"
	exit 0
    }

    lassign $::argv stageDir toolsDir

    if {$::tcl_platform(platform) == "windows"} {
	set vcBinPath [file native [file join $toolsDir DevStudio/VC/bin]]
	set ::env(PATH) "$vcBinPath;$::env(PATH)"

	# Build the help file

	set newRoot [mapPath $stageDir]
	set outDir [file join $newRoot pro/out]
	cd $outDir
	catch {exec nmake helpfile >@stdout 2>@stdout}
	cd $saveDir

	if {[string compare $newRoot $stageDir] != 0} {
	    unmapPath $newRoot
	}
    } else {
	set tclToolsDir [file join $stageDir $projectInfo::localSrcDirs(tcl) tools]
	set binDir [file join $stageDir \
		pro/srcs/tcl/build/Release/solaris-sparc/dll]
	set outDir [file join $stageDir pro/out]
    
	cd $tclToolsDir
	exec autoconf
	cd $outDir
	exec [file join $tclToolsDir configure] \
		--with-tcl=$binDir 2>@stdout >@stdout
	exec make pro 2>@stdout >@stdout
    }
    return
}

# genhelp::getFreeDrive --
#
#	Find an unused drive letter.
#
# Arguments:
#	None.
#
# Results:
#	Returns the drive prefix to use (e.g.  "d:")

proc genhelp::getFreeDrive {} {
    set volumes [file volume]
    foreach drive {d e f g h i j k l m n o p q r s t u v w x y z 0} {
	if {[lsearch $volumes ${drive}:/] == -1} {
	    break
	}
    }
    if {![string compare $drive "0"]} {
	puts "Unable to find a free drive letter to map the build directory."
	exit 1
    }
    return ${drive}:
}

# genhelp::mapPath --
#
#	Maps an UNC path to a drive and returns the equivalent non-UNC path.
#
# Arguments:
#	path	The path to map.
#
# Results:
#	Returns the new path.

proc genhelp::mapPath {path} {
    set parts [file split $path]
    set root [lindex $parts 0]
    if {[string match //* $root]} {
	# This is a UNC path, so we need to map it to a drive because HCW is
	# lame and doesn't work on UNC paths.

	set drive [getFreeDrive]
	exec net use $drive [file nativename $root]
	set path [eval {file join ${drive}/} [lrange $parts 1 end]]
    }
    return $path
}
	
# genhelp::unmapPath --
#
#	Unmaps a drive.
#
# Arguments:
#	path	The path whose drive should be unmapped.
#
# Results:
#	None.

proc genhelp::unmapPath {path} {
    regexp {^.:} $path drive
    exec net use /delete $drive
}

genhelp::init
