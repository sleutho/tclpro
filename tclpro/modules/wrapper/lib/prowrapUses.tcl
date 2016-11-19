# prowrapUses.tcl --
#
#       This file contains all common parts for use by the various
#	.uses scripts.  
#
#	NOTE: These files are for REFERENCE purposes only and any
#	modifications will not change the behavior of TclPro Wrapper.
#	If you wish to make changes to this file, copy it (and any
#	file that sources this file) to different names and create a
#	custom "-uses" specification.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: prowrapUses.tcl,v 1.6 2000/10/31 23:31:19 welch Exp $


namespace eval prowrapUses {
    # As of TclPro 1.1 and beyond, we have removed support for the
    # "load" comand in statically wrapped applications for all platforms.
    # There are too many issues with attempting to load a .dll (Windows)
    # or .so (UNIX) file from much an executable.  TclPro Wrapper however
    # uses the "load" command to its advantage to load packages that are
    # statically compiled, linked, and declared in base applications.

    variable code_for_load_command_in_static_wrapped_app {
	rename load load_unsupported
	proc load {args} {
	    if {[string trim [lindex $args 0]] == {}} {
		eval load_unsupported $args
	    } else {
		# The user is specifying a file name.  Let's first see 
		# if the package is statically bound in already.  Often
		# pkgIndex.tcl scripts get sucked in automatically for
		# things already loaded statically.
		foreach x [info loaded] {
		    set fname [lindex $x 0]
		    set pname [lindex $x 1]
		    if {[string compare -nocase $pname [lindex $args 1]] == 0} {
			return [load_unsupported $fname $pname]
		    }
		}
		error "load: Cannot match [lindex $args 1] with any static package.\n  Try \"load_unsupported\" to load dynamic packages into statically wrapped applications."
	    }
	}
    }


    # TclPro Wrapper looks in a pre-defined location for all library files
    # that contribute to a statically wrapped application.

    variable relTo [file dir [file dir [file dir [info nameofexec]]]]


    # TclPro Wrapper looks in a pre-defined location for all base-applications.

    variable inDir [file join [file dir [file dir [info nameofexec]]] lib]


    # Put all version specific wrap binary names here.  The .uses files
    # use these names to craft the base application names.

    variable WRAP_TCL		wraptclsh83
    variable WRAP_TK		wrapwish83
    variable WRAP_BIG_TCL	wrapbigtclsh83
    variable WRAP_BIG_TK	wrapbigwish83


    # The path below is the location where the "pkgIndex.tcl", for a
    # statically wrapped application, will exist.  This file will
    # contain all the code necessary for loading/initializing the
    # static packages that exist in a statically linked wrapped
    # application.

    variable staticPkgIndexFilePath \
	    [file join $::pro_wrapTempDirectory \
		    {lib/_staticPackage_/pkgIndex.tcl}]


    # 'library_files' is an array indexed by package name and holds
    # a list of files for the respective package.

    variable library_files

    # 'library_code' is an array indexed by package name and holds
    # package specific library initialization code to be wrapped.

    variable library_code

    # 'pkgIndex_script' is an array indexed by package name and holds
    # a fragment of code suitable to be placed in a "pkgIndex.tcl".

    variable pkgIndex_script



    # prowrapUses::listFiles --
    #
    #	This routine recursively lists the files in a directory meant to be wrapped up.
    #
    # Arguments
    #	varName		Name of variable to which to append file names 
    #	dir		Starting directory
    #	dirname		Wrapper-centric name for that directory
    #	skipPat		Directory name pattern to skip, to prune demos, etc.
    #
    # Side Effects
    #	Appends file names to the named variable.

    proc listFiles {varName dir {dirname {}} {skipPat {}}} {
	variable relTo
	upvar 1 $varName files
	if {[string length $dirname] == 0} {
	    set dirname $dir
	}
	foreach f [glob -nocomplain [file join $relTo $dir *]] {
	    if {[string length $skipPat] && [string match $skipPat $f]} {
		continue
	    }
	    if {[file isdirectory $f]} {
		listFiles files $f $dirname/[file tail $f]
	    } else {
		lappend files $dirname/[file tail $f]
	    }
	}
    }

    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tcl.

    listFiles library_files(tcl) lib/tcl8.3

    # TclLib files
    # First figure out the version, then grab everything

    variable dir
    set dir [glob [file join $relTo lib/tcllib*]]
    set dir lib/[file tail $dir]
    listFiles library_files(tcl) $dir

    set library_code(tcl) {
	set tcl_library {lib/tcl8.3}
    }


    # The list of code to be added to the dynamic "pkgIndex.tcl" files
    # for the standard windows extensions.

    if {$tcl_platform(platform) == "windows"} {
	set pkgIndex_script(tcl) {
  	    prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  		package ifneeded dde 1.1 {
  		    load {} Dde
  		}
  		package ifneeded registry 1.0 {
  		    load {} Registry
  		}
  	    }
	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tk.
    # The demos are pruned from the base tk package and listed in their own

    listFiles library_files(tk) lib/tk8.3 {} *lib/tk8.3/demos*
    listFiles library_files(tk_demos) lib/tk8.3/demos

    set library_code(tk) {
	set tk_library {lib/tk8.3}
    }

    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for [incr Tcl].

    listFiles library_files(itcl) lib/itcl3.2
    set pkgIndex_script(itcl) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Itcl 3.2 {
  		namespace eval ::itcl {variable library {lib/itcl3.2}}
  		load {} Itcl
  	    }
  	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for [incr Tk].
    
    listFiles library_files(itk) lib/itk3.2
    listFiles library_files(itk) lib/iwidgets2.2.0 {} *lib/iwidgets2.2.0/demos*
    listFiles library_files(itk) lib/iwidgets3.0.1 {} *lib/iwidgets3.0.1/demos*
    listFiles library_files(itk_demos) lib/iwidgets2.2.0/demos
    listFiles library_files(itk_demos) lib/iwidgets3.0.1/demos
    set pkgIndex_script(itk) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Itk 3.2 {
  		namespace eval ::itk {variable library {lib/itk3.2}}
  		load {} Itk
  	    }
  	}
    }
    
    
    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Expect.

    if {$tcl_platform(platform) == "unix"} {
	set library_files(expect) {
	}
	set pkgIndex_script(expect) {
  	    prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  		set expect_library {}
  		set exp_library {}
  		set exp_exec_library {}
  		package ifneeded Expect 5.32 {
  		    load {} Expect
  		}
  	    }
	}
    } else {
	# Expect doesn't run on windows.  Null these values.

	set library_files(expect) {}
	set pkgIndex_script(expect) {}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tclx.

    listFiles library_files(tclx) lib/tclX8.3 {} *lib/tclX8.3/help*
    listFiles library_files(tclx_help) lib/tclX8.3/help
    set pkgIndex_script(tclx) {
  	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
  	    package ifneeded Tclx 8.3 {
  		set tclx_library {lib/tclX8.3}
  		load {} Tclx
  		foreach __cmd {
  		    abs acos apropos asin assign_fields atan atan2
  		    auto_commands auto_load_file auto_packages buildhelp
  		    ceil cexpand convert_lib convertclock copyfile cos cosh
  		    dirs double edprocs exp fabs floor fmod fmtclock
  		    for_array_keys for_file for_recursive_glob frename
  		    etclock help helpcd helppwd int intersect intersect3
  		    log log10 lrmdups mainloop mkdir popd pow profrep pushd
  		    read_file recursive_glob rmdir round saveprocs searchpath
  		    server_cntl server_connect server_info server_open
  		    server_send showproc sin sinh sqrt tan tanh union unlink
  		    write_file
  		} {
  		    set auto_index($__cmd) {
  			source [file join $tclx_library tcl.tlib]
  		    }
  		}
  		unset __cmd
  	    }
  	}
    }


    # The list of library files, library initialization code, and code
    # to be added to the dynamic "pkgIndex.tcl" file for Tkx.
    
    listFiles library_files(tkx) lib/tkX8.3 {} *lib/tkX8.3/help*
    listFiles library_files(tkx_help) lib/tkX8.3/help
    set pkgIndex_script(tkx) {
	prowrapUses::appendWrappedFile $prowrapUses::staticPkgIndexFilePath {
	    package ifneeded Tkx 8.3 {
		set tkx_library {lib/tkX8.3}
		load {} Tkx
	    }
	}
    }
}

# prowrapUses::appendWrappedFile --
#
#	This routine writes a temporary file given by the fully qualified
#	path 'filePath'.  The appended data is the value of the script
#	literal.
#
# Arguments
#	filePath	the path name of the create file
#	scriptLiteral	the actual contents of the created file
#
# Results
#	Nothing.  The parent directory of the file will be created if it
#	doesn't already exist.  The file will be appended to (created) if
#	it exists (doesn't exist).

proc prowrapUses::appendWrappedFile {filePath scriptLiteral} {
    file mkdir [file dir $filePath]
    set f [open $filePath "a"]
    puts $f $scriptLiteral
    close $f
}


# prowrapUses::prependRelTo --
#
#	This routine returns a modified list with each element of the given
#	list prepended with the first argument.
#
# Arguments
#	relTo		the directory part that should be "pre-pended"
#	libList		a list of files that need pre-pending
#
# Results
#	A list that has each of the original file elements prepended with the
#	'relTo' argument.

proc prowrapUses::prependRelTo {relTo libList} {
    set ret {}
    foreach lib $libList {
	lappend ret [file join $relTo $lib]
    }
    return $ret
}


# prowrapUses::buildCommandLine --
#
#	This routine returns builds a complete command line for the given
#	packages in 'args'.
#
# Arguments
#	baseApp		name of base application for complete package list
#	args		a list of known static package names supported by
#			TclPro Wrapper
#
# Results
#	A list that represents new command line flags and file names that
#	is used by TclPro Wrapper.

proc prowrapUses::buildCommandLine {baseApp args} {
    set commandLine {}

    lappend commandLine \
	    -executable $baseApp \
	    -code $prowrapUses::code_for_load_command_in_static_wrapped_app

    foreach pkg $args {
	if {[info exist prowrapUses::pkgIndex_script($pkg)]} {
	    eval $prowrapUses::pkgIndex_script($pkg)
	}
	if {[info exist prowrapUses::library_code($pkg)]} {
	    lappend commandLine \
		    -code $prowrapUses::library_code($pkg)
	}

	lappend commandLine \
		-relativeto $prowrapUses::relTo
	set commandLine [concat $commandLine \
		[prowrapUses::prependRelTo \
			$prowrapUses::relTo \
			$prowrapUses::library_files($pkg)]]
    }

    if {[file exists [file join $prowrapUses::staticPkgIndexFilePath]]} {
	lappend commandLine \
		-relativeto $::pro_wrapTempDirectory \
			[file join $::pro_wrapTempDirectory \
		    	    	   $prowrapUses::staticPkgIndexFilePath]
    }

    return $commandLine
}

