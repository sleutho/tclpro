# expect.tcl --
#
#	This file contains type and command checkers for the Expect
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: expect.tcl,v 1.3 2000/10/31 23:30:54 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide expect 1.0

namespace eval expect {
    # scanCmdsX.X --
    # Define the set of commands that need to be recursed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds5.28 {
	exit-TPC-SCAN			1		
	exp_exit-TPC-SCAN		1		
	exp_interact-TPC-SCAN		1		
	exp_trap-TPC-SCAN		1		
	expect-TPC-SCAN			1		
	expect_after-TPC-SCAN		1		
	expect_background-TPC-SCAN	1		
	expect_before-TPC-SCAN		1		
	expect_tty-TPC-SCAN		1		
	expect_user-TPC-SCAN		1		
	interact-TPC-SCAN		1		
	trap-TPC-SCAN			1		
    }

    variable scanCmds5.31 {
	exp_interpreter-TPC-SCAN	1		
    }

    # checkersX.X --
    # Define the set of command-specific checkers used by this package.

    variable checkers5.28 {
	exp_close		{checkFloatConfigure 0 {
				    -slave 
				    {-i {checkSwitchArg -i 1 1 {checkWord}}} 
				    {-onexec {checkSwitchArg -onexec 1 1 {
					{checkKeyword 1 {0 1}}
				    }}}
				} {checkWord}}
	exp_continue		{checkSimpleArgs 0 1 \
					{{checkKeyword 1 {-continue_timer}}}}
	exp_debug		{checkFloatConfigure 0 {
				    {-now {checkSimpleArgs 0 1 {
					{checkKeyword 1 {0 1}}}}
				    }
				} {checkKeyword 1 {0 1}}}
	exp_disconnect		{checkSimpleArgs 0 0 {}}
	exp_exit		{checkOption {
				    {-noexit {checkSimpleArgs 0 0 {}}}
				    {-onexit {checkSimpleArgs 0 1 {checkBody}}}
				} {checkSimpleArgs 0 1 {checkInt}}}
	exp_fork		{checkSimpleArgs 0 0 {}}
	exp_inter_return	{coreTcl::checkReturnCmd}
	exp_interact		{expect::checkInteractCmd}
	exp_internal		{checkFloatConfigure 0 {
				    {-info {checkSimpleArgs 0 0 {}}}
				    {-f {checkSwitchArg -f 1 1 {checkWord}}}
				} {checkKeyword 1 {0 1}}}
	exp_interpreter		{checkSimpleArgs 0 0 {}}
	exp_log_file		{expect::checkLogFileCmd}
	exp_log_user		{checkSimpleArgs 0 1 {
				    {checkKeyword 1 {0 1 -info}}
				}}
	exp_match_max		{expect::checkDefaultOrId checkWholeNum}
	exp_open		{checkFloatConfigure 0 {
				    -leaveopen 
				    {-i {checkSwitchArg -i 1 1 {checkWord}}}
				} {}}
	exp_overlay		{::analyzer::warn warnDeprecated "well... Don says don't use it" \
				    {checkCommand}}
	exp_parity		{expect::checkDefaultOrId checkInt}
	exp_pid			{checkFloatConfigure 0 {
				    -d {-i {checkSwitchArg -i 1 1 {checkWord}}}
				} {checkSimpleArgs 0  1 {checkInt}}}
	exp_remove_nulls	{expect::checkDefaultOrId checkInt}
	exp_send		{expect::checkSendCmd}
	exp_send_error		{expect::checkSendCmd}
	exp_send_log		{checkSwitches 1 {
				    --
				} {checkSimpleArgs 1 1 {checkWord}}}
	exp_send_tty		{expect::checkSendCmd}
	exp_send_user		{expect::checkSendCmd}
	exp_sleep		{checkSimpleArgs 1 1 {checkFloat}}
	exp_spawn		{expect::checkSpawnCmd}
	exp_strace		{checkFloatConfigure 1 {
				    -info
				} {checkInt}}
	exp_stty		{expect::checkSttyCmd}
	exp_system		{checkSimpleArgs 0 -1 {checkWord}}
	exp_timestamp		{checkFloatConfigure 1 {
				    {-seconds {
					checkSwitchArg -seconds 1 1 {checkInt}}
				    }
				    {-format  {
					checkSwitchArg -format 1 1 {checkWord}}
				    }
				} {}}
	exp_trap		{expect::checkTrapCmd}
	exp_version		{checkFloatConfigure 0 {
				   {-exit {
				       checkSwitchArg -exit 1 1 checkVersion}
				   }
				}  {checkSimpleArgs 0 1 {checkVersion}}}
	exp_wait		{checkFloatConfigure 1 {
				    -nowait {-i {
					checkSwitchArg -i 1 1 {checkWord}}
				    }
				} {}}
	expect			{expect::checkExpectCmd}
	expect_after		{expect::checkExpectGlobalCmd}
	expect_background	{expect::checkExpectGlobalCmd}
	expect_before		{expect::checkExpectGlobalCmd}
	expect_tty		{expect::checkExpectCmd}
	expect_user		{expect::checkExpectCmd}
    }

    variable checkers5.30 {
    }

    variable checkers5.31 {
	exp_interpreter	{checkSwitches 1 {
	    		    {-eof checkBody}
			} {checkSimpleArgs 0 0 {}}}
    }

    # aliasCmds --
    # Define the set of commands that are created as aliases of the
    # corresponding exp_* commands.  These aliases are lower priority that
    # other checkers so they will only be installed if no other checker has
    # been defined for the command.

    variable aliasCmds {
	debug disconnect fork inter_return interact interpreter log_file
	log_user match_max overlay parity remove_nulls send send_error send_log
	send_tty send_user sleep spawn strace stty system timestamp trap wait 
    }

    # coreAliasCmds --
    # Define the set of commands that are created as aliases of the
    # corresponding exp_* commands regardless of whether there is already
    # a checker defined.  These commands are a superset of the Tcl core
    # commands so it is generally better to just install them.

    variable coreAliasCmds {
	close exit
    }

    # messages --
    # Define the set of message types and their human-readable translations. 

    variable messages
    array set messages {
	expect::warnAmbiguous	{"ambiguous switch, use \"%1$s\" to avoid conflicts" warn usage}
    }

    variable expPats [list glob regexp exact]
    variable expOpts
    set expOpts(5.28) [list timestamp iread iwrite indices]
    set expOpts(5.31) [list iread indices]
}

# expect::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc expect::init {ver} {
    # Procedures that check special Expect functions need to know which
    # Expect version is loaded.

    variable expectVersion $ver

    foreach name [lsort [info vars ::expect::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::expect::scanCmds$ver"} {
	    break
	}
    }
    foreach name [lsort [info vars ::expect::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::expect::checkers$ver"} {
	    break
	}
    }

    # Add aliased checkers.  The first set are only added if there isn't
    # another checker defined for the command.  The second set are always
    # installed. 

    set aliases {}
    foreach name $::expect::aliasCmds {
	if {[analyzer::topChecker $name] == ""} {
	    lappend aliases $name [analyzer::topChecker exp_$name]
	}
    }
    foreach name $::expect::coreAliasCmds {
	lappend aliases $name [analyzer::topChecker exp_$name]
    }
    analyzer::addCheckers $aliases

    return
}

# expect::getMessage --
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

proc expect::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# expect::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc expect::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# expect::isPatternActionList --
#
#	Determine if the argument is a single pattern or a set of
#	pattern/action pairs.  If the argument has any number of
#	space chars followed by a newline, then it is a set of
#	pattern/action pairs, otherwise it is a single argument.
#
# Arguments:
#	str	The argument to parse.
#
# Results:
#	Return 1 if it is a set of pattern/action pairs or return 
#	0 if it is not.

proc expect::isPatternActionList {str} {
    return [regexp "(\[ \t\r\])?\n.*" $str]
}

# expect::expMatch --
#
#	Using the Expect style of matching, determine if the string
#	matches one of the keywords.
#
# Arguments:
#	keywords	A list of keywords to match.
#	str		The word to match.
#	minlen		Minimum number of chars required to match.
#
# Results:
#	Return 1 if this matches or 0 if it does not.

proc expect::expMatch {keywords str minlen} {
    set end [string length $str]
    foreach key $keywords {
	set m $minlen
	for {set i 0} {$i < $end} {incr i; incr m -1} {
	    if {[string index $str $i] != [string index $key $i]} {
		break
	    }
	}
	if {($i == $end) && ($m <= 0)} {
	    return 1
	}
    }
    return 0
}

# expect::parseExpectCmd --
#
#	This command is used by both the "expect" command and the 
#	"interact" command.  It determines how to parse and check
#	the command based on the number of arguments, supplied 
#	switches and special characters in the body of the args.
#
# Arguments:
#	chainCmd	The command to call once the tokens have
#			been parsed correctly.
#	tokens		The list of word tokens after the initial
#			command and subcommand names
#	index		The index into the token tree where the 
#			checkers should start checking.
#
# Results:
#	Return the next index, in the tokens tree, to check.

proc expect::parseExpectCmd {chainCmd tokens index} {
    set end  [llength $tokens]
    set argc [expr {$end - $index}]

    # The command was called with no arguments, so just return.

    if {$argc < 1} {
	return $end
    }
    
    # Determine which command to execute.  We have four possible cases: 
    # 1. One argument which should be split into words.
    # 2. One argument which should NOT be split into words.
    # 3. Two arguments where the first is "-brace" and the second  
    #    is the body that needs to be split into words.
    # 4. A bunch of pattern/action pairs.

    if {$argc == 1} {	
	set word [lindex $tokens $index]
	if {![getLiteral $word body]} {
	    return [checkWord $tokens $index]
	}
	if {[expect::isPatternActionList $body]} {
	    set tokens [expect::parseExpRange $tokens $index]
	    set index  0
	}
    } elseif {$argc == 2} {
	# Get the switch and the body.  If either are non-literal
	# then punt and check nothing specific.

	set word [lindex $tokens $index]
	if {![getLiteral $word switch]} {
	    return [checkCommand $tokens $index]
	}
	set word [lindex $tokens [expr {$index + 1}]]
	if {![getLiteral $word body]} {
	    return [checkCommand $tokens $index]
	}

	# If the switch is "-brace" increment the index so the rangeCmd
	# is called with the index pointing to the body.

	if {$switch == "-brace"} {
	    incr index
	    set tokens [expect::parseExpRange $tokens $index]
	    set index 0

	    # We need to add 1 to the result to keep the arg of -brace
	    # from getting re-checked.

	    set result [expr {[$chainCmd $tokens $index] + 1}]
	    return $result
	}
    }

    return [$chainCmd $tokens $index]
}

proc expect::parseExpRange {tokens index} {
    set script [getScript]
    set word   [lindex $tokens $index]
    set range  [lindex $word 1]
    set quote  [string index $script [parse charindex $script $range]]
    if {$quote == "\"" || $quote == "\{"} {
	set range [list [expr {[lindex $range 0] + 1}] \
		[expr {[lindex $range 1] - 2}]]
    }
    
    set result {}

    for {} {[parse charlength $script $range] > 0} \
	    {set range $tail} {
	# Parse the next command

	if {[catch {foreach {comment cmdRange tail tree} \
		[parse command $script $range] {}}]} {
	    # An error occurred during parsing so generate the error.

	    set errPos [lindex $::errorCode 2]
	    set errLen [expr {[lindex $range 1] \
		    - ($errPos - [lindex $range 0])}]
	    set errMsg [lindex $::errorCode end]
	    logError parse [list $errPos $errLen] $errMsg
	    
	    # Attempt to keep parsing at the next thing that looks
	    # like a command.
	    
	    set range [list $errPos [expr {[lindex $range 0] \
		    + [lindex $range 1] - $errPos}]]
	    if {[regexp -indices "\[^\\\]\[\n;\]" \
		    [parse getstring $script $range] match]} {
		set start [parse charindex $script $range]
		set end [expr {$start + [lindex $match 1] + 1}]
		set len [expr {$start \
			+ [parse charlength $script $range] - $end}]
		set tail [parse getrange $script $end $len]
		continue
	    } else {
		break
	    }
	}

	if {[parse charlength $script $cmdRange] <= 0} {
	    continue
	}
	eval {lappend result} $tree
    }

    return $result
}

proc expect::checkExpectGlobalCmd {tokens index} {
    if {([getLiteral [lindex $tokens $index] keyword]) \
	    && ($keyword == "-info")} {
	# The -info command was used.  Check this command for additional
	# switches and return.  This is an introspection expect command
	# not a new expect command.
	
	incr index
	set argc [llength $tokens]
	while {$index < $argc} {
	    set index [checkSwitches 1 {
		-all -nodirect {-i checkWord}
	    } {} $tokens $index]
	}
	return $index
    } else {
	# This is a standard expect command.  Use the default expect checker.

	return [expect::checkExpectCmd $tokens $index]
    }
}

proc expect::checkExpectCmd {tokens index} {
    return [expect::parseExpectCmd \
	    expect::checkExpTokens \
	    $tokens $index]
}

proc expect::checkExpTokens {tokens index} {
    variable expPats
    variable expOpts
    variable expectVersion

    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    # Assume this non-literal is a pattern, check the word
	    # then move on to check the action.

	    checkWord $tokens $i
	} else {
	    # Check the switches for the next expect subcommand.
	    
	    switch -glob -- $arg {
		"eof" -
		"null" -
		"default" -
		"timeout" -
		"full_buffer" {
		    # No-Op.  This keyword is considered to be the "pattern"
		    # in the pattern/action pair.  The next word is the action.
		}
		-* {
		    set arg [string range $arg 1 end]
		    if {$arg == "-"} {
			# The -- option is deprecated.  The next word
			# is a pattern.  Check the pattern for subcommands.
			
			logError warnDeprecated [getTokenRange \
				[lindex $tokens $i]] "-gl"
			incr i
			checkWord $tokens $i
		    } elseif {[expMatch $expPats $arg 2]} {
			# The next word is a pattern.  Check the pattern for
			# subcommands.
			
			incr i
			checkWord $tokens $i
		    } elseif {($expectVersion < 5.31) \
			    && [expMatch $expOpts(5.28) $arg 2]} {
			if {[expMatch [list timestamp iwrite] $arg 2]} {
			    set tmpRange [getTokenRange [lindex $tokens $i]]
			    logError warnDeprecated $tmpRange \
				    "expect without the \-$arg option"
			}
			continue
		    } elseif {($expectVersion >= 5.31) \
			    && [expMatch $expOpts(5.31) $arg 2]} {
			continue
		    } elseif {[expMatch "notransfer" $arg 1]} {
			continue
		    } elseif {[expMatch "nocase" $arg 3]} {
			continue
		    } elseif {$arg == "nobrace"} {
			continue
		    } elseif {$arg == "i"} {
			# Log error stating that -i requires a spawn_id
			# if there are not enought args.
			
			incr i
			checkSwitchArg -i 1 1 checkWord $tokens $i
			continue
		    } elseif {[expMatch "timeout" $arg 2]} {
			# Log error stating that -timeout requires an integer
			# if there are not enought args.
			
			incr i
			checkSwitchArg -timeout 1 1 checkInt $tokens $i
			continue
		    } else {
			# Log Error stating this is an unrecognized switch or 
			# a pattern that should be preceeded with a -gl.
			# Assume this is a pattern and the next word is the
			# action.
			
			set word [lindex $tokens $i]
			logError expect::warnAmbiguous \
				[getTokenRange $word] "-gl"
		    }
		}
		default {
		    # This is a pattern.  Check the pattern for subcommands.
		    
		    checkWord $tokens $i
		}
	    }
	}

	# If a body exists, check the body for the expect subcommand.
	
	incr i
	if {$i < $argc} {
	    if {![getLiteral [lindex $tokens $i] foo]} {
		checkWord $tokens $i
	    } else {
		checkBody $tokens $i
	    }
	}
    }
    return $i
}

proc expect::checkInteractCmd {tokens index} {
    return [expect::parseExpectCmd \
	    expect::checkInteractTokens \
	    $tokens $index]
}

proc expect::checkInteractTokens {tokens index} {
    variable expectVersion
    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    # Assume this non-literal is a pattern, check the word
	    # then move on to check the action.

	    checkWord $tokens $i
	} else {
	    # Check the switches for the next interact subcommand.
	    
	    switch -glob -- $arg {
		"eof" -
		"null" {
		    # No-Op.  This keyword is considered to be the "pattern"
		    # in the pattern/action pair.  The next word is the action.
		}
		"timeout" {
		    # Log error stating that -timeout requires a time arg.
		    
		    incr i
		    checkSwitchArg $arg 1 1 checkInt $tokens $i
		}
		-* {
		    set arg [string range $arg 1 end]
		    if {($arg == "-") || [expMatch "exact" $arg 2]} {
			# The next word is a pattern.  Check the pattern for
			# subcommands if the word exists.
			
			incr i
			checkSwitchArg -$arg 0 1 checkWord $tokens $i
		    } elseif {[expMatch "regexp" $arg 2]} {
			# The next word is a pattern.  Check the pattern for
			# subcommands.  Report an error if the pattern does
			# not exist.
			
			incr i
			checkSwitchArg -$arg 1 1 checkWord $tokens $i
		    } elseif {$arg == "i"} {
			# If there is another word check it for subcommands,
			# then continue looking for pattern/action pairs.
			
			incr i
			checkSwitchArg -$arg 0 1 checkWord $tokens $i
			continue
		    } elseif {[expMatch "input" $arg 2] \
			    || [expMatch "output" $arg 3] \
			    || ($arg == "u")} {
			# These are switches with required args.  Verify the 
			# next word is there, then continue looking for 
			# pattern/action pairs.
			
			incr i
			checkSwitchArg -$arg 1 1 checkWord $tokens $i
			continue
		    } elseif {[expMatch "nobuffer" $arg 3] \
			    || [expMatch "indices" $arg 3] \
			    || [expMatch "iread" $arg 2] \
			    || [expMatch "iwrite" $arg 2] \
			    || ($arg == "echo") \
			    || ($arg == "f") \
			    || ($arg == "F") \
			    || ($arg == "reset") \
			    || ($arg == "nobrace") \
			    || ($arg == "o")} {
			# These are switches that take no args. Just continue 
			# looking for pattern/action pairs.
			
			continue
		    } elseif {$arg == "eof"} {
			if {$expectVersion < 5.31} {
			    set mid warnDeprecated
			} else {
			    set mid obsoleteCmd
			}
			set range [getTokenRange [lindex $tokens $i]]
			logError $mid $range "eof"
		    } elseif {$arg == "timeout"} {
			if {$expectVersion < 5.31} {
			    set mid warnDeprecated
			} else {
			    set mid obsoleteCmd
			}
			set range [getTokenRange [lindex $tokens $i]]
			logError $mid $range "timeout"
			incr i
			checkSwitchArg -$arg 1 1 checkInt $tokens $i
		    } elseif {[expMatch "timestamp" $arg 2]} {
			if {$expectVersion < 5.31} {
			    set mid warnDeprecated
			} else {
			    set mid obsoleteCmd
			}
			set range [getTokenRange [lindex $tokens $i]]
			logError $mid $range "clock"
			continue
		    } else {
			# Log Error stating this is an unrecognized switch or 
			# a pattern that should be preceeded with an -ex.
			# Assume this is a pattern and the next word is the
			# action.
			
			set word [lindex $tokens $i]
			logError expect::warnAmbiguous \
				[getTokenRange $word] "-ex"
		    }
		}
		default {
		    # This is a pattern.  Check the pattern for subcommands.
		    
		    checkWord $tokens $i
		}
	    }
	}
	# If a body exists, check the body for the expect subcommand.
	
	incr i
	if {$i < $argc} {
	    if {![getLiteral [lindex $tokens $i] foo]} {
		checkWord $tokens $i
	    } else {
		checkBody $tokens $i
	    }
	}
    }
    return $i
}

proc expect::checkLogFileCmd {tokens index} {
    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    break
	}

	switch -- $arg {
	    -noappend {
		# No-Op
	    }
	    -a -
	    -open -
	    -leaveopen {
		incr i
		checkWord $tokens $i
	    }
	    -info {
		incr i
		return [checkSimpleArgs 0 0 {} $tokens $i]
	    }
	    default {
		break
	    }
	}
    }
    
    return [checkSimpleArgs 0 1 {checkChannelID} $tokens $i]
}

proc expect::checkSendCmd {tokens index} {
    set stringRequired 1
    set argc [llength $tokens]

    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    break
	}
	if {[string index $arg 0] != "-"} {
	    break
	}

	set arg [string range $arg 1 end]
	if {$arg == "-"} {
	    # -- flag was found, so don't allow any more flags.
	    
	    incr i
	    break
	} elseif {$arg == "i"} {
	    # Check for the switch argument and set the string
	    # required bit to true.
	    
	    incr i
	    checkSwitchArg $arg 1 1 checkWord $tokens $i
	    set stringRequired 1
	} elseif {($arg == "h") \
		|| ($arg == "s") \
		|| [expMatch "null" $arg 1]} {
	    # Just set the string required bit to true.

	    set stringRequired 1
	} elseif {[expMatch "raw" $arg 1] \
		|| [expMatch "break" $arg 1]} {
	    # Just set the string required bit to false.

	    set stringRequired 0
	} else {
	    # This is a bad switch.

	    set word [lindex $tokens $i]
	    logError badSwitch [getTokenRange $word] "-$arg"
	}
    }
    
    # If the string is required, then verify that one argument is
    # left that is the string to be sent.  If there are more or
    # less arguments then log an error.  If the string is not 
    # required, log an error if the remaining number of args is 
    # not zero. 

    set remaining [expr {$argc - $i}]
    if {($stringRequired) && ($remaining == 1)} {
	set i [checkWord $tokens $i]
    } elseif {(!$stringRequired) && ($remaining == 0)} {
	# No-Op.  This is OK behavior.
    } else {
	logError numArgs {} 
	set i [checkCommand $tokens $i]
    }

    return $i
}

proc expect::checkSpawnCmd {tokens index} {
    set openArg 0
    set ptyOnly 0

    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    break
	}
	switch -- $arg {	    
	    -nottyinit -
	    -nottycopy -
	    -noecho -
	    -console {
		# No-Op.
	    }
	    -pty {
		set ptyOnly 1
	    }
	    -open -
	    -leaveopen {
		set openArg 1
		incr i
		checkSwitchArg $arg 1 1 checkChannelID $tokens $i
	    }
	    -ignore {
		incr i
		checkSwitchArg $arg 1 1 expect::checkSignal $tokens $i
	    }
	    -trap {
		incr i
		checkSwitchArg $arg 2 2 {
		    checkWord {checkKeyword 1 {SIG_DFL SIF_IGN}}
		} $tokens $i
	    }
	    default {
		break
	    }
	}
    }

    set remaining [expr {$argc - $i}]
    if {($openArg && ($remaining != 0)) \
	    || (!$ptyOnly && !$openArg && ($remaining == 0))} {
	logError numArgs {}
    } elseif {$remaining > 0} {
	set i [checkEvalArgs $tokens $i]
    }

    return $i
}

proc expect::checkSttyCmd {tokens index} {
    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    continue
	}
	switch -- $arg {	    
	    cooked -
	    echo -
	    raw -
	    -cooked -
	    -echo -
	    -raw {
		continue
	    }
	    rows -
	    columns {
		incr i
		checkSwitchArg $arg 0 1 checkInt $tokens $i
	    }
	    < {
		incr i
		set i [checkSimpleArgs 1 1 checkWord $tokens $i]
		break
	    }
	    default {
		set word [lindex $tokens $i]
		logError nonPortOption [getTokenRange $word]
	    }
	}
    }
    return $i
}

proc expect::checkTrapCmd {tokens index} {
    set show 0
    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    break
	}
	switch -- $arg {	    
	    -code {
		# No-Op
	    }
	    -max -
	    -name -
	    -number {
		set show 1
	    } 
	    default {
		break
	    }
	}
    }
    
    set remaining [expr {$argc - $i}]
    if {$show} {
	if {$remaining > 0} {
	    logError numArgs {}
	    set i [checkCommand $tokens $i]
	}
    } else {
	set i [checkNumArgs {
	    {1	{expect::checkSignal}}
	    {2  {checkSimpleArgs 2 2 {checkBody expect::checkSignal}}}
	} $tokens $i]
    }
    return $i
}

proc expect::checkSignal {tokens index} {
    return [checkWord $tokens $index]
}

proc expect::checkDefaultOrId {chainCmd tokens index} {
    set identity 0
    set default  0
    set errIndex 0

    set argc [llength $tokens]
    for {set i $index} {$i < $argc} {incr i} {
	if {![getLiteral [lindex $tokens $i] arg]} {
	    break
	}

	switch -- $arg {
	    -i {
		set errIndex $i
		incr i
		set identity 1
		checkSwitchArg "-i" 1 1 checkWord $tokens $i
	    }
	    -d {
		set errIndex $i
		set default 1
	    }
	    default {
		break
	    }
	}
    }
    
    if {($identity && $default)} {
	set range [getTokenRange [lindex $tokens $errIndex]]
	logError mismatchOptions $range
    }

    set remaining [expr {$argc - $i}]
    if {$remaining == 1} {
	set i [$chainCmd $tokens $i]
    } elseif {$remaining > 1} {
	logError numArgs {} 
	set i [checkCommand $tokens $i]
    }

    return $i
}

