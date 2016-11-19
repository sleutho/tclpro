# tclX.tcl --
#
#	This file contains type and command checkers for the TclX
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: tclX.tcl,v 1.3 2000/10/31 23:30:54 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide tclX 1.0

namespace eval tclX {
    # scanCmdsX.X --
    # Define the set of commands that need to be recuresed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds8.0 {
	commandloop-TPC-SCAN		1		
	for_array_keys-TPC-SCAN		1		
	for_recursive_glob-TPC-SCAN	1		
	loop-TPC-SCAN			1		
	try_eval-TPC-SCAN		1		
	cmdtrace-TPC-SCAN		1		
	signal-TPC-SCAN			1		
	for_file-TPC-SCAN		1		

    }

    # checkersX.X --
    # Define the set of command-specific checkers used by this package.

    variable checkers8.0 {
	dirs			{checkSimpleArgs 0 0 {}}
	commandloop		{checkSwitches 1 {
				    -async 
				    {-endcommand checkBody}
				    {-prompt1	 checkBody}
				    {-prompt2	 checkBody}
				    {-interactive tclX::checkTtyOrBoolean}
				} {}}
	echo			{checkSimpleArgs 0 -1 checkWord}
	infox			{checkSimpleArgs 1  1 {{checkOption {
	    {version		{checkSimpleArgs 0 0 {}}}
	    {patchlevel		{checkSimpleArgs 0 0 {}}}
	    {have_chown		{checkSimpleArgs 0 0 {}}}
	    {have_fchmod	{checkSimpleArgs 0 0 {}}}
	    {have_fchown	{checkSimpleArgs 0 0 {}}}
	    {have_flock		{checkSimpleArgs 0 0 {}}}
	    {have_fsync		{checkSimpleArgs 0 0 {}}}
	    {have_ftruncate	{checkSimpleArgs 0 0 {}}}
	    {have_msgcats	{checkSimpleArgs 0 0 {}}}
	    {have_posix_signals	{checkSimpleArgs 0 0 {}}}
	    {have_signal_restart	{checkSimpleArgs 0 0 {}}}
	    {have_symlink	{checkSimpleArgs 0 0 {}}}
	    {have_truncate	{checkSimpleArgs 0 0 {}}}
	    {have_waitpid	{checkSimpleArgs 0 0 {}}}
	    {appname		{checkSimpleArgs 0 0 {}}}
	    {applongname	{checkSimpleArgs 0 0 {}}}
	    {appversion		{checkSimpleArgs 0 0 {}}}
	    {apppatchlevel	{checkSimpleArgs 0 0 {}}}
	} {}}}}
	for_array_keys		{checkSimpleArgs 3 3 {
				    checkVarName checkVarName checkBody
				}}
	for_recursive_glob	{checkSimpleArgs 4 4 {
				    checkVarName checkList checkList checkBody
				}}
	loop			{checkNumArgs {
				    {4	{checkSimpleArgs 4 4 {
					checkVarName 
					checkInt 
					checkInt 
					checkBody
				    }}}
				    {5	{checkSimpleArgs 5 5 {
					checkVarName 
					checkInt 
					checkInt 
					checkInt 
					checkBody
				    }}}
				}}
	popd			{checkSimpleArgs 0 0 {}}
	pushd			{checkSimpleArgs 0 1 {checkFileName}}
	recursive_glob		{checkSimpleArgs 2 2 {checkList}}
	showproc		{checkSimpleArgs 0 -1 {checkWord}}
	try_eval		{checkSimpleArgs 2 3 {checkBody}}


	cmdtrace		{checkSimpleArgs 1 -1 {{checkOption {
	    {off		{checkSimpleArgs 0 0 {}}}
	    {depth		{checkSimpleArgs 0 0 {}}}
	    {on			{tclX::checkCmdTraceOnCmd}}
	} {tclX::checkCmdTraceLevelCmd}}}}
	edprocs			{checkSimpleArgs 0 -1 {checkWord}}
	profile			{tclX::checkProfileCmd}
	profrep			{checkSimpleArgs 2 4 {
				    checkVarName 
				    {checkKeyword 1 {calls cpu real}}
				    checkFileName
				    checkWord
				}}
	saveprocs		{checkSimpleArgs 1 -1 {
				    checkFileName checkWord
				}}

	
	alarm			{checkSimpleArgs 1 1 {checkInt}}
	execl			{checkSwitches 1 {
				    {-argv0 checkWord}
				} {checkSimpleArgs 1 -1 checkWord}}
	chroot			{checkSimpleArgs 1 1 {checkFileName}}
	fork			{::analyzer::warn nonPortCmd {} {checkSimpleArgs 0 0 {}}}
	id			{checkSimpleArgs 1 -1 {{checkOption {
	    {convert		{checkSimpleArgs 1 -1 {{checkOption {
		{group		{checkSimpleArgs 1 1 {checkWord}}}
		{groupid	{checkSimpleArgs 1 1 {checkWord}}}
		{user		{checkSimpleArgs 1 1 {checkWord}}}
		{userid		{checkSimpleArgs 1 1 {checkWord}}}
	    } {checkSimpleArgs 0 0 {}}}}}}
	    {effective		{checkSimpleArgs 1 -1 {{checkOption {
		{group		{checkSimpleArgs 0 0 {}}}
		{groupid	{checkSimpleArgs 0 0 {}}}
		{groupids	{checkSimpleArgs 0 0 {}}}
		{user		{checkSimpleArgs 0 0 {}}}
		{userid		{checkSimpleArgs 0 0 {}}}
	    } {checkSimpleArgs 0 0 {}}}}}}
	    {group		{checkSimpleArgs 0 1 {checkWord}}}
	    {groupid		{checkSimpleArgs 0 1 {checkWord}}}
	    {groupids		{checkSimpleArgs 0 0 {checkWord}}}
	    {groups		{checkSimpleArgs 0 0 {checkWord}}}
	    {host		{checkSimpleArgs 0 0 {checkWord}}}
	    {process		{checkSimpleArgs 0 -1 {{checkOption {
		{group		{checkSimpleArgs 0 -1 {{checkOption {
		    {set	{checkSimpleArgs 0 0 {}}}
		} {checkSimpleArgs 0 0 {}}}}}}
		{parent		{checkSimpleArgs 0 0 {}}}
	    } {checkSimpleArgs 0 0 {}}}}}}
	    {user		{checkSimpleArgs 0 1 {checkWord}}}
	    {userid		{checkSimpleArgs 0 1 {checkWord}}}
	} {checkSimpleArgs 0 0 {}}}}}
	kill			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -pgroup
				} {checkSimpleArgs 1 2 {checkWord checkList}}}}
	link			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -sym
				} {checkSimpleArgs 2 2 {checkFileName}}}}
	nice			{::analyzer::warn nonPortCmd {} {
				    checkSimpleArgs 0 1 {checkInt}}
				}
	readdir			{checkSwitches 1 {
				    -hidden
				} {checkSimpleArgs 1 1 {checkFileName}}}
	signal			{checkSwitches 1 {
				    -restart
				} {checkSimpleArgs 2 3 {
				    {checkKeyword 1 \
					    {default ignore error trap get \
					    set block unblock *}
				    }
				    checkList
				    checkBody
				}}}
	sleep			{checkSimpleArgs 1  1 {checkInt}}
	system			{checkSimpleArgs 1 -1 {checkWord}}
	sync			{checkSimpleArgs 0  1 {checkChannelID}}
	times			{checkSimpleArgs 0  0 {}}
	umask			{checkSimpleArgs 0  1 {checkInt}}
	wait			{checkSwitches 1 {
				    -nohang -untraced -pgroup
				} {checkSimpleArgs 0 1 {checkInt}}}


	bsearch			{checkSimpleArgs 2 4 {
				    checkChannelID checkWord
				}}
	chmod			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -fileid
				} {checkSimpleArgs 1 2 {checkWord checkList}}}}
	chown			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -fileid
				} {checkSimpleArgs 1 -1 {
				    checkList
				    checkWord
				}}}}
	chgrp			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -fileid
				} {checkSimpleArgs 1 2 {checkWord checkList}}}}
	dup			{checkSimpleArgs 1 2 {checkChannelID}}
	fcntl			{::analyzer::warn warnDeprecated fconfigure {
				    checkSimpleArgs 2 3 {
				        checkChannelID checkWord
				    }
				}}
	flock			{::analyzer::warn nonPortCmd {} {checkSwitches 1 {
				    -read -write -nowait
				} {checkSimpleArgs 1 4 {
				    checkChannelID
				    checkInt
				    checkInt
				    {checkKeyword 1 {start current end}}
				}}}}
	for_file		{checkSimpleArgs 3 3 {
				    checkVarName checkFileName checkBody
				}}
	funlock			{::analyzer::warn nonPortCmd {} {checkSimpleArgs 1 4 {
				    checkChannelID
				    checkInt
				    checkInt
				    {checkKeyword 1 {start current end}}
				}}}
	fstat			{checkSimpleArgs 1 -1 {
				    checkChannelID 
	{checkOption {
	    {stat		{checkSimpleArgs 1 1 {checkVarName}}}
	} {checkSimpleArgs 1 1 {{checkOption {
	    {atime		{checkSimpleArgs 0 0 {}}}
	    {ctime		{checkSimpleArgs 0 0 {}}}
	    {dev		{checkSimpleArgs 0 0 {}}}
	    {gid		{checkSimpleArgs 0 0 {}}}
	    {ino		{checkSimpleArgs 0 0 {}}}
	    {mode		{checkSimpleArgs 0 0 {}}}
	    {mtime		{checkSimpleArgs 0 0 {}}}
	    {nlink		{checkSimpleArgs 0 0 {}}}
	    {size		{checkSimpleArgs 0 0 {}}}
	    {tty		{checkSimpleArgs 0 0 {}}}
	    {type		{checkSimpleArgs 0 0 {}}}
	    {uid		{checkSimpleArgs 0 0 {}}}
	    {remotehost		{checkSimpleArgs 0 0 {}}}
	    {localhost		{checkSimpleArgs 0 0 {}}}
	} {}}}}}}}
	ftruncate		{checkSwitches 1 {
				    {-fileid {::analyzer::warn nonPortCmd {} {
					checkSwitchArg {} 0 0 {}
				    }}}
				} {checkSimpleArgs 2 2 {checkWord checkInt}}}
	lgets			{checkSimpleArgs 1 2 {
				    checkChannelID checkVarName
				}}
	pipe			{checkSimpleArgs 0 2 {checkChannelID}}
	read_file		{tclX::checkReadFileCmd}
	select			{checkSimpleArgs 1 4 {
				    checkList checkList checkList checkFloat
				}}
	write_file		{checkSimpleArgs 1 -1 {
				    checkFileName checkWord
				}}



	host_info		{checkSimpleArgs 2 2 {{checkOption {
	    {addresses		{checkSimpleArgs 1 1 {checkWord}}}
	    {official_name	{checkSimpleArgs 1 1 {checkWord}}}
	    {aliases		{checkSimpleArgs 1 1 {checkWord}}}
	} {}}}}



	scancontext		{checkSimpleArgs 1 3 {{checkOption {
	    {create		{checkSimpleArgs 0 0 {}}}
	    {delete		{checkSimpleArgs 1 1 {checkWord}}}
	    {copyfile		{checkSimpleArgs 1 2 {checkWord}}}
	} {}}}}
	scanfile		{checkSwitches 1 {
				    {-copyfile checkChannelID}
				} {checkSimpleArgs 2 2 {
				    checkWord checkChannelID
				}}}
	scanmatch		{checkSwitches 1 {
				    -nocase
				} {checkNumArgs {
				    {2	{checkSimpleArgs 2 2 {checkWord}}}
				    {3	{checkSimpleArgs 3 3 {
					checkWord checkPattern checkWord
				    }}}
				}}}

	abs			{checkSimpleArgs 1  1 {checkFloat}}
	acos			{checkSimpleArgs 1  1 {checkFloat}}
	asin			{checkSimpleArgs 1  1 {checkFloat}}
	atan 			{checkSimpleArgs 1  1 {checkFloat}}
	atan2			{checkSimpleArgs 1  1 {checkFloat}}
	ceil			{checkSimpleArgs 1  1 {checkFloat}}
	cos			{checkSimpleArgs 1  1 {checkFloat}}
	cosh			{checkSimpleArgs 1  1 {checkFloat}}
	double			{checkSimpleArgs 1  1 {checkFloat}}
	floor 			{checkSimpleArgs 1  1 {checkFloat}}
	fmod			{checkSimpleArgs 2  2 {checkFloat}}
	int			{checkSimpleArgs 1  1 {checkFloat}}
	log10			{checkSimpleArgs 1  1 {checkFloat}}
	log			{checkSimpleArgs 1  1 {checkFloat}}
	max			{checkSimpleArgs 1 -1 {checkFloat}}
	min			{checkSimpleArgs 1 -1 {checkFloat}}
	pow			{checkSimpleArgs 2  2 {checkFloat}}
	random			{checkSimpleArgs 1 2 {{checkOption {
	    {seed		    {checkSimpleArgs 0 1 {checkInt}}}
	} {checkSimpleArgs 1 1 {checkInt}}}}}
	round			{checkSimpleArgs 1  1 {checkFloat}}
	sin			{checkSimpleArgs 1  1 {checkFloat}}
	sinh			{checkSimpleArgs 1  1 {checkFloat}}
	sqrt			{checkSimpleArgs 1  1 {checkFloat}}
	tan			{checkSimpleArgs 1  1 {checkFloat}}
	tanh			{checkSimpleArgs 1  1 {checkFloat}}
	


	intersect		{checkSimpleArgs 2  2 {checkList}}
	intersect3		{checkSimpleArgs 2  2 {checkList}}
	lassign			{checkSimpleArgs 2 -1 {checkList checkWord}}
	lcontain		{checkSimpleArgs 2  2 {checkList checkWord}}
	lempty			{checkSimpleArgs 1  1 {checkList}}
	lmatch			{checkSwitches 1 {
				    -exact -glob -regexp
				} {checkSimpleArgs 2  2 {
				    checkList checkPattern
				}}}
	lrmdups			{checkSimpleArgs 1  1 {checkList}}
	lvarcat			{checkSimpleArgs 2 -1 {checkVarName checkWord}}
	lvarpop			{checkSimpleArgs 1  3 {
				    checkVarName tclX::checkLIndex checkWord
				}}
	lvarpush		{checkSimpleArgs 2  3 {
				    checkVarName checkWord tclX::checkLIndex
				}}
	union			{checkSimpleArgs 2  2 {checkList}}



	keyldel			{checkSimpleArgs 2  2 {checkVarName checkWord}}
	keylget			{checkSimpleArgs 1  3 {
				    checkVarName checkWord checkVarName
				}}
	keylkeys		{checkSimpleArgs 1  2 {checkVarName checkWord}}
	keylset			{checkSimpleArgs 3 -1 {
				    checkVarName 
				    {tclX::checkPair 1 checkWord checkWord}
				}}


	ccollate		{checkSwitches 1 {
				    -local
				} {checkSimpleArgs 2  2 {checkWord}}}
	cconcat			{checkSimpleArgs 0 -1 {checkWord}}
	cequal			{checkSimpleArgs 2  2 {checkWord}}
	cindex			{checkSimpleArgs 2  2 {
				    checkWord tclX::checkLIndex
				}}
	clength			{checkSimpleArgs 1  1 {checkWord}}
	crange			{checkSimpleArgs 3  3 {
				    checkWord tclX::checkLIndex
				}}
	csubstr			{checkSimpleArgs 3  3 {
				    checkWord tclX::checkLIndex
				}}
	ctoken 			{checkSimpleArgs 2  2 {checkVarName checkWord}}
	ctype			{checkOption {
				    {char  {checkSimpleArgs 1 1 checkByteNum}}
				    {ord   {checkSimpleArgs 1 1 checkWord}}
				} {checkSwitches 1 {
				    {-failindex checkVarName}
				} {checkSimpleArgs 2 2 {
				    {checkKeyword 1 \
					    {alnum alpha ascii cntrl digit \
					    graph lower space print punct \
					    upper xdigit}
				    }
				    checkWord
				}}}}
	replicate		{checkSimpleArgs 2  2 {checkWord checkInt}}
	translit		{checkSimpleArgs 3  3 {checkWord}}

	
	
	catopen			{checkSimpleArgs 1 2 {{checkSwitches 1 {
				    -fail -nofail
				} {checkSimpleArgs 1  1 {checkWord}}}}}
	catgets			{checkSimpleArgs 4  4 {
				    checkWord checkInt checkInt checkWord
				}}
	catclose		{checkSimpleArgs 1 2 {{checkSwitches 1 {
				    -fail -nofail
				} {checkSimpleArgs 1  1 {checkWord}}}}}


	mainloop		{checkSimpleArgs 0  0 {}}


	auto_commands		{checkSwitches 1 {
				    -loaders
				} {checkSimpleArgs 0 0 {}}}
	buildpackageindex	{checkSimpleArgs 1 1 {checkList}}
	convert_lib		{checkSimpleArgs 2 3 {
				    checkFileName checkFileName checkList
				}}
	loadlibindex		{checkSimpleArgs 1 1 {tclX::checkTlibSuffix}}
	auto_packages		{checkSwitches 1 {
				    -locations
				} {checkSimpleArgs 0  0 {}}}
	auto_load_file		{checkSimpleArgs 1 1 {checkWord}}
	searchpath		{checkSimpleArgs 2 2 {checkFileName checkWord}}
    }

    variable checkers8.1 {
    }

    variable checkers8.2 {
    }

    # messages --
    # Define the set of message types and their human-readable translations. 

    variable messages
    array set messages {
	tclX::badProfileOpt  {"option \"%1$s\" not valid when turning off profiling" err}
	tclX::optionRequired {"expected %1$s, got \"%2$s\"" err}
	tclX::badLIndex      {"invalid index: should be integer, \"len\" or \"end\"" err}
	tclX::badTlibFile    {"the filename must have a \".tlib\" suffix" err}

    }
}

# tclX::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc tclX::init {ver} {
    foreach name [lsort [info vars ::tclX::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::tclX::scanCmds$ver"} {
	    break
	}
    }
    foreach name [lsort [info vars ::tclX::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::tclX::checkers$ver"} {
	    break
	}
    }
    return
}

# tclX::getMessage --
#
#	Convert the message type into a human readable
#	string.  
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the message string or empty string if the
#	message type is undefined.

proc tclX::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# tclX::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc tclX::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# tclX::checkPair --
#
#	Check the next pair of command arguments.  This checker is
#	useful when there is a required sequence of word1 word2 
#	pairs.  An error is flagged if word1 exists, but word2 
#	does not.
#
# Arguments:
#	atLeastOne	Boolean, indicating if there is a minumun
#			of one pair required.
#	cmd1		The type checker for the first word.
#	cmd2		The type checker for the second word.
#	tokens		The list of word tokens after the initial
#			command and subcommand names
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the list of message type keywords.

proc tclX::checkPair {atLeastOne cmd1 cmd2 tokens index} {
    set oneFound 0
    set argc [llength $tokens]
    while {$index < $argc} {
	set index [$cmd1 $tokens $index]
	if {$index < $argc} {
	    set index [$cmd2 $tokens $index]
	} else {
	    logError numArgs {}
	}
	set oneFound 1
    }
    if {$atLeastOne && !$oneFound} {
	logError numArgs {}
    }
    return $index
}

# Checkers for specific commands --
#
#	Each checker is passed the tokens for the arguments to 
#	the command.  The name of each checker should be of the
#	form tclX::check<Name>Cmd, where <name> is the command
# 	being checked.
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.


proc tclX::checkTtyOrBoolean {tokens index} {
    # Used by the commandloop command, this checks to see if the word 
    # is a literal "tty" value or a valid boolean value.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {$literal == "tty"} {
	    incr index
	} else {
	    set index [checkBoolean $tokens $index]
	}
    } else {
	set index [checkWord $tokens $index]
    }
    return $index
}

proc tclX::checkCmdTraceOnCmd {tokens index} {
    # Check the various options for the "cmdtrace on" subcommand.

    set file 0
    set cmd  0
    set err  {}
    set argc [llength $tokens]
    while {$index < $argc} {
	if {![getLiteral [lindex $tokens $index] arg]} {
	    incr index
	    continue
	}

	switch -glob -- $arg {
	    notruncate -
	    noeval -
	    procs {
		incr index
	    }
	    std* -
	    file* {
		set file 1
		set err  $index
		incr index
		set index \
			[checkSwitchArg $arg 1 1 checkChannelID $tokens $index]
	    }
	    command {
		set cmd 1
		set err $index
		incr index
		set index [checkSwitchArg $arg 1 1 checkBody $tokens $index]
	    }
	    default {
		set range [getTokenRange [lindex $tokens $index]]
		logError badOption $range \
			{notruncate, noeval, procs, filed or command} $arg
		incr index
	    }
	}
    }
    
    if {($file && $cmd)} {
	set range [getTokenRange [lindex $tokens $err]]
	logError mismatchOptions $range
    }

    return $index
}

proc tclX::checkCmdTraceLevelCmd {tokens index} {
    # Check the "cmdtrace" command.  This is called if none of the
    # sub commands matched.  If there is one token left, then this
    # should be an integer value for the level.  Otherwise, this
    # should be logged as an unknown option.

    set argc [llength $tokens]
    if {![getLiteral [lindex $tokens $index] arg]} {
	return [checkCommand $tokens $index]
    }

    set remaining [expr {$argc - $index}]
    if {$remaining == 1} {
	checkInt $tokens $index
	incr index
    } else {
	set range [getTokenRange [lindex $tokens $index]]
	logError badOption $range \
		{notruncate, noeval, procs, filed or command} $arg
	set index [checkCommand $tokens $index]
    }
    return $index
}

proc tclX::checkProfileCmd {tokens index} {
    # Check the various options for the "profile" command.

    set onOpt {}
    set on    0
    set off   0
    set var   0

    set argc [llength $tokens]
    if {$index >= $argc} {
	logError numArgs {}
	return $index
    }

    while {$index < $argc} {
	if {![getLiteral [lindex $tokens $index] arg]} {
	    incr index
	    set var 1
	    continue
	}

	switch -glob -- $arg {
	    -commands -
	    -eval {
		set onOpt $arg
		set index \
			[checkSwitchArg $arg 1 1 checkChannelID $tokens $index]
	    }
	    on {
		set on 1
		incr index
		break
	    }
	    off {
		set off 1
		set index \
			[checkSwitchArg $arg 1 1 checkVarName $tokens $index]
		break
	    }
	    default {
		set range [getTokenRange [lindex $tokens $index]]
		logError badOption $range {commands eval on off} $arg
		incr index
	    }
	}
    }
    
    # Verify at least "on" or "off" was specified.  If a non-literal 
    # was encountered, give the benefit of the doubt and assume that
    # it will be OK.  

    if {!($on) && !($off) && !($var)} {
	set range [getTokenRange [lindex $tokens $index]]
	logError tclX::optionRequired $range {"on" or "off"} $arg
    } elseif {$off && ($onOpt != {})} {
	logError tclX::badProfileOpt {} $onOpt
    }

    set remaining [expr {$argc - $index}]
    if {$on && ($remaining > 0)} {
	logError numArgs {}
	set index [checkCommand $tokens $index]
    } elseif {$off} {
	if {$remaining == 1} {
	    set index [checkVarName $tokens $index]
	} else {
	    logError numArgs {}
	    set index [checkCommand $tokens $index]
	}
    } elseif {$remaining > 0} {
	set index [checkCommand $tokens $index]
    }
    return $index
}

proc tclX::checkReadFileCmd {tokens index} {
    # Check the various options for the "read)file" command.

    set argc [expr {[llength $tokens] - $index}]
    if {($argc != 1) && ($argc != 2)} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }	

    set arg {}
    set len [llength $tokens]
    set literal [getLiteral [lindex $tokens $index] arg]

    if {($argc == 1) && ($arg != "-nonewline")} {
	if {$index < $len} {
	    set index [checkFileName $tokens $index]
	} else {
	    logError numArgs {}
	}
    } elseif {$arg == "-nonewline"} {	
	incr index
	if {$index < $len} {
	    set index [checkFileName $tokens $index]
	} else {
	    logError numArgs {}
	}
    } else {
	set  index [checkFileName $tokens $index]
	set  index [checkInt $tokens $index]
    }
    return $index
}

proc tclX::checkLIndex {tokens index} {
    set word [lindex $tokens $index]
    # Check to see if:
    # - it's a string then verify it's "end", or "end-<integer>".
    # - it's a string then verify it's "len", or "len-<integer>".
    # - it's an integer (as opposed to a float.)

    if {[getLiteral $word literal]} {
	set length [string length $literal]
	if {[lsearch -exact [list "end" "len"] \
		[string range $literal 0 2]] >= 0} {
	    if {$length <= 3} {
		return [incr index]
	    } elseif {[string equal "-" [string index $literal 3]]} {
		set literal [string range $literal 4 end]
		if {[catch {incr literal}]} {
		    logError tclX::badLIndex [getTokenRange $word]
		}
		return [incr index]
	    } else {
		logError tclX::badLIndex [getTokenRange $word]
	    }
		
	} elseif {[catch {incr literal}]} {
	    logError tclX::badLIndex [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}

proc tclX::checkTlibSuffix {tokens index} {
    # Check to see if:
    # - it's a string then verify it ends with ".tlib"

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {![string match "*.tlib" $literal]} {
	    logError tclX::badTlibFile [getTokenRange $word]
	}
	return [incr index]
    } else {
	return [checkWord $tokens $index]
    }
}
