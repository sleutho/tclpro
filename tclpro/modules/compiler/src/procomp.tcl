# procomp.tcl --
#
#  Front-end script for the TclPro bytecode compiler.
#  Compiles individual TCL scripts, or directories containing TCL scripts.
#  For individual scripts, the output file is either the one specified by the
#  -o flag, or it is created in the same location as the input file, but with
#  a different extension (.tbc). For directories, all files matching a given
#  pattern (which defaults to *.tcl) are compiled; the output files are either
#  placed in the directory specified by the -o flag, or in the same directory
#  as the input files. All output files have the same root as their input file,
#  and different extension.
#
#
# Copyright (c) 1998 by Scriptics Corporation.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: procomp.tcl,v 1.4 2001/02/08 21:40:55 welch Exp $

package require Tcl 8.0
package require compiler 1.0

package provide procomp 1.0

namespace eval procomp {
    namespace export run setLogProc setErrorProc

    # The Log and Error procedures are used to emit output and errors,
    # respectively.

    variable logProc defaultLogProc errorProc defaultErrorProc

    variable fileList {}
    variable headerType auto 
    variable byteCodeExtension .tbc
    variable forceWrite 0

    # This is the tag pattern that is recognized by the 'tag' header type.
    # The tag must appear on a comment line by itself.
    # The tagError variable controls the behaviour of the 'tag' lookup
    # routine; if it is 1, a missing tag trigger an error, if it is 0
    # a missing tag makes the proc return an empty header.

    variable tagValue TclPro::Compiler::Include
    variable tagPattern [format {^[ ]*#[ ]%s[ ]*$} $tagValue]
    variable tagError 0

    variable usage "Usage: [cmdline::getArgv0] ?options? path1 ?path2 ...?
  -force	force overwrite; if the output file exists, delete it.
  -help		print this help message.
  -nologo	suppress copyright banner.
  -out name	specifies that the output path is 'name'.  If only one file
		is being compiled, 'name' may specify the complete output file
		name.  Otherwise 'name' must be the name of an existing
		directory to which all compiled files will be written.
  -prefix type  specifies whether a prefix string should be prepended to the
		emitted output files, and if so how it should be generated
		'type' value can be one of the following:
		  none	do not add a prefix string
		  auto	extract the prefix from the input file: everything
			from the start of the file to the first non-comment
			or empty line is prepended to the output (default)
		  tag	extract the prefix from the input file: everything
			from the start of the file to the first occurrence
			of a comment line starting with the string 
			\"TclPro::Compiler::Include\" is prepended to output
		Any other value for type is assumed to be a path to a
		file that will be used as the output file prefix.
  -quiet	suppress warnings about non-existent files
  -verbose	verbose mode: messages are generated to log progress.
  pathN		one or more files to compile."
}

# procomp::run --
#
#  Runs the package.
#
# Arguments:
#  argList	(optional) the argument list. If not specified, the list is
#		initialized from ::argv.
#
# Results:
#  Returns 1 on success, 0 on failure.

proc procomp::run { {argList {}} } {
    variable fileList

    if {[init $argList] == 0} {
	return 0
    }

    foreach file $fileList {
	if {![fileCompile $file]} {
	    return 0
	}
    }
}

# procomp::setLogProc --
#
#  Sets the log procedure for the package.
#  The log procedure is called by the package when it emits output; it is
#  assumed to take a single argument, the string to log.
#
# Arguments:
#  procName	the name of the log procedure to use
#
# Results:
#  Returns the name of the log procedure that was in use before the call.

proc procomp::setLogProc { procName } {
    variable logProc
    set logProc $procName
}

# procomp::setErrorProc --
#
#  Sets the error log procedure for the package.
#  The error log procedure is called by the package when it emits an error
#  message; it is assumed to take a single argument, the string to log.
#
# Arguments:
#  procName	the name of the log procedure to use
#
# Results:
#  Returns the name of the log procedure that was in use before the call.

proc procomp::setErrorProc { procName } {
    variable errorProc
    set errorProc $procName
}

# procomp::init --
#
#  Initializes the package: checks the arguments, initializes the control
#  structures and checks them for consistency.
#
# Arguments:
#  argList	(optional) the argument list. If not specified, the list is
#		initialized from ::argv.
#
# Results:
#  Returns 1 on success, 0 on failure.

proc procomp::init { {argList {}} } {
    variable headerType
    variable byteCodeExtension [compiler::getBytecodeExtension]
    variable fileList
    variable headerValue
    catch {unset headerValue}
    variable outPath
    catch {unset outPath}
    variable tagValue
    variable logProc
    variable forceWrite
    variable usage

    set quiet 0

    if {[string compare $argList {}] == 0} {
	set argList $::argv
    }

    # if the user has entered nothing on the command line, display the
    # usage string and exit with error

    if {[llength $argList] < 1} {
	log $usage
	return 0
    }

    # initialize the control structures from the argument list: parse the
    # flags

    set optionList {
	? f force h help n nologo o.arg out.arg p.arg prefix.arg
	q quiet v verbose
    }

    set isVerbose 0
    set projectInfo::printCopyright 0
    while {[set err [cmdline::getopt argList $optionList opt arg]]} {
	if {$err < 0} {
	    log "[cmdline::getArgv0]: $arg (use \"-help\" for legal options)"
	    return 0
	} else {
	    switch -exact $opt {
		? -
		h -
		help {
		    log $usage
		    return 1
		}

		f -
		force {
		    set forceWrite 1
		}

		logo {
		    # This will turn on the copyright printing info
		    # when we check out license.

		    set projectInfo::printCopyright 1
		}

		o -
		out {
		    set outPath $arg
		}

		p -
		prefix {
		    set headerType $arg
		}

		q -
		quiet {
		    set quiet 1
		}

		v -
		verbose {
		    set isVerbose 1
		}
	    }
	}
    }

    # After processing args but before we go any futher we check
    # to see if the user has a valid license key.

    projectInfo::printCopyright "TclPro Compiler"

    if {!$isVerbose} {
	set logProc nullLogProc
    }

    # Ensure that the -out option is consistent with the list of files being
    # compiled.  Also ensure that we have at least one file.

    set fileList [cmdline::getfiles $argList $quiet]
    if {[llength $fileList] < 1} {
	logError "no files to compile"
	return 0
    } elseif {([llength $fileList] != 1) && [info exists outPath]} {
	if {![file isdir $outPath]} {
	    logError "-out must specify a directory when compiling more than one file"
	}
    }

    # now check the control structures for internal consistency.
    # First, the header type; if not one of the known types, it must be an
    # existing file.

    switch -- $headerType {
	none -
	auto -
	tag {
	}

	default {
	    if {[catch {open $headerType r} istm] == 1} {
		logError "error: bad header type: $istm"
		return 0
	    }

	    set headerValue [read $istm]
	    close $istm
	    append headerValue [format "# %s\n" $tagValue]
	}
    }

    return 1
}

# procomp::defaultLogProc --
#
#  Default logging procedure: writes $msg to stdout.
#
# Arguments:
#  msg		the message to log.
#
# Results:
#  None.

proc procomp::defaultLogProc { msg } {
    puts stdout $msg
}

# procomp::defaultErrorProc --
#
#  Default error logging procedure: writes $msg to stdout.
#
# Arguments:
#  msg		the error message to log.
#
# Results:
#  None.

proc procomp::defaultErrorProc { msg } {
    puts stdout $msg
}

# procomp::nullLogProc --
#
#  Null logging procedure: does nothing with the argument.
#
# Arguments:
#  msg		the message to log.
#
# Results:
#  None.

proc procomp::nullLogProc { msg } {
}

# procomp::log --
#
#  Logging procedure: calls the current log procedure, passes $msg to it.
#
# Arguments:
#  msg		the message to log.
#
# Results:
#  None.

proc procomp::log { msg } {
    variable logProc
    $logProc $msg
}

# procomp::logError --
#
#  Error logging procedure: calls the current error log procedure, passes
#  "error: $msg" to it.
#
# Arguments:
#  msg		the error message to log.
#
# Results:
#  None.

proc procomp::logError { msg } {
    variable errorProc
    $errorProc "error: $msg"
}

# procomp::fileCompile --
#
#  Compiles a file.
#
# Arguments:
#  path		the path to the file to compile.
#  outputFile	(optional) the output file name; if not specified, determine
#		the output file name from the control structures.
#		This argument is used when fileCompile is called from
#		dirCompile.
#
# Results:
#  Returns 1 on success, 0 on failure.

proc procomp::fileCompile { path {outputFile {}} } {
    variable outPath
    variable byteCodeExtension
    variable headerType
    variable headerValue
    variable forceWrite

    set cmd compiler::compile

    # Get the preamble if any

    if {[catch {
	switch -- $headerType {
	    none {
	    }

	    auto {
		lappend cmd -preamble [getAutoHeader $path]
	    }

	    tag {
		lappend cmd -preamble [getTagHeader $path]
	    }

	    default {
		lappend cmd -preamble $headerValue
	    }
	}
    } err] == 1} {
	logError "compilation of \"$path\" failed: $err"
	return 0
    }

    set outputFile [generateOutFileName $path $outputFile]
    lappend cmd $path $outputFile

    # and finally run the compile

    if {[catch {
	if {$forceWrite == 1} {
	    file delete -force $outputFile
	}
	eval $cmd
    } err] == 1} {
	logError "compilation of \"$path\" failed: $err"
	return 0
    }

    log "compiled: $path to $outputFile"

    return 1
}

# procomp::generateOutFileName --
#
#  Generate an output file name from the input file name and the given output
#  file name. The generated path may be more complete than the one passed in.
#
# Arguments:
#  path		the path to the file to compile.
#  outputFile	(optional) the output file name; if not specified, determine
#		the output file name from the control structures.
#
# Results:
#  Returns the generated path, which may be the same as the value of
#  $outputFile

proc procomp::generateOutFileName { path {outputFile {}} } {
    variable outPath
    variable byteCodeExtension

    set tbcName [file rootname [file tail $path]]$byteCodeExtension

    if {[string compare $outputFile {}] == 0} {
	# if outPath is specified, construct the output file name from it.
	# Otherwise, the output file name is the input file name, with 
	# the .tbc extension.

	if {[info exists outPath] == 1} {
	    if {[file isdirectory $outPath] == 1} {
		set tbcName [file join $outPath $tbcName]
	    } else {
		set tbcName $outPath
	    }
	} else {
	    set tbcName [file join [file dir $path] $tbcName]
	}
    } else {
	# if the given output file is a directory, get the input file name,
	# tag the .tbc extension, and append it to the directory path.
	# If it is a file, or we can't tell, return it as is

	if {[file isdirectory $outputFile] == 1} {
	    set tbcName [file join $outputFile $tbcName]
	} else {
	    set tbcName $outputFile
	}
    }

    return $tbcName
}

# procomp::getAutoHeader --
#
#  Parses a script, extract the 'auto' header from it: all lines from the
#  beginning up to the first non-comment or the first empty line. Here, a line
#  containing only whitespace is considered to be empty.
#
# Arguments:
#  path		the path to the script to parse.
#
# Results:
#  Returns the header; may throw on error.

proc procomp::getAutoHeader { path } {
    variable tagValue

    set istm [open $path r]
    set header {}
    set continuation 0

    while {[gets $istm line] >= 0} {
	if {$continuation == 0} {
	    if {([regexp {^[ ]*#} $line] == 0) \
		    || ([regexp {^[ ]*$} $line] == 1)} {
		break
	    }
	}

	# we need to check if this line is continued on the next one

	if {[regexp {\\$} $line] == 1} {
	    set continuation 1
	} else {
	    set continuation 0
	}

	append header $line "\n"
    }
    close $istm

    append header [format "# %s\n" $tagValue]

    return $header
}

# procomp::getTagHeader --
#
#  Parses a script, extract the 'tag' header from it: all lines from the
#  beginning up to the first occurrence of the TclPro compiler include tag.
#  It is an error to parse a script that is missing the tag.
#
# Arguments:
#  path		the path to the script to parse.
#
# Results:
#  Returns the header; may throw on error.

proc procomp::getTagHeader { path } {
    variable tagPattern
    variable tagValue
    variable tagError

    set istm [open $path r]
    set header {}
    set didSeeTag 0

    while {[gets $istm line] >= 0} {
	if {[regexp $tagPattern $line] == 1} {
	    set didSeeTag 1
	    break
	}

	append header $line "\n"
    }
    close $istm

    if {$didSeeTag == 0} {
	if {$tagError == 0} {
	    return {}
	}
	error "missing header include tag"
    }

    append header [format "# %s\n" $tagValue]

    return $header
}
