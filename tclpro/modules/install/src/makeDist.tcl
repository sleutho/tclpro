#!/bin/sh
#\
exec tclsh8.0 "$0" "$@"

# makeDist.tcl
#
#    This is the master script used to "generate" the TclPro installation
#    images for _both_ UNIX & Windows.
#
# USAGE
#	<tclsh> makeDist.tcl <stageDir> <distDir> <prefix> <ex_pre>
# 
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: makeDist.tcl,v 1.24 2001/02/08 21:38:43 welch Exp $

proc Exec {args} {
    if {[catch {eval exec $args} msg]} {
	puts "makeDist script exitting due to the following error:"
	puts $msg
	exit
    }
}

proc genSrc {stageDir distDir} {
    global fastSrcCopy
    set srcDir [file join $distDir src]
    file mkdir $srcDir

    cd $distDir

    # Generate Tcl - configure in temp dir to avoid dirtying tcl workspace

    if {!$fastSrcCopy  ||
	    ![file isdirectory [file join $srcDir $projectInfo::srcDirs(tcl)]]} {
	cd [file join $stageDir $projectInfo::localSrcDirs(tcl) unix]
	file delete configure
	catch {exec autoconf >@stdout >&@stdout}
	cd dltest
	file delete configure
	catch {exec autoconf >@stdout >&@stdout}

	cd [file join $stageDir $projectInfo::localSrcDirs(tcl) win]
	file delete configure
	catch {exec autoconf >@stdout >&@stdout}

	cd $distDir
	file mkdir tmp-tcl
	cd tmp-tcl
	puts "Configuring Tcl..."
	Exec [file join $stageDir $projectInfo::localSrcDirs(tcl) unix configure] --enable-gcc
	puts "Copying Tcl source files..."
	Exec make dist DISTDIR=[file join $srcDir $projectInfo::srcDirs(tcl)]
	cd ..
    }

    # Generate Tk - configure in temp dir to avoid dirtying tk workspace

    if {!$fastSrcCopy  ||
	    ![file isdirectory [file join $srcDir $projectInfo::srcDirs(tk)]]} {
	cd [file join $stageDir $projectInfo::localSrcDirs(tk) unix]
	file delete configure
	catch {exec autoconf >@stdout >&@stdout}

	cd [file join $stageDir $projectInfo::localSrcDirs(tk) win]
	file delete configure
	catch {exec autoconf >@stdout >&@stdout}

	cd $distDir
	file mkdir tmp-tk
	cd tmp-tk
	puts "Configuring Tk..."
	Exec [file join $stageDir $projectInfo::localSrcDirs(tk) unix configure] --enable-gcc --with-tcl=[file join $distDir tmp-tcl]
	puts "Copying Tk source files..."
	Exec make dist DISTDIR=[file join $srcDir $projectInfo::srcDirs(tk)]
	cd ..
    }

    # Generate Itcl

    if {!$fastSrcCopy  ||
	    ![file isdirectory [file join $srcDir $projectInfo::srcDirs(itcl)]]} {
	cd [file join $stageDir $projectInfo::localSrcDirs(itcl)]
	if {![file exists Makefile]} {
	    file delete configure
	    exec autoconf >@stdout >&@stdout
	    if {[catch {
		exec [file join [pwd] configure] \
			--enable-gcc --prefix=$stageDir \
			--with-tcl=[file join $distDir tmp-tcl] >@stdout >&@stdout
	    } err]} {
		puts "Configure of Itcl failed, error: $err"
		puts "This is expected behaviour."
	    }
	}
	file delete configure
	Exec make configure
	Exec [file join [pwd] configure] --enable-gcc --prefix=$stageDir \
		--with-tcl=[file join $distDir tmp-tcl] \
		--with-tk=[file join $distDir tmp-tk] >@stdout >&@stdout
	Exec make distclean

	# Since there is no dist target, copy all of the files.

	puts "Copying Itcl files..."
	cd $stageDir
	set files [exec find $projectInfo::localSrcDirs(itcl) \
			! ( -name .cvsignore ) \
			-a ( \
			    ( -name Codemgr_wsdata -prune ) \
			    -o ( -name CVS -prune ) \
			    -o ( -name deleted_files -prune ) \
			) -o -print]

	if {[info exist destFiles]} { set destFiles [list] }
	set destPath [file join $srcDir $projectInfo::srcDirs(itcl)]
	foreach file $files {
	    # make sure the replacement only happens once.
	    regsub -- $projectInfo::localSrcDirs(itcl) $file $destPath dest
	    lappend destFiles $dest
	}

	foreach file $files destFile $destFiles {
	    if {[file isdir $file]} {
		file mkdir $destFile
	    } else {
		file copy -force $file $destFile
	    }
	}
    }

    # Generate TclX sources

    # Since there is no dist target, copy all of the files.

    if {!$fastSrcCopy  ||
	    ![file isdirectory [file join $srcDir $projectInfo::srcDirs(tclx)]]} {
	puts "Copying TclX files..."
	cd $stageDir
	set files [exec find $projectInfo::localSrcDirs(tclx) \
			! ( -name .cvsignore ) \
			-a ( \
			    ( -name Codemgr_wsdata -prune ) \
			    -o ( -name CVS -prune ) \
			    -o ( -name deleted_files -prune ) \
			) -o -print]

	if {[info exist destFiles]} { set destFiles [list] }
	set destPath [file join $srcDir $projectInfo::srcDirs(tclx)]
	foreach file $files {
	    # make sure the replacement only happens once.
	    regsub -- $projectInfo::localSrcDirs(tclx) $file $destPath dest
	    lappend destFiles $dest
	}

	foreach file $files destFile $destFiles {
	    if {[file isdir $file]} {
		file mkdir $destFile
	    } else {
		file copy -force $file $destFile
	    }
	}
    }


    # Generate Expect sources

    # Since there is no dist target, copy all of the files.

    if {!$fastSrcCopy  ||
	    ![file isdirectory [file join $srcDir $projectInfo::srcDirs(expect)]]} {
	puts "Copying Expect files from $projectInfo::localSrcDirs(expect)"
	cd $stageDir
	set files [exec find $projectInfo::localSrcDirs(expect) \
			! ( -name .cvsignore ) \
			-a ( \
			    ( -name Codemgr_wsdata -prune ) \
			    -o ( -name CVS -prune ) \
			    -o ( -name deleted_files -prune ) \
			) -o -print]

	if {[info exist destFiles]} { set destFiles [list] }
	set destPath [file join $srcDir $projectInfo::srcDirs(expect)]
	foreach file $files {
	    # make sure the replacement only happens once.
	    regsub -- $projectInfo::localSrcDirs(expect) $file $destPath dest
	    lappend destFiles $dest
	}

	foreach file $files destFile $destFiles {
	    if {[file isdir $file]} {
		file mkdir $destFile
	    } else {
		file copy -force $file $destFile
	    }
	}
    }

    file delete -force [file join $distDir tmp-tcl]
    file delete -force [file join $distDir tmp-tk]
}

proc touch {filePath} {
    if {![file isdir [file dir $filePath]]} {
	catch {file mkdir [file dir $filePath]}
    }
    catch {close [open $filePath w]}
}

proc copy {src dest file} {
    global test
    if {![file isdir $dest]} {
	catch {file mkdir $dest}
    }
    set files [glob -nocomplain -- [file join $src $file]]
    if {$files == ""} {
	puts stderr "MISSING: [file join $src $file]"
	if {$test} {
	    touch [file join $dest $file]
	}
    } else {
	foreach file $files {
	    if {[file isdir $file]} {
		continue
	    }
	    set dfile [file join $dest [file tail $file]]
	    if {[catch {file copy -force $file $dfile} msg]} {
		puts stderr "ERROR: $msg"
		if {$test} {
		    touch $dfile
		}
	    } else {
		set perm [file attributes $dfile -permissions]
		file attributes $dfile -permissions [format 0%o \
			[expr {$perm & 0555}]]
	    }
	}
    }
}



puts "--- makeDist.tcl started: \
	[clock format [clock seconds] -format "%Y%m%d-%H:%M"] --"

set argc [llength $argv]

if {$tcl_platform(platform) != "unix"} {
    puts "This script must be run from a Unix system."
    exit 1
}

if {$argc < 4 || $argc > 5} {
    puts "usage: $argv0 ?-test? <stageDir> <distDir> <prefix> <exec_prefix>"
    exit 1
} else {
    if {$argc == 5} {
	set test 1
	set stageDir [lindex $argv 1]
	set distDir [lindex $argv 2]
	set prefix [lindex $argv 3]
	set exec_prefix [lindex $argv 4]
    } else {
	set test 0
	set stageDir [lindex $argv 0]
	set distDir [lindex $argv 1]
	set prefix [lindex $argv 2]
	set exec_prefix [lindex $argv 3]
    }
}

set auto_path [list [info library] [file join $prefix lib]]
set installSrcDir [file join $stageDir tclpro modules install src]

package require projectInfo
parray projectInfo::srcDirs

set fileListFn [file join $installSrcDir parts.in]

if {![file exist $fileListFn]} {
    puts stderr "ERROR: Parts list file $fileListFn does not exist."
    exit -1
}

# Prompt to remove the dist directory if it exists.  Also make
# the imageDir absolute if it isn't already.

set fastSrcCopy 0
set distDir [file join [pwd] $distDir]
if {[file exists $distDir]} {
    puts -nonewline "Remove \"$distDir\"? \[yn\] "
    flush stdout
    set result [gets stdin]
    if {$result == "y" || $result == ""} {
	puts "Removing \"$distDir\" . . ."
	file delete -force $distDir
    } else {
	puts stderr "WARNING: Directory \"$distDir\" exists.  Proceeding."
	set fastSrcCopy 1
    }
}

# Generate the source file distributions first, since they spew and might
# mask MISSING warnings generated by the parts list.

genSrc $stageDir $distDir

# Parse the parts list and copy the specified files

set fileListFile [open $fileListFn r]
set fileList [read $fileListFile]
close $fileListFile

set rawFileList [split $fileList "\n"]

puts "Copying files from parts list..."

foreach rawFileElement $rawFileList {
    if {![string match "#*" $rawFileElement]
    	    && [llength $rawFileElement]} {

	# Support for variables and other code in the parts list file.

	if {[regexp "^eval" $rawFileElement]} {

	    # Do "string" range instead of "list" range to
	    # avoid quoting of variable references

	    puts stderr [string range $rawFileElement 4 end]
	    eval [string range $rawFileElement 4 end]
	    continue
	}
	
	# The subst allows variable references in the parts.in file

	if {[catch {
	    set rawFileElement [subst $rawFileElement]
	} err]} {
	    puts "ERROR: $rawFileElement\n$err"
	    continue
	}

	set distPath  [lindex $rawFileElement 0]
	set stagePath [lindex $rawFileElement 1]
	set file [lindex $rawFileElement 2]
	set plat [lindex $rawFileElement 3]
	set built [lindex $rawFileElement 4]

	copy [file join $stageDir $stagePath] [file join $distDir $distPath] $file
    }
}

# The $distDir/. construct is to skip through a symlink at $distDir

puts "Setting directory permissions on $distDir..."
exec find $distDir/. -type d | xargs chmod 0755
puts "Setting all file permissions to be readable on $distDir..."
catch {exec chmod -R a+r $distDir}
puts "Making configure scripts executable..."
catch {exec find $distDir/. -name configure | xargs chmod 0555}
puts "Setting time stamps..."
set time [clock format [clock seconds] -format %m%d%H%M]
catch {
    # Could do Tcl equivalent
exec find $distDir/. | xargs touch -acm -t $time
}

puts "\n--- makeDist.tcl finished: \
	[clock format [clock seconds] -format "%Y%m%d-%H:%M"] --\n\n"
