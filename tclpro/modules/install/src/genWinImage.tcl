# genWinImage.tcl --
#
#	This script generates the Windows installer.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: genWinImage.tcl,v 1.9 2001/01/16 05:19:07 welch Exp $


set installSrcDir [file dir [info script]]
source [file join $installSrcDir ../../projectInfo/projectInfo.tcl]

source [file join [file dir [info script]] utils.tcl]

namespace eval genWinImage {

    # cdParts --
    #
    # This variable contains the list of files that only appear in the
    # CD version of the installer.

    variable cdParts

    # webParts --
    #
    # This variable contains the list of files that appear both in the
    # CD version of the installer and in the web version.

    variable webParts

    # distDir --
    #
    # This variable points to the directory that contains the unzipped
    # distribution files.

    variable distDir

    # toolsDir --
    #
    # This variable points to the platform specific tools directory.

    variable toolsDir

    # stageDir --
    #
    # This variable points to the directory containing the source trees.

    variable stageDir
}

# genWinImage::init --
#
#	This is the main entry point.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc genWinImage::init {} {
    global tcl_platform argv argv0
    variable cdParts
    variable webParts
    variable stageDir
    variable distDir
    variable toolsDir
 
    puts "\n--- genWiImage.tcl started: \
	    [clock format [clock seconds] -format "%Y%m%d-%H:%M"] --\n"

    set saveDir [pwd]
    cd [file dir [info script]]

    if {$tcl_platform(platform) != "windows"} {
	puts stderr "ERROR: Cannot build PRO.EXE on Unix systems"
	exit 1
    }

    if {[llength $argv] != 3} {
	puts stderr "usage: $argv0 <stageDir> <distDir> <toolsDir>"
	exit 0
    }

    lassign $argv stageDir distDir toolsDir

    set fileListFn [file join $stageDir tclpro/modules/install/src/parts.in]

    if {![file exist $fileListFn]} {
	puts stderr "MISSING: \"$fileListFn\""
	exit -1
    }

    genWinImage::parsePartsList $fileListFn

    puts "Creating webfiles.wse"

    # Create the webfiles.wse script file that lists all of the files being
    # installed.

    set f [genWinImage::openWiseFile webfiles.wse]
    genWinImage::addComponent $f A $webParts
    close $f

    # Now create the cd-only distribution file

    puts "Creating cdfiles.wse"
    set f [genWinImage::openWiseFile cdfiles.wse]
    genWinImage::addComponent $f B $cdParts
    foreach pkg {tcl tk itcl tclx} component {C D E F} {
	puts "adding $pkg"
	genWinImage::addComponent $f $component \
		[sourceFiles [file join src $projectInfo::srcDirs($pkg)]]
    }
    close $f

    # We also need to translat the license file into crlf format so we aren't
    # sensitive to CVS platform differences.

#    genWinImage::convertFile crlf \
#	    [file join [file dir [info script]] license.txt.nolnbrk] \
#	    new-license.txt.nolnbrk

    genWinImage::convertFile crlf license.txt.nolnbrk \
	    new-license.txt.nolnbrk

    generateInstallers
 
    cd $saveDir

    puts "\n--- genWiImage.tcl finished: \
	    [clock format [clock seconds] -format "%Y%m%d-%H:%M"] --\n\n"
}

# genWinImage::sourceFiles --
#
#	List all of the files inside a given source heirarchy.
#
# Arguments:
#	dir	The top of a source tree (e.g. tcl8.1)
#
# Results:
#	Returns the list of all of the files in the directory tree.

proc genWinImage::sourceFiles {dir} {
    variable distDir
    variable toolsDir

    set olddir [pwd]
    cd $distDir
    set files [exec [file join $toolsDir bin find.exe] \
		[file join $dir] -type f]
    cd $olddir
    return $files
}

# genWinImage::convertFile --
#
#	Converts the file either from \n to \r\n or vice versa
#	based on the passed in control arg.
#
# Arguments:
#	control		Either lf or crlf.
#	file		File name to convert.
#	newName		Dest file name if not null.
#
# Results:
#	None.  The file is changed on disk.

proc genWinImage::convertFile {control file {newName {}}} {
    puts "cwd = [pwd]"
    puts "convertion file $file to $newName"
    set inId [open $file]
    set data [read $inId]
    close $inId

    if {$newName != ""} {
	set file $newName
    }

    set outId [open $file w]
    fconfigure $outId -translation $control
    puts -nonewline $outId $data
    close $outId
}

# genWinImage::parsePartsList --
#
#	Parses the srcs/install/parts.in file to determine which files
#	belong in the Web distribution and which belong in the CD-ROM
#	distribution.
#
# Arguments:
#	partsFile	The name of the parts list file.
#
# Results:
#	Stores the list of files in cdParts and webParts variables.

proc genWinImage::parsePartsList {fileListFn} {
    variable distDir

    variable cdParts {}
    variable webParts {}

    set fileListFile [open $fileListFn r]
    set fileList [read $fileListFile]
    close $fileListFile

    set rawFileList [split $fileList "\n"]

    foreach rawFileElement $rawFileList {
	if {[string match "#*" $rawFileElement] \
		|| ([llength $rawFileElement] == 0)} {
	    continue
	}

	# Support for variables and other code in the parts list file.

	if {[regexp "^eval" $rawFileElement]} {
	    puts stderr [string range $rawFileElement 4 end]
	    uplevel #0 [string range $rawFileElement 4 end]
	    continue
	}
	
	# The subst allows variable references in the parts.in file

	if {[catch {
	    set rawFileElement [uplevel #0 [list subst $rawFileElement]]
	} err]} {
	    puts "ERROR: $rawFileElement\n$err"
	    continue
	}

	lassign $rawFileElement distPath stagePath globPat plat
	if {![regexp {^(all|win)(/cd)?$} $plat dummy plat cdonly]} {
	    continue
	}
	    
        set destFile  [file join $distDir $distPath $globPat]
	
	# Get this list of files that is returned from the glob call.
	# If the glob result is empty, gen an error message and 
	# check the next rawFileElement.

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

	    set file [file join $distPath [file tail $path]]
	    if {$cdonly == ""} {
		lappend webParts $file
	    } else {
		lappend cdParts $file
	    }
	}
    }
    return
}

# genWinImage::addComponent --
#
#	Emit the files for a particular component.
#
# Arguments:
#	fd	The file handle for the output script.
#	id	The WISE component id (e.g "A")
#	files	The list of files to include.
#
# Results:
#	None.

proc genWinImage::addComponent {fd id files} {
    variable distDir

    # Each component is surrounded by a conditional block based on the
    # component identifier.  This causes WISE to associate all of the files
    # with the specified component.

    puts $fd "item: If/While Statement
  Variable=COMPONENTS
  Value=$id
  Flags=00001010
end"

    foreach file $files {
	set file [file nativename $file]
	set distFile [file nativename [file join $distDir $file]]

	if {[string match "*README" $distFile] \
		|| [string match "*.txt" $distFile]} {
	    # Text files should be converted to crlf format.  Also
	    # the README files should end in .txt
	    set newFile [file nativename [file join crlf-dir $file]]
	    if {[string match "*README" $distFile]} {
		set newFile $newFile.TXT
		set file $file.TXT
	    }
	    file mkdir [file dirname $newFile]
	    convertFile crlf $distFile $newFile
	    set distFile $newFile
	}
	puts $fd "item: Install File
  Source=$distFile
  Destination=%MAINDIR%\\$file
  Flags=0000000010000010
end"
    }
    puts $fd "item: End Block\nend"
    return
}

# genWinImage::openWiseFile --
#
#	Create a new WISE script file and add the standard header
#	to the beginning.
#
# Arguments:
#	name	The name of the script file to create.
#
# Results:
#	The open file descriptor.

proc genWinImage::openWiseFile {name} {
    catch {file delete $name}

    set f [open $name w]
    fconfigure $f -translation crlf

    puts $f {Document Type: WSE
item: Global
  Version=6.01
  Flags=00000100
  Split=1420
  Languages=65 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
  Japanese Font Name=MS Gothic
  Japanese Font Size=10
  Start Gradient=0 0 255
  End Gradient=0 0 0
  Windows Flags=00000100000000010010110000001000
  Message Font=MS Sans Serif
  Font Size=8
  Disk Filename=SETUP
  Patch Flags=0000000000000001
  Patch Threshold=85
  Patch Memory=4000
  FTP Cluster Size=20
  Per-User Version ID=1
  Dialogs Version=6
end}
    return $f
}

# genWinImage::generateInstallers --
#
#	Perform substitutions on the pro.wse.in file and then
#	invoke the WSE script twice; once for CD and once for web.
#
# Arguments:
#	None.
#
# Results:
#	Leaves proweb.exe and procd.exe sitting in the curent directory.

proc genWinImage::generateInstallers {} {
    variable toolsDir

    # Now read the "pro/srcs/install/pro.wse.in" file, have Tcl make
    # appropriate substitutions, write out the resulting file in a
    # current-working-directory.  Use this new file to perform installation
    # image creation.  Note that we have to use this technique to set
    # the value of _WISE_ because wise32 won't use a /d switch for this
    # variable.

    # Do the subst at the global scope so we can share variables with
    # the "eval" statements in the parts list.

    global __WISE__
    set __WISE__ [file native [file join $toolsDir wise]]
    set f [open pro.wse.in r]
    set s [read $f]
    close $f
    set s [uplevel #0 [list subst -nocommands -nobackslashes $s]]
    set f [open __pro__.wse w]
    puts $f $s
    close $f

    set wise32ProgFilePath [file native [file join $__WISE__ wise32.exe]]

    # Run the Wise installer to create the Windows install images.

    puts "Building Web installer"

    if {[catch {exec [file native $wise32ProgFilePath] \
	    /d_VERS_=$projectInfo::prefsLocation \
	    /d_VERSTR_=$projectInfo::directoryName \
	    /d_PATCH_=$projectInfo::patchLevel \
	    /d_WEBONLY_=Yes /c __pro__.wse} errMsg]} {
	puts stderr "ERROR: $errMsg"
    }
    catch {file delete proweb.exe}
    file rename __pro__.exe proweb.exe

    puts "Building CD installer"

    if {[catch {exec [file native $wise32ProgFilePath] \
	    /d_VERS_=$projectInfo::prefsLocation \
	    /d_VERSTR_=$projectInfo::directoryName \
	    /d_PATCH_=$projectInfo::patchLevel \
	    /d_WEBONLY_=No /c __pro__.wse} errMsg]} {
	puts stderr "ERROR: $errMsg"
    }
    catch {file delete procd.exe}
    file rename __pro__.exe procd.exe

    return
}

genWinImage::init
