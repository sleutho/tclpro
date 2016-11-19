#
# snapshot processor
#
# This reads the snapshot file and produes on stdout a list of each file
# in the output tree and what module provided it.
#
# Also it puts out which module made which package available.
#
# $Id: postpro.tcl,v 1.1 2001/03/30 16:35:06 andreas_kupries Exp $
#

# lassign - sigh
proc lassign {valueList args} {
  if {[llength $args] == 0} {
      error "wrong # args: lassign list varname ?varname..?"
  }

  uplevel [list foreach $args $valueList {break}]
  return [lrange $valueList [llength $args] end]
}


# merge_snapshot --
#
#	Read the SNAPSHOT file.  For each file recorded, figure out
#	and record which module or modules produced it.
#
# Arguments:
#	none
#
# Side Effects:
#	None
#
# Results:
#	For each package recorded, figure out which module made it available.
#
#	Write the results into the file pointed to by global "mergefp"
#
proc merge_snapshot {} {
    global mergefp

    set fp [open SNAPSHOT]
    while {[gets $fp line] >= 0} {
	lassign $line type module arg1 arg2

	if {$type == "package"} {
	    # arg1 is the package name
	    # arg2 is a list of package versions
	    process_package $module $arg1 $arg2
	    continue
	}

	if {$type != "file"} {
	    error "unknown type '$type' in SNAPSHOT file"
	}

	# if we got here, it's type 'file'

	# arg1 is time and arg2 is file
	set time $arg1
	set file $arg2

	# if this is the first time we've seen this file, record
	# the file mod time and module name for this file
	if {![info exists fileModules($file)]} {
	    set fileTimes($file) $time
	    set fileModules($file) $module
	    continue
	}

	# if the time didn't change, nothing happened
	if {$fileTimes($file) == $time} continue

	# record the new change time
	set fileTimes($file) $time

	# if we got here, we knew about it and the time changed,
	# so a second module has installed the same file

	# if we are tcl or tk, I don't care what the picture was,
	# I am a core holding and I provide this file.
	if {
	    ($module == "tcl") ||
	    ($module == "tk")  ||
	    [string match "tcl\[0-9\]*" $module] ||
	    [string match "tk\[0-9\]*"  $module]
	} {
	    set fileModules($file) $module
	    continue
	}

	# if this file already belongs to tcl or tk, it's a core holding
	# no need to say a different package also provides it
	if {
	    $fileModules($file) == "tcl" ||
	    $fileModules($file) == "tk"  ||
	    [string match "tcl\[0-9\]*" $fileModules($file)] ||
	    [string match "tk\[0-9\]*"  $fileModules($file)]
	} {
	    continue
	}

	# if the previous module was a static version of this one,
	# forget the static version, we only care about the main
	# version
	if {$fileModules($file) == "${module}_static"} {
	    set fileModules($file) ""
	}

	lappend fileModules($file) $module
    }

    foreach file [lsort [array names fileModules]] {
	puts $mergefp [list module_file $fileModules($file) $file]
    }
}

# process_package --
#
#	Record information to help figure out which modules provided
#	which packages.
#
# Arguments:
#	module		The name of the module.
#	packageName	The name of the package.
#	packageVersions	A list containing one or more versions provided.
#
# Side Effects:
#	None
#
# Results:
#	If we already knew about this package, does nothing.
#
#	If we didn't know about it, the module passed in is the
#	module that provided it, remember it.
#
proc process_package {module packageName packageVersions} {
    global packageModule

    # if package was found by a static build, it's in the nonstatic (main)
    # one for sure, switch our module name to that
    if {[string match *_static $module]} {
	set module [string range $module 0 end-7]
    }

    # for each version (usually only one) of the package provided
    foreach version $packageVersions {
	set name $packageName:$version

	# if we already knew about this package, the module this call
	# didn't put it here the first time, skip it
	if {[info exists packageModule($name)]} {
	    continue
	}

	# if we got here, this is the first time we've seen this package,
	# this module must have done it
	set packageModule($name) $module
    }
}

# package_report --
#
#	Report on which modules provided what packages.
#
# Arguments:
#	None
#
# Side Effects:
#	None
#
# Results:
#	By examining data recorded by process_package, writes a line
#	of output into the file pointed to by global "mergefp".
#
#	The line contains the record type (module_package), the module
#	name, package name and package version number provided.
#
proc package_report {} {
    global packageModule mergefp

    foreach package [lsort [array names packageModule]] {
	set packVer [split $package ":"]
	puts $mergefp [list module_package $packageModule($package) [lindex $packVer 0] [lindex $packVer 1]]
    }
}

proc doit {{argv ""}} {
    global mergefp

    set mergefp [open SNAPSHOT.merge w]
    merge_snapshot
    package_report
}

if !$tcl_interactive {doit $argv}
