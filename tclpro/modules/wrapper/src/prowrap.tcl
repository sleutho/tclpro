# prowrap.tcl --
#
#	The main file for the "TclPro Wrapper Utility API"
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: prowrap.tcl,v 1.7 2001/02/08 21:44:30 welch Exp $

namespace eval proWrap {
    # A variable to control whether to eject a usage statement  or not.

    variable printHelpMessage 0

    # The name of the executable used as the wrapping core.

    variable input_executableName ""

    # The name of the wrapped executable.

    variable output_executableName ""

    # The default -uses specification string.

    variable uses_spec "bigwish"

    # The current -relativeto value as the command line is parsed.

    variable relativeto_dir ""

    # This variable indexes the i'th relative directory seen.  We need this
    # to find the first user-specified (not -uses specified) file name on
    # the command line.

    variable i_relativeToDir 0

    # This variable tells which i'th array element in "wrap_specs" begins
    # the users file specifications.

    variable i_user_relativeToDir -1

    # An array that will have an element of "-startup" whose contents will be
    # the value of a startup script file name specified by the user--whether
    # an actual file name or simply, "".  If the user does not either an
    # actual filename or "", the first file name pattern off the command
    # line will be set in this array.

    variable startup_fileName

    # The wrapped application's argument list.

    variable argument_list ""

    # The temporary directory for use during wrapping.

    variable temp_directory ""

    # The array of "wrap" specifications indexed by the ith relativeto directory
    # and the -relativeto directory name itself.

    variable wrap_specs

    # In the array above, how many specs come directly from a user (as opposed
    # to those that are contributed by the -uses flag).
 
    variable n_user_wrap_specs 0

    # The array of "wrap" specifications indexed by the the fully-qualified
    # -relativeto directory and each array element consisting of a list of
    # fully-qualified file names.

    variable wrap_specs_resolved

    # The following list holds "code" fragments that are to be placed into
    # the initialization script file for a wrapped application.

    variable code_fragments {}

    # 'wrapped_tcl_pkgPath' contains wrapped directories that each have either
    # a "tclIndex" or "pkgIndex.tcl" file.  This path is appended to the
    # "tcl_pkgIndex" variable as part of the code fragments placed into the
    # initialization script file for the wrapped application.

    variable wrapped_tcl_pkgPath {}

    # Debug hack

    variable debug 0

    # A flag to control verbose output during the wrapping process.

    variable verbose_flag 0

    # The argument to the "-binarypatch" flag initially of the form "arg1,arg2".

    variable binary_patch ""

    # The directory to use for the Tcl library and encoding files, -tcllibrary
    # flag

    variable tcllibrary "lib/tcl8.2"

    # The set of error messages that may be encountered during the application.

    variable msgStrings
    
    append msgStrings(0_USAGE_STATEMENT) \
	    "Usage: [cmdline::getArgv0] ?options? ?fileNamePatterns? "\
	    	"?options? fileNamePatterns ...\n" \
	    "  -help                    print this help message\n" \
	    "  -nologo                  suppress copyright banner\n" \
	    "  -verbose                 produce detailed output during wrapping\n" \
	    "  -uses usesSpecification  specify a predefined flag set\n" \
	    "  -startup initialScript   declare starting script filename\n" \
	    "  -arguments arguments     specify additional arguments to application\n" \
	    "  -executable fileName     name of input executable\n" \
	    "  -relativeto directory    specify a relative directory for files that follow\n" \
	    "  -tcllibrary directory    specify location of Tcl library (and encoding) files\n" \
	    "  -code script             interpreter initialization script\n" \
	    "  -out fileName            name of output file (default: prowrapout?.exe?)\n" \
	    "  -temp directory          specify an alternate temp. directory\n" \
	    "  -@                       collect more command line args from stdin"
    array set msgStrings {
	0_USE_HELP_FOR_MORE_INFO
	    "(use \"-help\" for legal options)"
	1_NO_STARTUP_FILE_SPECIFIED
	    "no startup file specified"
	2_MALFORMED_STDIN_ARGS
	    "malformed arguments string from standard input"

	10_UNABLE_TO_LOCATE_USES_FILE
	    "-uses file \"%s\" could not be found in %s"
	12_ERR_SOURCING_USES_FILE
	    "error sourcing uses file \"%s\": %s"
	13_SOURCING_USES_FILE_RET_NOTHING
	    "sourcing uses file \"%s\" returned nothing"

	41_EXECUTABLE_SAME_AS_OUTPUT
	    "-executable \"%s\" is the same as -out \"%s\""
	42_MISSING_EXECUTABLE_FLAG
	    "-executable is a required flag"
	43_EXECUTABLE_DOES_NOT_EXIST
	    "-executable \"%s\" does not exist"
	44_INVALID_INPUT_EXECUTABLE
	    "input executable \"%s\" does not contain wrapper extensions"
	45_FATAL_ERROR
	    "fatal error accessing \"%s\": %s"

	90_STARTUPSCRIPT_NOT_WRAPPED
	    "-startup \"%s\", but no such file wrapped"

	100_RELATIVE_DOES_NOT_EXIST
	    "-relativeto directory \"%s\" does not exist or may be a file"
	101_NO_MATCHING_FILES
	    "no files matching pattern \"%s\""
	102_RELATIVE_TO
	    " relative to \"%s\""
	103_FILE_MULTIPLE_DIRS
	    "file \"%s\" specified from multiple directories:\n"
	104_CWD
	    "<current working directory>"
	105_RELATIVETO_MISMATCH
	    "-relativeto directory \"%s\" and file name pattern \"%s\" mismatch"

	110_UNABLE_TO_DETERMINE_TEMPDIR
	    "unable to determine temporary directory"
	111_UNABLE_TO_DESTROY_TEMPDIR
	    "unable to destroy temporary directory"
	112_UNABLE_TO_CREATE_TEMPDIR
	    "unable to create suitable temporary directory"
	113_UNABLE_TO_DETERMINE_TEMPDIR
	    "unable to determine a temporary directory; use -temp flag"
	114_TEMPORARY_DIR_NOEXIST
	    "temporary directory does not exist"
	115_TEMPDIRNAME_DOES_NOT_EXIST
	    "temporary directory \"%s\" does not exist"

	150_CREATING_INITSCRIPTINFOFILE
	    "Creating wrapper information file:\n"
	158_WRAPPER_INFORMATION
	    "    Startup file: \"%s\"\n    Arguments: \"%s\"\n    Base application: \"%s\""
	151_CREATING_APPINITSCRIPTFILE
	    "Creating application initialization script file."
	152_WRAPPING_CONTROL_FILES
	    "Wrapping information files:"
	153_WRAPPING_FILES
	    "Wrapping file(s):"
	154_CREATING_OUTEXEC
	    "Creating output executable:\n    %s"
	157_NOT_COMPRESSING_PATTERNS
	    "    Not compressing patterns: %s\n"
	156_RELATIVE_TO
	    "    Relative to: %s\n"
	155_FILENAME_PATTERNS
	    "    File names:"

	200_UNSUPPORTED_PLATFORM
	    "unsupported platform"
    }

    # The pre-defined name of a wrapped application's Tcl init. script filename.
    # The value of this variable is retrieved directly from the base application.

    variable proWrapInitFileName ""

    # The pre-defined name of a file in the wrapped application that contains
    # the name of the "-startup <scriptFileName>" and "-arguments <args>" lines.
    # The value of this variable is retrieved directly from the base application.

    variable proWrapScriptInfoFileName ""
}


# proWrap::processCommandLine --
#
#	This is the main procedure for processing the 'prowrap' command line.
#
# Arguments
#	'argv' is the list of command line arguments as provided by the shell.
#
# Results
#	Upon completion of this routine, the command line will have been pro-
#	cessed and all flag associated variables in the namespace are
#	initialized with the respective command line arguments.  If an error
#	occurs during processing of flags and arguments, an exception is
#	raised and a list of error strings is returned.

proc proWrap::processCommandLine {argc argv {processingUses 0}} {
    # Induce a "-help" if command line was empty.

    if {$argc == 0} {
	set proWrap::printHelpMessage 1
	error {}
    }

    # Pass over the command line arguments for existance of "-@".  If such a
    # flag exists, get additional command line arguments from stdin and put
    # them at the end of the command line list.  At the same time look for
    # "-help" and "-nologo"; if we see "-help", quickly bail; if we see
    # "-nologo" silence the copyright routine right away.  Also parse out
    # the "-t?emp?" flag.

    set newArgv {}
    set projectInfo::printCopyright 0
    set optionList {? h help n nologo debug t.arg temp.arg @}
    while {[llength $argv]} {
	set err [cmdline::getopt argv $optionList opt arg]
	if {$err == 1} {
	    switch -exact -- $opt {
		? -
		h -
		help {
		    set proWrap::printHelpMessage 1
		    return;
		}
		debug {
		    set proWrap::debug 1
		}
	    	logo {
	    	    # This will turn on printing the banner on start up.

		    set projectInfo::printCopyright 1
		}
		t -
		temp {
		    set proWrap::temp_directory $arg
		}
		@ {
		    set getFromStdin 1
		}
	    }
	} else {
	    lappend newArgv [lindex $argv 0]
	    set argv [lrange $argv 1 end]
	}
    }
    if {[info exists getFromStdin]} {
	set stdinArgString [read stdin]
	if {$stdinArgString != ""} {
	    set newArgv [concat $newArgv [parseArgs $stdinArgString]]
	}
    }
    set argv $newArgv
    set argc [llength $newArgv]

    # Now create the temporary directory; this would either be in the default
    # location or the one specified and parsed above via the "-t?emp?" flag.
    # This created temporary directory needs to later be removed in the outer
    # most script (in "startup.tcl").

    if {[catch {proWrap::tempDirectory create} error]} {
	error $error
    }

    # Now process in arguments from any -uses specifications and put those
    # arguments at the begining of the command line list.  Only the last
    # occurance of a -uses flag will be honored as per design spec.

    set newArgv {}
    set optionList {u.arg uses.arg}
    while {[llength $argv]} {
	set err [cmdline::getopt argv $optionList opt arg]
	if {$err == 1} {
	    set proWrap::uses_spec $arg
	} else {
	    lappend newArgv [lindex $argv 0]
	    set argv [lrange $argv 1 end]
	}
    }
    set usesArgv {}
    if {[string length $proWrap::uses_spec]} {
	if {[catch {processUsesSpec $proWrap::uses_spec} usesArgv]} {
	    error [list $usesArgv]
	}
    }
    set newArgv [concat \
	    $usesArgv -endOfUsesSpec_startCountineUsersFiles $newArgv]
    set argv $newArgv
    set argc [llength $newArgv]

    # Parse the remaining for flags and arguments on the command line.  Stop
    # parsing when an error is encountered.

    set optionList {? h help
		    n nologo
		    v verbose
		    s.arg startup.arg
    		    u.arg uses.arg
		    r.arg relativeto.arg
		    e.arg executable.arg
		    tcllibrary.arg
    		    o.arg out.arg
		    a.arg arguments.arg
		    c.arg code.arg
		    endOfUsesSpec_startCountineUsersFiles
		    @}

    set processingUses 1

    while {[llength $argv]} {
	set err [cmdline::getopt argv $optionList opt arg]
	if {$err == 0} {
	    lappend proWrap::wrap_specs([list \
		    $proWrap::i_relativeToDir $proWrap::relativeto_dir]) \
			[lindex $argv 0]
	    if {!$processingUses} {
		if {$proWrap::i_user_relativeToDir == -1} {
		    set proWrap::i_user_relativeToDir $proWrap::i_relativeToDir
		}
	        incr proWrap::n_user_wrap_specs
	    }
	    set argv [lrange $argv 1 end]
	} elseif {$err < 0} {
       	    error [list "[cmdline::getArgv0]: $opt $proWrap::msgStrings(0_USE_HELP_FOR_MORE_INFO)"]
        } else {
	    switch -exact -- $opt {
		endOfUsesSpec_startCountineUsersFiles {
		    set processingUses 0
		}
		a -
		arguments {
		    set proWrap::argument_list $arg
	    	}
	    	s -
	    	startup {
	    	    set proWrap::startup_fileName(-startup) $arg
	    	}
	    	u -
	    	uses {
		    # set proWrap::uses_spec $arg
	    	}
	    	r -
	    	relativeto {
		    incr proWrap::i_relativeToDir
	    	    set proWrap::relativeto_dir [file nativename $arg]
	    	}
	    	e -
	    	executable {
	    	    set proWrap::input_executableName [file nativename $arg]
	    	}
		tcllibrary {
		    set proWrap::tcllibrary [file nativename $arg]
		}
		o -
		out {
		    set proWrap::output_executableName [file nativename $arg]
		}
		c -
		code {
		    lappend proWrap::code_fragments $arg
		}
		v -
		verbose {
		    set proWrap::verbose_flag 1
		}
		? -
		h -
		help -
		nologo -
		@ -
		t -
		temp {
		    # Ignore these flags at this point so as not to produce an
		    # annoying error message.  (This may happen if some clever
		    # user includes these in a -uses specification.
		}
	    }
	}
    }
}


# proWrap::processUsesSpec --
#
#	Process in the arguments associated with a single "-uses" argument.
#
# Arguments
#	arg	A string that represents a "-uses" argument.
#
# Results
#	An exception is raised if the specified "uses" argument could not be
#	processed.

proc proWrap::processUsesSpec {arg} {
    set fileFound 0
    set err 0

    set usesExt "uses"

    # If it does not have an absolute path, find the file, "$arg.uses" in the
    # following locations:
    #	. the built-in (wrapped) directory, "wrapper/lib/$arg.uses"
    #	. in the "lib/prowrap" directory (relative to the TclPro <plat>/bin dir.)
    #	. <current-working-directory> (from which "prowrap" was invoked)

    if {[file pathtype $arg] == "absolute"} {
	lappend usesFileList $arg
	set builtInBeingUsed 0
    } else {
	lappend usesFileList [file join wrapper lib $arg]
	lappend usesFileList [file join \
		[file dirname [file dirname [file dirname [info nameofexec]]]] \
    	        lib prowrapuses $arg]
	lappend usesFileList [file join [pwd] $arg]
	set builtInBeingUsed 1
    }

    foreach usesFile $usesFileList {
	if {[file exists $usesFile]} {
	    set fileFound 1
	    break
	}
	if {[file exists $usesFile.$usesExt]} {
	    append usesFile .$usesExt
	    set fileFound 1
	    break
	}
	set builtInBeingUsed 0
    }

    # Darn, didn't find the file.  Too bad!

    if {!$fileFound} {
	set dirsString ""
	foreach usesFileName [lrange $usesFileList 1 end] {
	    append dirsString "\"[file dir $usesFileName]\" "
	}
	append string [format \
		"$proWrap::msgStrings(10_UNABLE_TO_LOCATE_USES_FILE)" \
		$arg.$usesExt $dirsString]
	error $string
    }

    # If the built-in .uses files are not being used, change to the directory
    # where the .uses file was located.

    if {!$builtInBeingUsed} {
	set saveDir [pwd]
	cd [file dir $usesFile]
    }

    # Create an interp. in which to evaluate the contents of the located .uses
    # file.  The result of the evaluation will return additions to the prowrap
    # command line.

    set usesInterp [interp create]
    set err [catch {
	interp eval $usesInterp [list \
	    set ::pro_wrapTempDirectory [proWrap::tempDirectory get] \
	]
    	interp eval $usesInterp [list source $usesFile]
    } usesCmdLine]
    interp delete $usesInterp

    # If it was changed, restore the working-directory.

    if {!$builtInBeingUsed} {
	cd $saveDir
    }

    # If the evaluation actually succeeded and returned something, process the
    # returned command line.

    if {$err} {
	set err 1
	set error $usesCmdLine
	set error [format $proWrap::msgStrings(12_ERR_SOURCING_USES_FILE) \
		$usesFile $error]
    } else {
    	if {[llength $usesCmdLine]} {
	    lappend usesCmdLine -relativeto ""
	} else {
	    set err 1
	    set error [format \
		    $proWrap::msgStrings(13_SOURCING_USES_FILE_RET_NOTHING) \
		    $usesFile]
	}
    }

    if {$err} {
    	error $error
    }
    return $usesCmdLine
}


# ::fileSearchString --
#
#	This routine performs a listeral search in the file "fileName" for
#	the pattern "searchString" beginning at offset "startingOffset".  The
#	search string can be any valid string, including a binary string,
#	supported by Tcl.
#
# Arguments
#	None.
#
# Results
#	Returns the offset where the search string was found in the file or
#	-1 if such a pattern was not located.

proc ::fileSearchString {fileName searchString {startingOffset 0}} {
    set fileChan [open $fileName r]
    fconfigure $fileChan -translation binary -buffersize 4096 -buffering full
    seek $fileChan $startingOffset start
    set searchStringFoundAt \
	    [string first $searchString [read $fileChan [file size $fileName]]]
    close $fileChan

    return $searchStringFoundAt
}


# proWrap::validateFlags --
#
#	This routine performs some sanity checks on all the variables in the
#	namespace to ensure the processing will go as error-free as posible.
#
# Arguments
#	None.
#
# Results
#	An exceoption is raised with a list of errors.

proc proWrap::validateFlags {} {
    set errors {}

    # Check for a minimum set of arguments and if not, eject a usage statement.

    if {!$proWrap::n_user_wrap_specs
	    && ![info exists proWrap::startup_fileName(-startup)]} {
	lappend errors $proWrap::msgStrings(1_NO_STARTUP_FILE_SPECIFIED)
	error $errors
    }

    # Sort the 'proWrap::wrap_specs' array based on the 'ith_relativeToDir'
    # index of each array element.  This ensures that the foreach loop
    # below will see files in the ordered specified on the command line.

    set wrap_specs_arrayNamesOrdered \
	    [lsort -integer -index 0 [array names proWrap::wrap_specs]]

    # Process each -relativeto directory in the array of wrap specifications.

    foreach wrap_spec_arrayElement $wrap_specs_arrayNamesOrdered {
	set wrap_arrayIndex [lindex $wrap_spec_arrayElement 0]
	set wrap_relativetoDir [lindex $wrap_spec_arrayElement 1]

	# Resolve the specified -relativetoDir.to its absolute path.

	if {[string length $wrap_relativetoDir] == 0} {

	    # Avoid weird windows bug that gives me :/TEMP when I join the
	    # the empty string to [pwd]

	    set wrap_relativetoDir_resolved [pwd]
	} else {
	    set wrap_relativetoDir_resolved [file join [pwd] $wrap_relativetoDir]
	}

	# On windows you can pass in a native pathname with \ from the
	# command line - here we map those to / so we can string match

	if {$proWrap::debug} {
	    puts [list pwd [pwd]]
	    puts [list relativeto $wrap_relativetoDir [file pathtype $wrap_relativetoDir] $wrap_relativetoDir_resolved]
	}

	if {![file isdir $wrap_relativetoDir_resolved]} {
	    set string ""
	    append string \
	    	    [format $proWrap::msgStrings(100_RELATIVE_DOES_NOT_EXIST) \
			    $wrap_relativetoDir]
	    lappend errors $string
	} else {
	    set wrap_spec_index [list $wrap_arrayIndex $wrap_relativetoDir]

	    # Process each file pattern for the -relativeto directory currently
	    # being processed.

	    regsub -all {\\} $wrap_relativetoDir / wrap_relativetoDir
	    foreach wrap_fileNamePattern $proWrap::wrap_specs($wrap_spec_index) {
		regsub -all {\\} $wrap_fileNamePattern / wrap_fileNamePattern
		if {[string length $wrap_relativetoDir]
			&& ([string first $wrap_relativetoDir \
				$wrap_fileNamePattern] != 0)} {
		    # The leading portion of the given file spec. does not
		    # contain the -relativeto directory currently being
		    # processed.  Emit an error.

		    lappend errors [format \
		    	    $proWrap::msgStrings(105_RELATIVETO_MISMATCH) \
			    $wrap_relativetoDir \
			    $wrap_fileNamePattern]
		} elseif {[file isdir $wrap_fileNamePattern] == 1} {
		    # Don't bother wrapping directory elements that appear on
		    # the command line.  Directories that exist within file
		    # path specifications will be created elsewhere.
		} else {
		    # Resolve the file spec. which may include a glob spec.

		    set filesToWrap \
			    [proWrap::getfiles [list $wrap_fileNamePattern] 1]

		    if {![llength $filesToWrap]} {
			# The given file spec. resolved to no files in the
			# file-system.  Emit an error.

		        set string ""
		        append string [format \
		        	$proWrap::msgStrings(101_NO_MATCHING_FILES) \
		        	$wrap_fileNamePattern]
		        if {[string length $wrap_relativetoDir]} {
		            append string [format \
				    $proWrap::msgStrings(102_RELATIVE_TO) \
				    $wrap_relativetoDir]
			} else {
		            append string [format \
				    $proWrap::msgStrings(102_RELATIVE_TO) \
				    $proWrap::msgStrings(104_CWD)]
			}
			lappend errors $string
		    } else {
		        foreach fileName $filesToWrap {
			    # Create a version of the file name that does not
			    # contain the "relative to" part of the path.

			    set fileEntry [stripLeading \
			    	    $wrap_relativetoDir_resolved $fileName]

			    # If the file "pkgIndex.tcl" (checked case-
			    # insensitively for the sake of Windows), then add
			    # the wrapped directory path to a list.   The
			    # ultimate directory list will be the effective
			    # value of 'tcl_pkgPath" varuable for the wrapped
			    # application.  (As per Defect ID# 974, we longer
			    # add directories with "tclIndex" files to the
			    # "auto_path.)

			    if {[string match pkgindex.tcl [string tolower \
					[file tail $fileEntry]]]} {
			        lappend proWrap::wrapped_tcl_pkgPath \
					[file dir $fileEntry]
			    }

			    # Add the resolved file name to the list of files
			    # against the current -relativetoDir being
			    # processed.

			    lappend proWrap::wrap_specs_resolved($wrap_relativetoDir_resolved) \
				    $fileName

			    # If an entry for the resolved file does not
			    # already exist in "$fileNameArray", create one.
			    # Associated with each file name entry is a list of
			    # _distinct_ -relativeto directories against which
			    # that file has been specified.

			    set dirEntry [list $wrap_relativetoDir \
				    $wrap_relativetoDir_resolved]

			    if {[info exists fileNameArray($fileEntry)]} {
			        if {[lsearch $fileNameArray($fileEntry) \
					$dirEntry] == -1} {
				    lappend fileNameArray($fileEntry) $dirEntry
				}
			    } else {
				lappend fileNameArray($fileEntry) $dirEntry
			    }

			    # If 'proWrap::startup_fileName(-startup) has not
			    # been set (either by user or here previously),
			    # then $fileName must be the first file name on
			    # the 'prowrap' command line, in which case it
			    # becomes the startup script file.  Set it now.

			    if {($proWrap::i_user_relativeToDir == 
				    $wrap_arrayIndex) 
				&& ![info exists proWrap::startup_fileName(-startup)]} {
				set proWrap::startup_fileName(-startup) \
					$fileEntry
			    }
			}
		    }
		}
	    }
	}
    }

    # Add the collected path of "proWrap::wrapped_tcl_pkgPath" to the code
    # fragments.

    if {[llength $proWrap::wrapped_tcl_pkgPath]} {
	set codeFrag [format "    set tcl_pkgPath {%s}\n" \
		$proWrap::wrapped_tcl_pkgPath]
	lappend proWrap::code_fragments $codeFrag
    }

    # Set up a file name list called "specialFileList" that consists of
    # files implicitly required by the "-startup".

    if {[info exists proWrap::startup_fileName(-startup)]
	    && [string length $proWrap::startup_fileName(-startup)]} {
	set startup_file [file join $proWrap::startup_fileName(-startup)]
	set spelialFilesArray($startup_file) \
	    [format $proWrap::msgStrings(90_STARTUPSCRIPT_NOT_WRAPPED) \
		    $proWrap::startup_fileName(-startup)]
    }

    # Check for file name collision specifications by seeing if multiple,
    # but different, -relativto directories were specified for the same
    # file path.  Also check for existance of "special files".

    foreach fileName [array names fileNameArray] {
	set relativetoDirInfoList $fileNameArray($fileName)

	if {[llength $relativetoDirInfoList] > 1} {
	    set string ""
	    append string [format \
	    	    $proWrap::msgStrings(103_FILE_MULTIPLE_DIRS) \
		    $fileName]
	    foreach relativetoDirInfo $relativetoDirInfoList {
	        set relativetoDir [lindex $relativetoDirInfo 0]
		if {![string length $relativetoDir]} {
	            append string "  $proWrap::msgStrings(104_CWD)"
		} else {
		    append string "  \"$relativetoDir\""
		}
	        set relativetoDir_resolved [lindex $relativetoDirInfo 1]
	        append string " (\"$relativetoDir_resolved\")\n"
	    }
	    lappend errors $string
	}

	if {[lsearch -exact \
		[array names spelialFilesArray] \
	        [file join $fileName] ] != -1} {
	    unset spelialFilesArray([file join $fileName])
	}
    }

    # If any "special files" were not located in the wrapped set of files,
    # the array "$spelialFilesArray" will still be populated with elements.
    # Generate errors for them now.

    foreach specialFile [array names spelialFilesArray] {
	lappend errors $spelialFilesArray($specialFile)
    }

    # If no output executable name was selected, take on the default.

    if {[string length $proWrap::output_executableName] == 0} {
        set proWrap::output_executableName "prowrapout"
    }

    # On Windows, append a ".exe" extension if one does not already exist.
    # (Defect ID #462)

    if {$::tcl_platform(platform) == "windows"} {
	if {[string match "*.exe" "$proWrap::output_executableName"] == 0} {
	    append proWrap::output_executableName ".exe"
	}
    }

    # Check that the -executable flag was specified.  If it was, check that
    # the it exists.  If it exists, check to be sure it is not the same name
    # as the output executable (wrapping in place is not currently supported).

    if {![string length $proWrap::input_executableName]} {
	lappend errors $proWrap::msgStrings(42_MISSING_EXECUTABLE_FLAG)
    } elseif {![file isfile $proWrap::input_executableName]} {
	lappend errors \
		[format $proWrap::msgStrings(43_EXECUTABLE_DOES_NOT_EXIST) \
			$proWrap::input_executableName]
    } elseif {$proWrap::input_executableName == $proWrap::output_executableName} {
	lappend errors \
		[format $proWrap::msgStrings(41_EXECUTABLE_SAME_AS_OUTPUT) \
			$proWrap::input_executableName \
			$proWrap::output_executableName]
    } elseif {[catch {
	# Check that the input executable contains a wrap core.  Search
	# the given executable to ensure it contains the wrapper C API
	# AND retrieve the names of the wrap control files names and
	# store in variables variables:
	#     proWrap::proWrapInitFileName &&
	#     proWrap::proWrapScriptInfoFileName

	set searchString1 "wrapInitFileName:"
	set searchString2 "wrapScriptInfoFileName:"
	if {([set offset1 [::fileSearchString \
		$proWrap::input_executableName $searchString1]] != -1) \
		&& ([set offset2 [::fileSearchString \
		$proWrap::input_executableName $searchString2]] != -1)} {

	    set inFile [open $proWrap::input_executableName r]
	    fconfigure $inFile -encoding binary -translation binary

	    # Looking for "wrapInitFileName:<filename>:\u0000"
	    # pull out the <filename> portion

	    seek $inFile $offset1 start
            set buf [read $inFile 128]
 	    regexp :(\[^\u0000\]*):\u0000 $buf dummy \
		    proWrap::proWrapInitFileName

	    # Looking for "wrapScriptInfoFileName:<filename>:\u0000"
	    # pull out the <filename> portion

	    seek $inFile $offset2 start
            set buf [read $inFile 128]
	    regexp :(\[^\u0000\]*):\u0000 $buf dummy \
		    proWrap::proWrapScriptInfoFileName

	    close $inFile
	}
	if {($offset1 == -1)
		|| ($offset2 == -1)
		|| ([string length $proWrap::proWrapInitFileName] == 0)
		|| ([string length $proWrap::proWrapScriptInfoFileName] == 0)} {
	    lappend errors \
		    [format $proWrap::msgStrings(44_INVALID_INPUT_EXECUTABLE) \
			    $proWrap::input_executableName]
	}
    } error]} {
	lappend errors \
		[format $proWrap::msgStrings(45_FATAL_ERROR) \
			$proWrap::input_executableName \
			$error]
    }

    # Check that the specified temporary directory exists.

    if {[string length $proWrap::temp_directory] 
	    && ![file isdir $proWrap::temp_directory]} {
	lappend errors [format $proWrap::msgStrings(115_TEMPDIRNAME_DOES_NOT_EXIST) \
			       $proWrap::temp_directory]
    }

    # Throw an exception if at least one error was caught.

    if {[llength $errors]} {
	error $errors
    }
}


# proWrap::tempDirectory --
#
#	Creates, deletes, or retrieves the name of a temporary directory for
#	the utility to use.  The name of the temporary directory is derived
#	from the prefix "WRAPTMP" concatenated with the process-id.  This
#	directory will either be created in the directory specified by the
#	variable "proWrap::temp_directory" or a directory defined by the
#	environment variables: TEMP, TMP, TMPDIR, temp, tmp, tmpdir, Temp,
#	Tmp, Tmpdir.
#
# Arguments
#	command		one of the words "create", "delete", or "get"
#
# Results
#	For a command of "create" or "get" will return the full path of the
#	temporary directory.  If a temporary directory cannot be create or
#	determined, an exception is raised.  For command of "delete", returns
#	nothing but an exception may be raised if the deletion fails.

proc proWrap::tempDirectory {command} {
    global env
    global tcl_platform

    set proWrapTempDirName "WRAPTMP[pid]"

    switch -exact -- $command {
	create {
	    # Determine the temporary directory

	    if {$proWrap::temp_directory == ""} {
		# The user did not specifiy a temporary directory.
		# Let the system select one.

		if {$tcl_platform(platform) == "unix"} {
		    set env(_prowraptmp_) "/tmp"
		}

		foreach elem {TEMP TMP TMPDIR
			      temp tmp tmpdir Temp Tmp Tmpdir _prowraptmp_} {
		    if {[info exists env($elem)] && [file isdir $env($elem)]} {
			set proWrap::temp_directory $env($elem)
			break;
		    }
		}
	    }

	    if {$proWrap::temp_directory == ""} {
		error "$proWrap::msgStrings(113_UNABLE_TO_DETERMINE_TEMPDIR)"
	    } elseif {![file isdir $proWrap::temp_directory]} {
		error [format $proWrap::msgStrings(115_TEMPDIRNAME_DOES_NOT_EXIST) \
			$proWrap::temp_directory]
	    } else {
		set tempDir [file join $proWrap::temp_directory $proWrapTempDirName]
		if {[catch {file mkdir $tempDir} error]} {
		    error "$proWrap::msgStrings(112_UNABLE_TO_CREATE_TEMPDIR): $error"
		}
		# 'tempDir' now set.
	    }
	}
	delete {
	    if {[info exists proWrap::temp_directory]
		    && [file isdir $proWrap::temp_directory]} {
		set tempDir [file join $proWrap::temp_directory $proWrapTempDirName]
		if {[catch {file delete -force $tempDir} error]} {
		    error "$proWrap::msgStrings(111_UNABLE_TO_DESTROY_TEMPDIR): $error"
		}
	    }
	    return
	    # Returns nothing!
	}
	get {
	    if {[info exists proWrap::temp_directory]
		    && [file isdir $proWrap::temp_directory]} {
		set tempDir [file join $proWrap::temp_directory $proWrapTempDirName]
	    } else {
		error $proWrap::msgStrings(110_UNABLE_TO_DETERMINE_TEMPDIR)
	    }
	    # 'tempDir' now set.
	}
	default {
	    error "unknown 'tempDirectory' command: $command"
	}
    }

    # Resolve '$tempDir' to an absolute path in case it is a relative path.

    set tempDir [file join [pwd] $tempDir]
    return $tempDir
}

# proWrap::getfiles --
#
#	Given a list of file arguments from the command line, compute
#	the set of valid files.  On windows, file globbing is performed
#	on each argument.  On Unix, only file existence is tested.  If
#	a file argument produces no valid files, a warning is optionally
#	generated.
#
#	This code also uses the full path for each file.  If not
#	given it prepends [pwd] to the filename.  This ensures that
#	these files will never comflict with files in our zip file.
#
# Arguments:
#	patterns	The file patterns specified by the user.
#	quiet		If this flag is set, no warnings will be generated.
#
# Results:
#	Returns the list of files that match the input patterns.

proc proWrap::getfiles {patterns quiet} {
    set result {}
    if {$::tcl_platform(platform) == "windows"} {
	foreach pattern $patterns {
	    regsub -all {\\} $pattern {\\\\} pat
	    set files [glob -nocomplain -- $pat]
	    if {$files == {}} {
		if {! $quiet} {
		    puts stdout "warning: no files match \"$pattern\""
		}
	    } else {
		foreach file $files {
		    lappend result $file
		}
	    }
	}
    } else {
	set result $patterns
    }
    set files {}
    foreach file $result {
	# Make file an absolute path so that we will never conflict
	# with files that might be contained in our zip file.

	set fullPath [file nativename [file join [pwd] $file]]
	
	if {[file isfile $fullPath]} {
	    lappend files $fullPath
	} elseif {! $quiet} {
	    puts stdout "warning: no files match \"$file\""
	}
    }
    return $files
}

# proWrap::createTaskList --
#
#	At this point, the complete set of operational variables in the
#	'proWrap' namesapce should completely valid and ready to be processed.
#	The temporary directory is also assumed to be created and ready for use.
#
# Arguments
#	tasksVar	a variable name that will be set to a list of tasks
#			of the form:
#			    {{task-description-string	script-to-evaluate}
#			     {task-description-string	script-to-evaluate}
#			     ... }
#
# Results
#	Nothing.

proc proWrap::createTaskList {tasksVar} {
    upvar $tasksVar tasks
    global tcl_platform

    set tasks {}

    # Determine the program path for the Zip command.

    switch -exact -- $tcl_platform(platform) {
	windows {
	    set zipProg [file join [file dir [info nameofexec]] pwutil10.exe]
	}
	unix {
	    set zipProg [file join [file dir [info nameofexec]] pwutil10]
	}						 
	default {
	    error "$proWrap::msgStrings(200_UNSUPPORTED_PLATFORM) $tcl_platform(platform)"
	}
    }

    # For the first task, create the file named by '$proWrapScriptInfoFileName'.

    if {[info exists proWrap::startup_fileName(-startup)]
	    && [string length $proWrap::startup_fileName(-startup)]} {
	set startupFileName $proWrap::startup_fileName(-startup)
    } else {
	set startupFileName ""
    }
    set wrapperInfo [format $proWrap::msgStrings(158_WRAPPER_INFORMATION) \
	    $startupFileName $proWrap::argument_list \
	    $proWrap::input_executableName]
    lappend tasks [list \
	    [format "%s%s" \
		    $proWrap::msgStrings(150_CREATING_INITSCRIPTINFOFILE) \
		    $wrapperInfo] \
	    proWrap::createWrapScriptInfoFile \
    ]

    # Next task: create the file named by '$proWrapInitFileName'.

    lappend tasks [list \
	    $proWrap::msgStrings(151_CREATING_APPINITSCRIPTFILE) \
	    proWrap::createWrapInitFile \
    ]

    # Create one task to wrap up the above two files.

    lappend tasks [list \
	    [format "%s\n    %s\n    %s" \
		    $proWrap::msgStrings(152_WRAPPING_CONTROL_FILES) \
		    $proWrap::proWrapInitFileName \
		    $proWrap::proWrapScriptInfoFileName] \
	    [list proWrap::wrapControlFiles $zipProg] \
    ]

    # For each "wrap" specification, create a task that invokes the zip
    # program with the apprpriate flag specifications, including.

    foreach wrap_relativetoDir_resolved [array names proWrap::wrap_specs_resolved] {
	set string ""
	append string "$proWrap::msgStrings(153_WRAPPING_FILES)\n"
	if {[string length $wrap_relativetoDir_resolved]} {
	    append string [format \
		    $proWrap::msgStrings(156_RELATIVE_TO) \
	    	    $wrap_relativetoDir_resolved]
	}
	append string "$proWrap::msgStrings(155_FILENAME_PATTERNS)"
	foreach wrap_fileName $proWrap::wrap_specs_resolved($wrap_relativetoDir_resolved) {
	    append string "\n        $wrap_fileName"
	}
	lappend tasks [list \
		$string \
		[list proWrap::doTheWrap \
			$wrap_relativetoDir_resolved \
			$proWrap::wrap_specs_resolved($wrap_relativetoDir_resolved) \
			$zipProg] \
	    ]
    }

    # Create the output executable as the final task.

    lappend tasks [list \
	[format $proWrap::msgStrings(154_CREATING_OUTEXEC) \
		$proWrap::output_executableName] \
	proWrap::createOutputExecutable \
    ]
}


# proWrap::wrapControlFiles --
#
#	This proc performs the necessary zip command to wrap up the "control"
#	files; i.e. the files named by $proWrap::proWrapInitFileName &&
#	$proWrap::proWrapScriptInfoFileName.
#
# Arguments
#	None.
#
# Returns
#	Nothing

proc proWrap::wrapControlFiles {zipProg} {
    upvar wrapZipFileName wrapZipFileName
    upvar proWrapTempDirName proWrapTempDirName

    lappend execCmd "exec" "$zipProg" "-j" "-m"
    if {!$proWrap::verbose_flag} {
	lappend execCmd "-q"
    }
    lappend execCmd "$wrapZipFileName" \
	"[file join $proWrapTempDirName $proWrap::proWrapInitFileName]" \
	"[file join $proWrapTempDirName $proWrap::proWrapScriptInfoFileName]"

    eval $execCmd
}


# proWrap::createWrapInitFile --
#
#	Create the file named by '$proWrapInitFileName'.  The contents of
#	this file is a script that (later may include other things) sets up
#	the varaibels necessary for locating the wrapped system of Tcl &
#	Tk libraries; this information comes from the "-code" flags that
#	were collected when the command line was processed.
#
# Arguments
#	None.
#
# Returns
#	Nothing

proc proWrap::createWrapInitFile {} {
    upvar proWrapTempDirName proWrapTempDirName

    set proWrapInitFileName \
	    [file join $proWrapTempDirName $proWrap::proWrapInitFileName]

    set f [open $proWrapInitFileName w]

    # This "fconfigure" ensures that the written file is identical on
    # UNIX and Windows.

    fconfigure $f -translation {binary binary}

    puts $f "# $proWrap::proWrapInitFileName"
    puts $f "#     TclPro Wrapper initialization script"
    puts $f "set tcl_platform(isWrapped) 1"
    foreach codeFragment $proWrap::code_fragments {
	puts $f $codeFragment
    }

    close $f
}


# proWrap::createWrapScriptInfoFile --
#
#	Create the file named by '$proWrapScriptInfoFileName'.  The contents
#	of this file is the value of given by the "-startup" and '-arguments'
#	flags.
#
# Arguments
#	None.
#
# Returns
#	Nothing.

proc proWrap::createWrapScriptInfoFile {} {
    upvar proWrapTempDirName proWrapTempDirName

    set proWrapScriptInfoFileName \
	    [file join $proWrapTempDirName \
		       $proWrap::proWrapScriptInfoFileName]

    set f [open $proWrapScriptInfoFileName w]

    # This "fconfigure" ensures that the written file is identical on
    # UNIX and Windows.

    fconfigure $f -translation {binary binary}

    # Write out the name of the -startup script file name, if specified.

    puts -nonewline $f "-startup "
    if {[info exists proWrap::startup_fileName(-startup)]
	    && [string length $proWrap::startup_fileName(-startup)]} {
	puts -nonewline $f "$proWrap::startup_fileName(-startup)"
    }
    puts $f ""

    # Write out the value of the -arguments flag, if specified.

    puts -nonewline $f "-arguments "
    if {[string length $proWrap::argument_list]} {
	puts -nonewline $f "$proWrap::argument_list"
    }
    puts $f ""

    # Write out the tcllibrary flag
    
    puts $f "-tcllibrary $proWrap::tcllibrary"

    # Write out the encoding flag
    
    puts $f "-encoding [encoding system]"

    close $f
}


# proWrap::doTheWrap --
#
#	Create the file named by '$proWrapScriptInfoFileName'.  The contents
#	of this file is the string '$arguments'.  The "fconfigure" below ensures
#	that the written files are identical on UNIX and Windows.
#
# Arguments
#	None.
#
# Returns
#	Nothing.

proc proWrap::doTheWrap {wrap_relativetoDir
			 wrap_fileNamePatterns
			 zipProg} {
    upvar wrapFileListFileName wrapFileListFileName
    upvar wrapZipFileName wrapZipFileName

    # Write out the file name pattern list and use the file as a
    # standard-input redirect for the zip command.

    set zipListFile [open $wrapFileListFileName w]
    foreach fileEntry $wrap_fileNamePatterns {
	# Strip off the leading "relativeto" directory pattern from the
	# file name pattern.

	set fileEntry [stripLeading $wrap_relativetoDir $fileEntry]

        # Zip documentation says that any file name with embaedded space
        # characters needs to have single quote marks around it.  So for
	# safety sake, put a pair of single quote marks around every file.

        puts $zipListFile "'$fileEntry'"
    }
    close $zipListFile

    # Construct a zip-command that will wrap-up (zip-up) the specified files,
    # and applying any specified no-compression suffix option.

    lappend execCmd "exec" "$zipProg"
    if {!$proWrap::verbose_flag} {
	lappend execCmd "-q"
    }
    lappend execCmd "$wrapZipFileName" "-@" "<" "$wrapFileListFileName"

    # Change to the "-relatvieto" directory.

    set saveDir [pwd]
    cd $wrap_relativetoDir

    set error [catch $execCmd errMsg]

    # Restore the previous working directory if it was changed.

    cd $saveDir
    unset saveDir

    if {$error} {
	error $errMsg
    }
}


# proWrap::createOutputExecutable --
#
#	Create the executable named by "$proWrap::output_executableName" based
#	on the name "$proWrap::input_executableName".  Mark the output file as
#	executable on UNIX so it can immediately be run.
#
# Arguments
#	None.
#
# Results
#	Nothing.

proc proWrap::createOutputExecutable {} {
    upvar wrapZipFileName wrapZipFileName

    global tcl_platform

    # Copy over the input exec. to the output exec.

    file copy -force -- \
    	    $proWrap::input_executableName $proWrap::output_executableName

    # Ensure the output file is marked with r/w & exec. mode on UNIX.

    if {$tcl_platform(platform) == "unix"} {
	file attrib $proWrap::output_executableName -permissions 0777
    } elseif {$tcl_platform(platform) == "windows"} {
	file attrib $proWrap::output_executableName -readonly 0
    }

    # Open the output exec with append mode.

    set outFile [open $proWrap::output_executableName a]
    fconfigure $outFile -translation binary

    # Slam the zip file onto the end of the output exec.

    set zipFile [open $wrapZipFileName r]
    fconfigure $zipFile -translatio binary
    fcopy $zipFile $outFile
    close $zipFile
    
    close $outFile
}



# proWrap::processTaskList --
#
#	This routine will first create the temporary directory, the temporary
#	zip file where the wrapped application is targeted,  Each task given
#	by the variable name 'tasksVar' is processed one by one, while extra
#	information is produced if the verbose flag ('proWrap::verbose_flag')
#	is set.  Then the temporary directory is removed unconditionally.
#
# Arguments
#	tasksVar	the variable name for a list of tasks produced by a
#			call to 'proWrap::createTaskList'.
#
# Results
#	Returns nothing.  Task processing stops and an exceoption is raised
#	if any task in the list fails to evaluate to completion.

proc proWrap::processTaskList {tasksVar} {
    upvar $tasksVar tasks

    if {![catch {proWrap::tempDirectory get} error]} {
        set proWrapTempDirName [proWrap::tempDirectory get]
	set wrapZipFileName [file join $proWrapTempDirName WRAPTMP[pid].zip]
	set wrapFileListFileName [file join $proWrapTempDirName WRAPTMP[pid].lst]

        if {$proWrap::verbose_flag} {
	    rename exec exec_orig
	    proc exec {args} {
		if {$proWrap::verbose_flag} {
		    #puts -nonewline "\n    exec $args"
		    #flush stdout
		}
		set retval [uplevel exec_orig $args]
		if {$proWrap::verbose_flag} {
		    #puts -nonewline "\n$retval"
		    #flush stdout
		}
	    }
	}
	if {![catch {
	    foreach task $tasks {
		if {$proWrap::verbose_flag} {
		    puts -nonewline [lindex $task 0]
		    flush stdout
		}
		eval [lindex $task 1]
		if {$proWrap::verbose_flag} {
		    puts "\n"
		    flush stdout
		}
	    }
	} error]} {
	    unset error
	}
    }

    if {[info exists error]} {
	if {$proWrap::verbose_flag} {
	    puts "\n"
	    flush stdout
	}
	error [list $error]
    }
}


# stripLeading --
#
#	Given the arguments, 'dirPath' and 'filePath', this routine stripts
#	off from 'filePath' those leading elements from both paths.
#
# Arguments
#	dirPath		a directory path
#	filePath	a file path that may contain a lead 'dirPath' pattern
#
# Results
#	A file path is returned.

proc stripLeading {dirPath filePath} {
    set dirPath [file split $dirPath]
    set filePath [file split $filePath]

    for {set i 0} {$i < [llength $dirPath]} {incr i} {
	if {[lindex $dirPath $i] != [lindex $filePath $i]} {
	    break;
	}
    }
    if {$i == [llength $dirPath]} {
	# The list for 'dirPath' was exhausted, therefore 'dirPath' is truly
	# a complete leading subset of 'filePath'.

	set filePath [lrange $filePath $i end]
    }
    if {[llength $filePath] == 0} {
	return ""
    }
    return [eval file join $filePath]
}

# parseArgs --
#
#	Parse command line arguments from a string using Windows
#	quoting syntax.
#
# Arguments:
#	cmdLine		The string to parse.
#
# Results:
#	Returns a list containing the command line arguments.

proc parseArgs {cmdLine} {
    set result {}
    set i 0

    # This complicated routine implements the Windows quoting convention:
    #
    # 2N backslashes + quote -> N backslashes + begin quoted string
    # 2N + 1 backslashes + quote -> N backslashes + literal quote
    # N backslashes + non-quote -> N backslashes + non-quote
    # quote + quote in a quoted string -> single quote
    # quote + quote not in quoted string -> empty string
    # quote -> begin quoted string

    set cmdLine [string trim $cmdLine]
    while {$cmdLine != ""} {
	set arg ""
	set slashes {}
	set inquote 0
	while {$cmdLine != ""} {
	    regexp {^(\\*)(\"?)(.*)} $cmdLine match slashes \
		    quote1 cmdLine
	    if {$quote1 != ""} {
		append arg [string range $slashes 0 \
			[expr {([string length $slashes]>>1)-1}]]
		if {([string length $slashes] & 1) == 0} {
		    if {$inquote && [string index $cmdLine 0] == "\""} {
			append arg \"
			set cmdLine [string range $cmdLine 1 end]
		    } else {
			set inquote [expr {!$inquote}]
		    }
		} else {
		    append arg \"
		}
	    } else {
		append arg $slashes
	    }
	    if {!$inquote && [regexp {^[\n\t ]} $cmdLine]} {
		break
	    }
	    if {$inquote} {
		regexp {^([^\\\"]*)(.*)} $cmdLine match word cmdLine
	    } else {
		regexp {^([^\\\"\n\t ]*)(.*)} $cmdLine match word cmdLine
	    }
	    append arg $word
	}
	set cmdLine [string trim $cmdLine]
	lappend result $arg
    }
    return $result
}
 
