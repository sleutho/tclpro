#
# Prototype program to bundle different parts of the TclPro build into
# web-installable zip files.
#
# Requires the SNAPSHOT file that the modified buildModule.tcl constructs
# over subsequent installations of various pieces to figure out what
# installation produced what file in the out directory.
#
# $Id: bundle.tcl,v 1.2 2001/03/15 12:53:19 karll Exp $
#

set tempVersion 1-5-0

# lassign - what a great idea, it should be in the core
proc lassign {valueList args} {
  if {[llength $args] == 0} {
      error "wrong # args: lassign list varname ?varname..?"
  }

  uplevel [list foreach $args $valueList {break}]
  return [lrange $valueList [llength $args] end]
}


# process_merge_snapshot
#
#	Reads the SNAPSHOT.merge file to produce one or more zip files 
#	for each module that has files in it.
#
# Arguments:
#	None
#
# Side Effects:
#
# Results:
#
#	Makes a zipfiles directory in the out directory.
#	Reads SNAPSHOT.merge from the current directory.
#	Creates one or more zip files for each module that has a
#	file listed in the merge file.
#	
proc process_merged_snapshot {} {
    global tempVersion

    # sort the SNAPSHOT file so the zip file contents will be prettier
    # also for some reason, it makes the program run much faster.
    set fp [open "|sort <SNAPSHOT.merge"]
    file mkdir zipfiles
    cd out

    while {[gets $fp line] >= 0} {
	lassign $line type modules file

	# ignore records other than module_file
	if {$type != "module_file"} {
	    continue
	}
	set xfile [file split $file]

	set subdist "main"

	# if it's in a manpage directory, put it into the man subdist
	if {[lindex $xfile 1] == "man"} {
	    set subdist "man"
	}

	# if demos appears as a directory in its path, put it into
	# the demos subdist
	if {[lsearch $xfile "demos"] >= 0} {
	    set subdist "demos"
	}

	# otherwise for each module this file is a part of, add this
	# file to the zip archive for that module
	foreach module $modules {
	    # if there isn't a pipeline open to an invocation of zip
	    # that is producing a zip archive for this module, open
	    # a pipeline to the zip archive -- zip will be reading
	    # filenames from this pipeline
	    set modPlusDist "$module-$subdist"
	    if {![info exists pipelines($modPlusDist)]} {
		set pipelines($modPlusDist) [open "|zip ../zipfiles/$modPlusDist-$tempVersion.zip -@" w]
	    }
	    puts $pipelines($modPlusDist) $file
	}
    }
    close $fp
    # shut down the pipelines to all of the invocations of zip
    foreach module [array names pipelines] {
	close $pipelines($module)
    }
}

proc doit {{argv ""}} {
    process_merged_snapshot
}

if !$tcl_interactive {doit $argv}
