# genImage.tcl
#
#    This is the master script used to "generate" the TclPro installation
#    images for _both_ UNIX & Windows.
#
# USAGE
#	<tclsh> genImage.tcl <stageDir> <distDir> <imageDir> <prefix> <exec-prefix> ?debug?
# 
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: genImage.tcl,v 1.18 2001/02/06 22:08:03 welch Exp $

set beginSeconds [clock seconds]
puts "\n--- genImage.tcl started: \
        [clock format $beginSeconds -format "%Y%m%d-%H:%M"] --\n"

# This file is insensitive to the directory from which it is invoked.
# To do this all sources the script refers to should be accessed
# via the installSrcDir which is the directory containing this
# script.  However, installSrcDir must not be ".".

set installSrcDir [file join [pwd] [file dir [info script]]]
source [file join $installSrcDir ../../projectInfo/projectInfo.tcl]

# parseCmdLineArgs --
#
#	Set these global variables:
#		stageDir	The build area
#		distDir		The "make dist" output area
#		imageDir	The "make image" output area
#		toolsDir	E.g., /tools/1.3
#		protoolsDir	E.g., /tools/TclPro1.3
#		prefix		The compiled in prefix (for patching)
#		exec_prefix	The compiled in exec_prefix (for patching)
#
#	If imageDir already exists, prompt the user to either remove it,
#	keep it, or quit the program.
#
#	Create the directory "outDir" that will contain the files to
#	compress.
#
# Arguments:
#	argv	The list of argument to parse.
#
# Side Effects:
#	See above

proc parseCmdLineArgs {argv} {
    global stageDir distDir imageDir outDir debug fastCopy
    global toolsDir protoolsDir prefix exec_prefix

    set debug 0
    if {[string compare debug [lindex $argv end]] == 0} {
	set debug 1
    }

    set stageDir	[lindex $argv 0]
    set distDir		[lindex $argv 1]
    set imageDir	[lindex $argv 2]
    set toolsDir	[lindex $argv 3]
    set protoolsDir	[lindex $argv 4]
    set prefix		[lindex $argv 5]
    set exec_prefix	[lindex $argv 6]

puts stderr "prefix = $prefix"
puts stderr "exec_prefix = $exec_prefix"
    # Prompt to remove the image directory if it exists.  Also make
    # the imageDir absolute if it isn't already.

    set fastCopy 0
    set imageDir [file join [pwd] $imageDir]
    if {[file exists $imageDir]} {
	puts -nonewline "Remove \"$imageDir\"? \[yn\] "
	flush stdout
	set result [gets stdin]
	if {$result == "y"} {
	    puts "Removing \"$imageDir\" . . ."
	    file delete -force $imageDir
	} elseif {$result == "go"} {
	    set fastCopy 1
	} else {
	    puts stderr "ERROR: Directory \"$imageDir\" exists.  Quitting."
	    exit -1
	}
    }

    # Set the name of the dir that users will see when they untar
    # the web download.  Create the dir if it doesn't already exist,
    # and remove any existing unix/lic* files from outDir.

    set outDir [file join $imageDir tclpro$projectInfo::baseVersion]
    file mkdir $outDir

    foreach file [glob -nocomplain [file join $outDir unix lic*]] {
	catch {file delete -force $file}
    }
}

# setupPlatform --
#
#	This routine attempts to determine the correct tools directory
#	and wrapper executable to use for the current platform.
#
# Arguments:
#	stageDir	The directory containing the workspaces to
#			build from.
#
# Results:
#	Sets the prowrap and toolsDir variables.

proc setupPlatform {stageDir} {
    global prowrap toolsDir tcl_platform
    global prefix exec_prefix

    # determine the current platform

    switch $tcl_platform(os) {
	SunOS {
	    set plat solaris-sparc
	}
	HP-UX {
	    set plat hpux-parisc
	}
	Linux {
	    set plat linux-ix86
	}
	Irix {
	    set plat irix-mips
	}
	Aix {
	    set plat aix-risc
	}
	FreeBSD {
	    set plat freebsd-ix86
	}
	default {
	    puts stderr "ERROR: cannot generate images on $tcl_platform(platform)"
	    exit 1
	}
    }

    # Use our own wrapper
    set prowrap [file join $exec_prefix bin/prowrap]

    # Tools for unzip, acrobat, etc.
    set toolsDir /tools/1.3

    return
}

# parseParts --
#
#	Parse the parts list and store the info in the distFiles array.
#
# Arguments:
#	stageDir	The directory containing the workspaces to use.
#	distDir		The target directory where files will be placed.
#
# Results:
#	None.

proc parseParts {stageDir distDir} {
    global distFiles installSrcDir

    set partsPath [file join $installSrcDir parts.in]

    if {![file exist $partsPath]} {
	puts stderr "ERROR: cannot find $partsPath"
	exit 1
    }
    puts "PartsList: $partsPath"

    set fd [open $partsPath r]

    foreach line [split [read $fd] \n] {
	set line [string trim $line]
	
	# Skip blank lines and comments

	if {($line == "") || ([string index $line 0] == "#")} {
	    continue
	}

	# Support for variables and other code in the parts list file.
	# "string" range is used instead of "lrange" to avoid
	# quoting of variable references in the statement.

	if {[regexp "^eval" $line]} {
	    puts stderr [string range $line 4 end]
	    uplevel #0 [string range $line 4 end]
	    continue
	}
	
	# The subst allows variable references in the parts.in file

	if {[catch {
	    set line [uplevel #0 [list subst $line]]
	} err]} {
	    puts "ERROR: $line\n$err"
	    continue
	}

	set distPath  [lindex $line 0]
	set stagePath [lindex $line 1]
	set globPat   [lindex $line 2]
	set plat      [lindex $line 3]
	set built     [lindex $line 4]
        set destFile  [file join $distDir $distPath $globPat]
	
	# Get this list of files that is returned from the glob call.
	# If the glob result is empty, gen an error message and 
	# check the next line.

	set globList [glob -nocomplain $destFile]
	if {$globList == {}} {
	    puts stderr "MISSING: $destFile"
	    continue
	}

	# The path from the glob's result is absolute from the "distDir."
	# Foreach path, strip the directory and append the filename to
	# the "distPath".  Then append the new path to the correct list.

	foreach path $globList {
	    # Exclude directories from the list of acceptable paths.
	    if {[file isdirectory $path]} {
		continue
	    }

	    set file [file tail $path]
	    lappend distFiles($plat) [file join $distPath $file]
	}
    }

    close $fd

    return
}

# parseManifest --
#
#	Parse the manifest file that determines which files go into which
#	distributions.
#
# Arguments:
#	stageDir	The directory containing the workspaces to use.
#	distDir		The directory containing the dist files.
#	tmpDir		The directory to store intermediate files into.
#
# Results:
#	Fills in the imageFiles and wrap arrays.

proc parseManifest {stageDir distDir tmpDir} {
    global imageFiles distFiles wrap wrapInfo toolsDir
    global installSrcDir

    set partsPath [file join $installSrcDir cdparts.in]

    if {![file exist $partsPath]} {
	puts stderr "ERROR: cannot find $partsPath"
	exit 1
    }

    # Initialize wrapInfo in case we're only generating a windows image
    # and files with the "wrap" flag in cdparts.in don't exist.

    set wrapInfo ""

    set fd [open $partsPath r]

    foreach line [split [read $fd] \n] {
	set line [string trim $line]
	
	# Skip blank lines and comments

	if {($line == "") || ([string index $line 0] == "#")} {
	    continue
	}

	# Support for variables and other code in the parts list file.
	# "string" range is used instead of "lrange" to avoid
	# quoting of variable references in the statement.

	if {[regexp "^eval" $line]} {
	    puts stderr [string range $line 4 end]
	    uplevel #0 [string range $line 4 end]
	    continue
	}
	
	# The subst allows variable references in the parts.in file

	if {[catch {
	    set line [uplevel #0 [list subst $line]]
	} err]} {
	    puts "ERROR: $line\n$err"
	    continue
	}

	# Parse the line into three parts, the output name, the flags, and
	# the source name

	foreach {dst src} [split $line \#] {}
	set dstName [lindex $dst 0]
	set tmpFile [file join $tmpDir $dstName]
	set flags [lrange $dst 1 end]
	set type [lindex $src 0]
	set srcPaths [lrange $src 1 end]

	# Ensure the existence of the destination directory

	file mkdir [file dirname $tmpFile]

	# Copy the specified files into the temporary directory
	
	if {$type == "PARTS"} {
	    set save [pwd]
	    cd $distDir
	    set files {}
	    foreach plat $srcPaths {
		if {[info exists distFiles($plat)]} {
		    set files [concat $files $distFiles($plat)]
		}
	    }
	    createZipFile $distDir $files $tmpFile
	    cd $save
	} elseif {$type == "SRC"} {
	    set save [pwd]
	    cd $distDir
	    set files {}
	    foreach pkg $srcPaths {
		set dir $::projectInfo::srcDirs($pkg)
		lappend files [exec find [file join src $dir]]
	    }
	    createZipFile $distDir $files $tmpFile
	    cd $save
	} else {
	    if {$type == "STAGE"} {
		set dir $stageDir
	    } elseif {$type == "TOOLS"} {
		set dir $toolsDir
	    }
	    set file [file join $dir [lindex $srcPaths 0]]
	    if {![file exists $file]} {
		puts stderr "MISSING: $file"
		continue
	    }
	    copy $file $tmpFile
	}
	
	# Process the resulting files according to the flags

	foreach flag $flags {
	    switch $flag {
		wrap {
		    # Compute the original size of the file and add it to the
		    # list of wrap targets

		    append wrapInfo "set install::unwrappedFileSizes([file tail $dstName]) [file size $file]\n"
		    set wrap($dstName) $tmpFile
		}
		exe {
		    chmod 0755 $tmpFile
		}
		cdrom -
		unix -
		c-all -
		c-unix -
		c-sol -
		c-hp -
		c-lin -
		c-sgi -
		c-win -
		c-aix -
		c-bsd -
		l-sol -
		l-hp -
		l-lin -
		l-sgi -
		sol -
		hp -
		lin -
		sgi -
		aix -
		bsd -
		win {
		    lappend imageFiles($flag) $dstName
		}
		default {
		    error "UNSUPPORTED FLAG: $flag"
		}
	    }
	}
    }

    return
}

# wrapBinaries --
#
#	Generate the wrapped installation executables.
#
# Arguments:
#	stageDir	The directory containing the workspaces.
#
# Results:
#	None.

proc wrapBinaries {stageDir} {
    global wrap wrapInfo prowrap installSrcDir debug
    global prefix exec_prefix

    # Capture the zip file sizes for the installer time estimates

    set sizesFile [file join $installSrcDir unwrapsizes.tcl]
    set f [open $sizesFile w]
    puts -nonewline $f $wrapInfo

    # Capture the build prefix and exec_prefix for install-time patching

    puts $f [list set install::PREFIX $prefix]
    puts $f [list set install::EXEC_PREFIX $exec_prefix]
    puts $f [list set install::TCL_LIBRARY [file join $prefix lib tcl8.3]]
    puts $f [list set install::SHLIBPATH [file join $prefix _PLATFORM_ lib]]
    puts $f [list set install::TCL_PACKAGE_PATH \
		[list \
		    [file join $prefix _PLATFORM_ lib] \
		    [file join $prefix lib]]]
    close $f

    # Create wrapper command line for the Installer executable

    set wrapTclFlags [list -nologo -startup setup.tcl -uses bigtclsh-lite \
		-relativeto $installSrcDir ]
    
    foreach f { acrobat_license.txt acrobat_license.txt.nolnbrk 
	    gui.tcl install.tcl license.txt license.txt.nolnbrk 
	    messages.tcl setup.tcl tclProSplash.gif text.tcl 
	    unwrapsizes.tcl upgprefs.tcl } {
	lappend wrapTclFlags [file join $installSrcDir $f]
    }
    lappend wrapTclFlags \
	    -relativeto [file join $stageDir tclpro/modules] \
	    [file join $stageDir tclpro/modules projectInfo/projectInfo.tcl]


    set wrapTkFlags [concat $wrapTclFlags -uses bigwish-lite]

    foreach name [array names wrap] {
	if {![regexp {^p(t|w)} [file tail $name] dummy type]} {
	    puts stderr "ERROR: unexpected wrapper input $name"
	}

	if {$type == "t"} {
	    set flags $wrapTclFlags
	} else {
	    set flags $wrapTkFlags
	}

	# Generate the wrapped executable

	set debug 1
	if {$debug} {
	    set verbose "-verbose"
	    puts "Generating $wrap($name) using the following wrapper cmdline:"
	    puts "$prowrap $verbose -out $wrap($name).out -executable $wrap($name) $flags\n"
	} else {
	    set verbose "-nologo"
	    puts "Generating $wrap($name) . . ."
	}
	if {[catch {eval {exec $prowrap $verbose -out $wrap($name).out \
		-executable $wrap($name)} $flags} msg]} {
	    puts stderr "ERROR: $msg"
	} else {
	    puts $msg
	}

	# Replace the unwrapped executable with the wrapped one, preserving
	# the permissions from the original.  If the wrapped one didn't get
	# produced in the prior, rename it to have the .bak extension for
	# future inspection.

	set attr [file attributes $wrap($name) -permissions]
	if {[file exists $wrap($name).out]} {
	    file rename -force $wrap($name) $wrap($name).bak
	    file rename -force $wrap($name).out $wrap($name)
	} else {
	    puts stderr "ERROR: $wrap($name).out was never created"
	    catch {file rename -force $wrap($name) $wrap($name).bak}
	}
	file attributes $wrap($name) -permissions $attr
    }

#    file delete $sizesFile
puts stderr "DELETE $sizesFile"

    return
}

# copy --
#
#	Copy files, creating intermediate directories if necessary.
#
# Arguments:
#	src	The file to copy.
#	dest	The name to copy into.
#
# Results:
#	None.

proc copy {src dest} {
    if {![file isdir [file dir $dest]]} {
	catch {file mkdir [file dir $dest]}
    }
    if {[catch {file copy -force $src $dest} msg]} {
	puts stderr "ERROR: $msg"
    }
    return
}

# chmod --
#
#	Set the permissions of a file, logging any errors.
#
# Arguments:
#	perm	The octal permissions value.
#	file	The file to modify.
#
# Results:
#	None.

proc chmod {perm file} {
    if {[catch {file attributes $file -permissions $perm} msg]} {
	puts stderr "ERROR: $msg"
    }
    return
}

# createZipFile --
#
#	Create a zip file to contain the given list of files from
#	the dist directory.
#
# Arguments:
#	distDir		The directory containing the files to be zipped.
#	distFileList	The files to zip.
#	zipFilePath	The path to the zip file being created.
#
# Results:
#	None.

proc createZipFile {distDir distFileList zipFilePath} {
    global fastCopy
    if {$fastCopy && [file exists $zipFilePath]} {
	puts "Using existing $zipFilePath"
	return
    }
    set saveDir [pwd]
    cd $distDir

    puts "Creating zip file: $zipFilePath"
    set zipPipe [open "| zip -@ $zipFilePath" w]

    foreach distFile $distFileList {
	puts $zipPipe $distFile
    }

    catch {close $zipPipe} msg
    puts stderr $msg

    cd $saveDir
    return
}

# fillWebAndCdromDirs --
#
#	Create the .tar, .tar.gz, and .zip files for the web downloads.
#	Copy cdrom files from Dist area.
#
# Arguments:
#	skipGz	(optional) if true, only produce tar and zip files, don't
#		produce gz files.
#
# Results:
#	None.

proc fillWebAndCdromDirs {{skipGz 0}} {
    global imageDir imageFiles outDir

    file mkdir [file join $imageDir web]
    set oldDir [pwd]
    cd $imageDir

    # Compress tar and zip files
    # The "type" is a tag in the parts list file.
    # The "tarSuffix" is used in the name of the tar file.
    
    foreach {type tarSuffix} {
		hp hpux
		sol solaris
		lin linux
		sgi irix
    		aix aix
		bsd freebsd
	    } {
	if {[catch {
	    set tarfile tclpro$::projectInfo::shortVers.$tarSuffix.tar
	    set files {}
	    foreach file [concat $imageFiles($type) $imageFiles(unix)] {
		lappend files [file join tclpro$::projectInfo::baseVersion $file]
	    }

	    set tarfile tclpro$::projectInfo::shortVers.$tarSuffix.tar
	    lappend files [file join tclpro$::projectInfo::baseVersion \
		    $imageFiles(c-all)]
	    lappend files [file join tclpro$::projectInfo::baseVersion \
		    $imageFiles(c-unix)]
	    lappend files [file join tclpro$::projectInfo::baseVersion \
		    $imageFiles(c-$type)]
	    puts "Generating $tarfile..."
	    eval [list exec tar cf [file join web $tarfile]] $files

	    if {!$skipGz} {
		puts "Compressing $tarfile (.gz) ..."
		exec gzip -9c [file join web $tarfile] \
			> [file join web ${tarfile}.gz]
	    }
	} error]} {
	    puts stderr "ERROR: $error"
	}
    }

    # Copy Windows download files into image directory
    
    if {[info exist imageFiles(win)]} {
	foreach name $imageFiles(win) {
	    copy [file join $outDir $name] [file join $imageDir web $name]
	}
    } else {
	puts stderr "MISSING: win files"
    }

    # Move file from the temporary directory to the cdrom directory, 
    # changing the file names to all upper case
    
    file mkdir [file join $imageDir cdrom]
    foreach name $imageFiles(cdrom)  {
	copy [file join $outDir $name] \
		[file join $imageDir cdrom [string toupper $name]]
    }

    cd $oldDir
    return
}

parseCmdLineArgs $argv

setupPlatform $stageDir

parseParts $stageDir $distDir

parseManifest $stageDir $distDir $outDir

wrapBinaries $stageDir 

fillWebAndCdromDirs $debug

if {!$debug} {
    puts "Cleaning up..."
    file delete -force $outDir
}
set endSeconds [clock seconds]
set diff [expr {($endSeconds - $beginSeconds) / 60}]
puts "\n--- genImage.tcl finished after $diff minutes: \
        [clock format $endSeconds -format "%Y%m%d-%H:%M"] --\n\n"
