# coreTcl.tcl --
#
#	This file contains type and command checkers for the core Tcl
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
#
# RCS: @(#) $Id: coreTcl.tcl,v 1.14 2000/10/31 23:30:54 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide coreTcl 1.0

namespace eval coreTcl {
    # If the init command is called with empty string for the 
    # version, use this version number as the default checker.
    # Register the default version of this analyzer package 
    # in the analyzer's configuration package.

    set ::configure::versions(coreTcl,default) $::projectInfo::baseTclVers

    # Define the set of commands that need to be recuresed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds7.3 {
	case-TPC-SCAN		1
	catch-TPC-SCAN		1
	eval-TPC-SCAN		1
	for-TPC-SCAN		1
	foreach-TPC-SCAN	1
	history-TPC-SCAN	1
	if-TPC-SCAN		1
	switch-TPC-SCAN		1
	time-TPC-SCAN		1
	while-TPC-SCAN		1
	proc		{addContext 1 1 {} {} {checkSimpleArgs 3 3 {
	    			addUserProc addArgList checkBody}}}
	rename		{addRenameCmd}
    }
    variable scanCmds7.4 {
    }
    variable scanCmds7.5 {
	after-TPC-SCAN		1
	namespace	{checkOption {
	    {code	    	{checkSimpleArgs 1 1 {checkBody}}}
	    {eval	    	{addContext 2 0 {} {} {checkSimpleArgs 2 -1 \
		    			{checkWord checkEvalArgs}}}}
	    {export	    	{addExportCmd}}
	    {import	    	{addImportCmd}}
	} {checkCommand}}
    }
    variable scanCmds7.6 {}
    variable scanCmds8.0 {}
    variable scanCmds8.1 {}
    variable scanCmds8.2 {}
    variable scanCmds8.3 {}
    variable proScanCmds {
	debugger_eval-TPC-SCAN	1
    }

    # Define the set of command-specific checkers used by this package.

    variable checkers7.3 {
	append		{checkSimpleArgs 2 -1 {checkVarName checkWord}}
	array		{checkSimpleArgs 2 3 {{checkOption {
	    {anymore	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {donesearch	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {names	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {nextelement    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {size	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {startsearch    {checkSimpleArgs 1 1 {checkVarName}}}
	} {}}}}
	auto_execok	{checkSimpleArgs 1  1 {checkFileName}}
	auto_load	{checkSimpleArgs 1  1 {checkWord}}
	auto_mkindex	{checkSimpleArgs 1 -1 {checkFileName checkPattern}}
	auto_reset	{checkSimpleArgs 0  0 {}}
	break		{checkSimpleArgs 0 0 {}}
	case		{coreTcl::checkCaseCmd}
	catch		{checkSimpleArgs 1 2 {checkBody checkVarName}}
	cd		{checkSimpleArgs 0 1 {checkFileName}}
	close		{checkSimpleArgs 1 1 {checkChannelID}}
	concat		{checkSimpleArgs 0 -1 {checkWord}}
	continue	{checkSimpleArgs 0 0 {}}
	eof		{checkSimpleArgs 1 1 {checkChannelID}}
	error		{checkSimpleArgs 1 3 {checkWord}}
	eval		{checkSimpleArgs 1 -1 {checkEvalArgs}}
	exec		{checkSwitches 1 {
	    		    -keepnewline --
			} {checkSimpleArgs 1 -1 {checkWord}}}
	exit		{checkSimpleArgs 0 1 {checkInt}}
	expr		coreTcl::checkExprCmd
	file		{checkSimpleArgs 1 -1 {{checkOption {
	    {atime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {attributes 	{checkSimpleArgs 1 -1 {checkFileName 
				{checkConfigure 1 {
				    {-group {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-owner {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-permissions {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-archive {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-hidden {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-longname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-readonly {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-shortname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-system {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-creator {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-type {::analyzer::warn nonPortCmd {} {checkWord}}}
				}}}}}
	    {dirname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {executable 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {exists 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {extension 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {isdirectory 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {isfile 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {lstat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {mtime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {owned 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readable 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readlink 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {rootname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {size 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {stat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {tail 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {type 		{checkSimpleArgs 1 1 {checkFileName}}} 
	    {volume 		{checkSimpleArgs 0 0 {}}} 
	    {writable 		{checkSimpleArgs 1 1 {checkFileName}}}
	} {}}}}
	flush		{checkSimpleArgs 1 1 {checkChannelID}}
	for		{checkSimpleArgs 4 4 {checkBody checkExpr checkBody}}
	foreach		coreTcl::checkForeachCmd
	format		{checkSimpleArgs 1 -1 {checkWord}}
	gets		{checkSimpleArgs 1  2 {checkChannelID checkVarName}}
	glob		{checkSwitches 1 {
	    		    -nocomplain --
			} {checkSimpleArgs 1 -1 {checkPattern}}}
	global		{checkSimpleArgs 1 -1 {checkVarName}}
	history		{checkSimpleArgs 0 3 {{checkOption {
	    {add 		{checkSimpleArgs 1 2 \
		    			{checkBody {checkKeyword 0 {exec}}}}}
	    {change 		{checkSimpleArgs 1 2 {checkWord}}}
	    {event 		{checkSimpleArgs 0 1 {checkWord}}}
	    {info 		{checkSimpleArgs 0 1 {checkInt}}}
	    {keep 		{checkSimpleArgs 0 1 {checkInt}}}
	    {nextid 		{checkSimpleArgs 0 0 {}}}
	    {redo 		{checkSimpleArgs 0 1 {checkWord}}}
	} {}}}}
	if 		coreTcl::checkIfCmd
	incr		{checkSimpleArgs 1  2 {checkVarName checkInt}}
	info		{checkSimpleArgs 1 4 {{checkOption {
	    {args	{checkSimpleArgs 1  1 {checkWord}}}
	    {body	{checkSimpleArgs 1  1 {checkWord}}}
	    {cmdcount	{checkSimpleArgs 0  0 {}}}
	    {commands	{checkSimpleArgs 0  1 {checkPattern}}}
	    {complete	{checkSimpleArgs 1  1 {checkWord}}}
	    {default	{checkSimpleArgs 3  3 \
				{checkWord checkWord checkVarName}}}
	    {exists	{checkSimpleArgs 1  1 {checkVarName}}}
	    {globals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {level	{checkSimpleArgs 0  1 {checkInt}}}
	    {library	{checkSimpleArgs 0  0 {}}}
	    {loaded	{checkSimpleArgs 0  1 {checkWord}}}
	    {locals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {patchlevel	{checkSimpleArgs 0  0 {}}}
	    {procs	{checkSimpleArgs 0  1 {checkPattern}}}
	    {script	{checkSimpleArgs 0  0 {}}}
	    {tclversion	{checkSimpleArgs 0  0 {}}}
	    {vars	{checkSimpleArgs 0  1 {checkPattern}}}
	} {}}}}
	join		{checkSimpleArgs 1  2 {checkList checkWord}}
	lappend		{checkSimpleArgs 2 -1 {checkVarName checkWord}}
	lindex		{checkSimpleArgs 2  2 {checkList checkInt}}
	linsert		{checkSimpleArgs 3 -1 {checkList checkInt checkWord}}
	list		{checkSimpleArgs 0 -1 {checkWord}}
	llength		{checkSimpleArgs 1  1 {checkList}}
	lrange		{checkSimpleArgs 3  3 {checkList checkInt}}
	lreplace	{checkSimpleArgs 3 -1 {checkList checkInt \
				checkInt checkWord}}
	lsearch		{checkTailArgs \
			     {checkHeadSwitches 0 2 {
				 -exact -glob -regexp
			     } {}} \
			     {checkSimpleArgs 2 2 {checkList checkPattern}} \
			     2
			}
	lsort		{checkTailArgs \
			     {checkHeadSwitches 0 1 {
				 -ascii -integer -real \
				 {-command {checkProcCall 2}} \
				 -increasing -decreasing
			         } {}
			     } \
	    		     {checkSimpleArgs 1 1 {checkList}} \
			     1
			}
	open		{checkSimpleArgs 1 3 \
			    {checkFileName checkAccessMode checkInt}}
	parray		{checkSimpleArgs 1  1 {checkVarName}}
	pid		{checkSimpleArgs 0  1 {checkChannelID}}
	proc		{checkContext 1 1 {checkSimpleArgs 3  3 \
			    {checkRedefined checkArgList checkBody}}}
        puts 		{checkOption {
	    		    {-nonewline {checkNumArgs {
				{1  {checkSimpleArgs 1 1 {checkWord}}}
				{-1  {checkSimpleArgs 2 3 {
				    checkChannelID checkWord 
				    {checkKeyword 0 nonewline}}}}}
				}
			    }
			} {checkNumArgs {
	    		    {1  {checkSimpleArgs 1 1 {checkWord}}}
			    {-1  {checkSimpleArgs 2 3 {
				checkChannelID checkWord 
				{checkKeyword 0 nonewline}}}}}
			    }
			}
	pwd		{checkSimpleArgs 0  0 {}}
        read 		coreTcl::checkReadCmd
	regexp		{checkSwitches 1 {
	    		    -nocase -indices --
			} {checkSimpleArgs 2 -1 \
				{coreTcl::checkRegexp checkWord checkVarName}}}
	regsub		{checkSwitches 1 {
	    		    -all -nocase --
			} {checkSimpleArgs 4 4 \
				{coreTcl::checkRegexp checkWord 
	                                 checkWord checkVarName}
                        }}
	rename		{checkSimpleArgs 2  2 {checkProcName checkWord}}
	return		coreTcl::checkReturnCmd
	scan		{checkSimpleArgs 3 -1 \
			    {checkWord checkWord checkVarName}}
	seek		{checkSimpleArgs 2  3 {checkChannelID checkInt \
				{checkKeyword 0 {start current end}}}}
	set		{checkSimpleArgs 1  2 {checkVarName checkWord}}
	source		coreTcl::checkSourceCmd
	split		{checkSimpleArgs 1  2 {checkWord}}
	string		{checkSimpleArgs 2  4 {{checkOption {
	    {compare 		{checkSimpleArgs 2 2 {checkWord}}}
	    {first 		{checkSimpleArgs 2 2 {checkWord}}}
	    {index 		{checkSimpleArgs 2 2 {checkWord checkInt}}}
	    {last 		{checkSimpleArgs 2 2 {checkWord}}}
	    {length 		{checkSimpleArgs 1 1 {checkWord}}}
	    {match 		{checkSimpleArgs 2 2 {checkPattern checkWord}}}
	    {range 		{checkSimpleArgs 3 3 {checkWord checkIndex}}}
	    {tolower 		{checkSimpleArgs 1 1 {checkWord}}}
	    {toupper 		{checkSimpleArgs 1 1 {checkWord}}}
	    {trim 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimleft 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimright 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	} {}}}}
	switch		{checkSwitches 0 {
	    		    -exact -glob -regexp --
			} coreTcl::checkSwitchCmd}
	tcl_endOfWord		{checkSimpleArgs 2  2 {checkWord checkIndex}}
	tcl_startOfNextWord	{checkSimpleArgs 2  2 {checkWord checkIndex}}
	tcl_startOfPreviousWord	{checkSimpleArgs 2  2 {checkWord checkIndex}}
	tcl_wordBreakAfter	{checkSimpleArgs 2  2 {checkWord checkIndex}}
	tcl_wordBreakBefore	{checkSimpleArgs 2  2 {checkWord checkIndex}}
	tell		{checkSimpleArgs 1  1 {checkChannelID}}
	time		{checkSimpleArgs 1  2 {checkBody checkInt}}
	trace		{checkNumArgs {
	    		    {2  {checkSimpleArgs 2 2 \
				    {{checkKeyword 1 {vinfo}} \
				    checkVarName}}}
			    {4  {checkSimpleArgs 4 4 \
				    {{checkKeyword 1 {variable vdelete}} \
				    checkVarName coreTcl::checkTraceOp \
				    {checkProcCall 3}}}}
			}}
	unknown		{checkSimpleArgs 1 -1 {checkWord}}
	unset		{checkSimpleArgs 1 -1 {checkVarName}}
	uplevel		{checkLevel {checkSimpleArgs 1 -1 {
	    coreTcl::checkUplevelCmd}}}
	upvar		{coreTcl::checkUpvarCmd}
	while      	{checkSimpleArgs 2  2 {checkExpr checkBody}}
    }

    variable checkers7.4 {
	append		{checkSimpleArgs 1 -1 {checkVarName checkWord}}
	array		{checkSimpleArgs 2 3 {{checkOption {
	    {anymore	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {donesearch	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {exists	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {get	    {checkSimpleArgs 1 2 {checkVarName checkPattern}}}
	    {names	    {checkSimpleArgs 1 2 {checkVarName checkPattern}}}
	    {nextelement    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {set	    {checkSimpleArgs 2 2 {checkVarName checkList}}}
	    {size	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {startsearch    {checkSimpleArgs 1 1 {checkVarName}}}
	} {}}}}
	lappend		{checkSimpleArgs 1 -1 {checkVarName checkWord}}
	lindex		{checkSimpleArgs 2  2 {checkList checkIndex}}
	linsert		{checkSimpleArgs 3 -1 {checkList checkIndex checkWord}}
	lrange		{checkSimpleArgs 3  3 {checkList checkIndex}}
	lreplace	{checkSimpleArgs 3 -1 {checkList checkIndex \
				checkIndex checkWord}}
	parray		{checkSimpleArgs 1  2 {checkVarName checkPattern}}
	string		{checkSimpleArgs 2  4 {{checkOption {
	    {compare 		{checkSimpleArgs 2 2 {checkWord}}}
	    {first 		{checkSimpleArgs 2 2 {checkWord}}}
	    {index 		{checkSimpleArgs 2 2 {checkWord checkInt}}}
	    {last 		{checkSimpleArgs 2 2 {checkWord}}}
	    {length 		{checkSimpleArgs 1 1 {checkWord}}}
	    {match 		{checkSimpleArgs 2 2 {checkPattern checkWord}}}
	    {range 		{checkSimpleArgs 3 3 {checkWord checkIndex}}}
	    {tolower 		{checkSimpleArgs 1 1 {checkWord}}}
	    {toupper 		{checkSimpleArgs 1 1 {checkWord}}}
	    {trim 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimleft 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimright 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {wordend 		{checkSimpleArgs 2 2 {checkWord checkIndex}}}
	    {wordstart 		{checkSimpleArgs 2 2 {checkWord checkIndex}}}
	} {}}}}
	subst		{checkSwitches 0 {
	    		    -nobackslashes -nocommands -novariables
			} {checkSimpleArgs 1 1 {checkWord}}}
    }

    variable checkers7.5 {
        after 		{checkOption {
	    {cancel	    {checkSimpleArgs 1 -1 {checkWord}}}
	    {idle	    {checkSimpleArgs 0 -1 {checkEvalArgs}}}
	    {info	    {checkSimpleArgs 0 -1 {checkWord}}}
	} {checkSimpleArgs 1 -1 {checkInt checkEvalArgs}}}
	bgerror		{checkSimpleArgs 1 1 {checkWord}}
	clock		{checkSimpleArgs 1 6 {{checkOption {
	    {clicks	    {checkSimpleArgs 0 0 {}}}
	    {format	    {checkSimpleArgs 1 5 {
				checkInt
				{checkSwitches 0 {
				    {-format coreTcl::checkClockFormat} 
				    {-gmt checkBoolean}
				} {}}}}
	    }
	    {scan	    {checkSimpleArgs 1 5 {
				checkWord
				{checkSwitches 0 {
				    {-base checkInt}
				    {-gmt checkBoolean}
				} {}}}}
	    }
	    {seconds	    {checkSimpleArgs 0 0 {}}}
	} {}}}}
	fblocked	{checkSimpleArgs 1 1 {checkChannelID}}
	fconfigure	{checkSimpleArgs 1 -1 {checkChannelID {
	    checkConfigure 1 {
		{-blocking checkBoolean}
		{-buffering {checkKeyword 0 {full line none}}}
		{-buffersize checkInt}
		{-eofchar {checkListValues 0 2 {checkWord}}}
		{-peername {checkSimpleArgs 0 0 {}}}
		{-sockname {checkSimpleArgs 0 0 {}}}
		{-translation {checkListValues 0 2 {
		    {checkKeyword 1 {auto binary cr crlf lf}}}}}}
		}
	    }
	}
	file		{checkSimpleArgs 1 -1 {{checkOption {
	    {atime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {attributes 	{checkSimpleArgs 1 -1 {checkFileName
				{checkConfigure 1 {
				    {-group {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-owner {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-permissions {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-archive {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-hidden {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-longname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-readonly {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-shortname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-system {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-creator {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-type {::analyzer::warn nonPortCmd {} {checkWord}}}
				}}}}}
	    {dirname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {executable 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {exists 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {extension 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {isdirectory 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {isfile 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {join 		{checkSimpleArgs 1 -1 {checkFileName}}}
	    {lstat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {mtime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {nativename 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {owned 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {pathtype 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readable 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readlink 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {rootname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {size 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {split 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {stat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {tail 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {type 		{checkSimpleArgs 1 1 {checkFileName}}} 
	    {volume 		{checkSimpleArgs 0 0 {}}} 
	    {writable 		{checkSimpleArgs 1 1 {checkFileName}}}
	} {}}}}
	fileevent	{checkSimpleArgs 2 3 {checkChannelID \
			    {checkKeyword 0 {readable writable}} checkBody}}
	info		{checkSimpleArgs 1 4 {{checkOption {
	    {args	{checkSimpleArgs 1  1 {checkWord}}}
	    {body	{checkSimpleArgs 1  1 {checkWord}}}
	    {cmdcount	{checkSimpleArgs 0  0 {}}}
	    {commands	{checkSimpleArgs 0  1 {checkPattern}}}
	    {complete	{checkSimpleArgs 1  1 {checkWord}}}
	    {default	{checkSimpleArgs 3  3 \
				{checkWord checkWord checkVarName}}}
	    {exists	{checkSimpleArgs 1  1 {checkVarName}}}
	    {globals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {hostname	{checkSimpleArgs 0  0 {}}}
	    {level	{checkSimpleArgs 0  1 {checkInt}}}
	    {library	{checkSimpleArgs 0  0 {}}}
	    {loaded	{checkSimpleArgs 0  1 {checkWord}}}
	    {locals	{checkSimpleArgs 0  1 {checkPattern}}}
	    {nameofexecutable	{checkSimpleArgs 0  0 {}}}
	    {patchlevel	{checkSimpleArgs 0  0 {}}}
	    {procs	{checkSimpleArgs 0  1 {checkPattern}}}
	    {script	{checkSimpleArgs 0  0 {}}}
	    {sharedlibextension	{checkSimpleArgs 0  0 {}}}
	    {tclversion	{checkSimpleArgs 0  0 {}}}
	    {vars	{checkSimpleArgs 0  1 {checkPattern}}}
	} {}}}}
	interp		{checkOption {
	    {alias		{checkNumArgs {
	    			    {2  {checkSimpleArgs 2 2 {
					checkList checkWord}}}
				    {3  {checkSimpleArgs 3 3 {
					checkList checkWord \
					{checkKeyword 1 [list {}]}}}}
				    {-1 {checkSimpleArgs 4 -1 {
					checkList checkWord checkList \
				        checkWord}}}
				}}}
	    {aliases		{checkSimpleArgs 0  1 {checkList}}}
	    {create 		{checkSwitches 0 {
				     -safe --
	    			} {checkSimpleArgs 0 1 {checkList}}}}
	    {delete 		{checkSimpleArgs 0 -1 {checkList}}}
	    {eval 		{checkSimpleArgs 2 -1 \
		    			{checkList checkEvalArgs}}}
	    {exists 		{checkSimpleArgs 1  1 {checkList}}}
	    {issafe		{checkSimpleArgs 0  1 {checkList}}}
	    {share 		{checkSimpleArgs 3  3 {
				    checkList checkChannelID checkList}}}
	    {slaves 		{checkSimpleArgs 0  1 {checkList}}}
	    {target 		{checkSimpleArgs 2  2 {checkList checkWord}}}
	    {transfer 		{checkSimpleArgs 3  3 {
				    checkList checkChannelID checkList}}}
	} {}}
	load		{checkSimpleArgs 1  3 {checkFileName checkWord \
				checkList}}
	package		{checkSimpleArgs 1 4 {{checkOption {
	    {forget	 	{checkSimpleArgs 1 1 {checkWord}}}
	    {ifneeded 		{checkSimpleArgs 2 3 \
		    		    {checkWord checkVersion 
	    			    checkBody}}}
	    {names 		{checkSimpleArgs 0 0 {}}}
	    {provide 		{checkSimpleArgs 1 2 {checkWord 
	    			    checkVersion}}}
	    {require 		{checkSwitches 1 {
					-exact
	    			} {checkSimpleArgs 1 2 \
					{checkWord checkVersion}}}}
	    {unknown 		{checkSimpleArgs 0 1 {checkWord}}}
	    {vcompare 		{checkSimpleArgs 2 2 {checkVersion}}}
	    {versions 		{checkSimpleArgs 1 1 {checkWord}}}
	    {vsatisfies 	{checkSimpleArgs 2 2 {checkVersion}}}
	} {}}}}
	pkg_mkIndex	{checkSimpleArgs 2 -1 {checkFileName checkPattern}}
	socket		coreTcl::checkSocketCmd
	update		{checkSimpleArgs 0  1 {{checkKeyword 0 {idletasks}}}}
	vwait		{checkSimpleArgs 0  1 {checkVarName}}
    }

    variable checkers7.6 {
	file		{checkSimpleArgs 1 -1 {{checkOption {
	    {atime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {attributes 	{checkSimpleArgs 1 -1 {checkFileName
				{checkConfigure 1 {
				    {-group {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-owner {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-permissions {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-archive {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-hidden {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-longname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-readonly {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-shortname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-system {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-creator {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-type {::analyzer::warn nonPortCmd {} {checkWord}}}
				}}}}}
	    {copy 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 2 -1 {checkFileName}}}}
	    {delete 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 1 -1 {checkFileName}}}}
	    {dirname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {executable 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {exists 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {extension 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {isdirectory 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {isfile 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {join 		{checkSimpleArgs 1 -1 {checkFileName}}}
	    {lstat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {mkdir 		{checkSimpleArgs 1 -1 {checkFileName}}}
	    {mtime 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {nativename 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {owned 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {pathtype 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readable 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readlink 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {rename 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 2 -1 {checkFileName}}}}
	    {rootname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {size 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {split 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {stat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {tail 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {type 		{checkSimpleArgs 1 1 {checkFileName}}} 
	    {volume 		{checkSimpleArgs 0 0 {}}} 
	    {writable 		{checkSimpleArgs 1 1 {checkFileName}}}
	} {}}}}
    }

    variable checkers8.0 {
	auto_import	{checkSimpleArgs 1  1 {checkPattern}}
	auto_mkindex_old {checkSimpleArgs 1 -1 {checkFileName checkPattern}}
	auto_qualify	{checkSimpleArgs 2 2 {checkWord checkNamespace}}
	tcl_findLibrary	{checkSimpleArgs 6 6 {checkWord checkVersion checkWord
	                     checkBody checkVarName}}
	binary		{checkOption {
	    {format	    {checkSimpleArgs 1 -1 {checkWord}}}
	    {scan	    {checkSimpleArgs 2 -1 {checkWord checkWord \
							checkVarName}}}
	} {}}
	fconfigure	{checkSimpleArgs 1 -1 {checkChannelID {
	    checkConfigure 1 {
		{-blocking checkBoolean}
		{-buffering {checkKeyword 0 {full line none}}}
		{-buffersize checkInt}
		{-eofchar {checkListValues 0 2 {checkWord}}}
		{-peername {checkSimpleArgs 0 0 {}}}
		{-mode {checkWord}}
		{-sockname {checkSimpleArgs 0 0 {}}}
		{-translation {checkListValues 0 2 {
		    {checkKeyword 1 {auto binary cr crlf lf}}}}}}
		}
	    }
	}
	fcopy		{checkSimpleArgs 2 6 {
				checkChannelID checkChannelID
				{checkSwitches 0 {
				    {-size checkInt} 
				    {-command checkBody}
				} {}}}}
	history		{checkSimpleArgs 0 3 {{checkOption {
	    {add 		{checkSimpleArgs 1 2 \
		    			{checkBody {checkKeyword 0 {exec}}}}}
	    {change 		{checkSimpleArgs 1 2 {checkWord}}}
	    {clear 		{checkSimpleArgs 0 0 {}}}
	    {event 		{checkSimpleArgs 0 1 {checkWord}}}
	    {info 		{checkSimpleArgs 0 1 {checkInt}}}
	    {keep 		{checkSimpleArgs 0 1 {checkInt}}}
	    {nextid 		{checkSimpleArgs 0 0 {}}}
	    {redo 		{checkSimpleArgs 0 1 {checkWord}}}
	} {}}}}
    	interp		{checkOption {
	    {alias		{checkNumArgs {
	    			    {2  {checkSimpleArgs 2 2 {
					checkList checkWord}}}
				    {3  {checkSimpleArgs 3 3 {
					checkList checkWord \
					{checkKeyword 1 [list {}]}}}}
				    {-1 {checkSimpleArgs 4 -1 {
					checkList checkWord checkList \
				        checkWord}}}
				}}}
	    {aliases		{checkSimpleArgs 0  1 {checkList}}}
	    {create 		{checkSwitches 0 {
				     -safe --
	    			} {checkSimpleArgs 0 1 {checkList}}}}
	    {delete 		{checkSimpleArgs 0 -1 {checkList}}}
	    {eval 		{checkSimpleArgs 2 -1 \
		    			{checkList checkEvalArgs}}}
	    {exists 		{checkSimpleArgs 1  1 {checkList}}}
	    {expose 		{checkSimpleArgs 2  3 {checkList checkWord}}}
	    {hide 		{checkSimpleArgs 2  3 {checkList checkWord}}}
	    {hidden 		{checkSimpleArgs 0  1 {checkList}}}
	    {invokehidden 	{checkNumArgs {
	    			    {1  {checkSimpleArgs 1  1 {checkList}}}
				    {-1 {checkSimpleArgs 1 -1 {checkList \
		                    {checkSwitches 1 {
				        {-global checkWord}
				    } {checkSimpleArgs 0 -1 {checkWord}}}}}}
				}}}
	    {issafe		{checkSimpleArgs 0  1 {checkList}}}
	    {marktrusted 	{checkSimpleArgs 1  1 {checkList}}}
	    {share 		{checkSimpleArgs 3  3 {
				    checkList checkChannelID checkList}}}
	    {slaves 		{checkSimpleArgs 0  1 {checkList}}}
	    {target 		{checkSimpleArgs 2  2 {checkList checkWord}}}
	    {transfer 		{checkSimpleArgs 3  3 {
				    checkList checkChannelID checkList}}}
	} {}}
	lsort		{checkTailArgs \
			     {checkHeadSwitches 0 1 {
				 -ascii -integer -real -dictionary \
				 {-command {checkProcCall 2}} -increasing \
				 -decreasing {-index checkIndex}
			         } {}
			     } \
	    		     {checkSimpleArgs 1 1 {checkList}} \
			     1
			}
	namespace	{checkOption {
	    {children		{checkSimpleArgs 0 2 \
		    		    {checkNamespace checkNamespacePattern}}}
	    {code	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {current	    	{checkSimpleArgs 0 0 {}}}
	    {delete	    	{checkSimpleArgs 0 -1 {checkNamespace}}}
	    {eval	    	{checkContext 2 0 {checkSimpleArgs 2 -1 \
		    		    {checkNamespace checkEvalArgs}}}}
	    {export	    	{checkSwitches 0 {
	    		    	    -clear
				} {checkSimpleArgs 0 -1 \
					{checkExportPattern}}}}
	    {forget	    	{checkSimpleArgs 0 -1 {checkNamespacePattern}}}
	    {import	    	{checkSwitches 0 {
	    		    	    -force
				} {checkSimpleArgs 0 -1 \
					{checkNamespacePattern}}}}
	    {inscope	    	{checkSimpleArgs 2 -1 \
		    		   	{checkNamespace checkWord}}}
	    {origin	    	{checkSimpleArgs 1 1 {checkProcName}}}
	    {parent	    	{checkSimpleArgs 0 1 {checkNamespace}}}
	    {qualifiers	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {tail	    	{checkSimpleArgs 1 1 {checkWord}}}
	    {which	    	{checkSwitches 0 {
	    		    	    -command -variable
				} {checkSimpleArgs 1  1 {checkWord}}}}
	} {}}
	registry	{::analyzer::warn nonPortCmd {} {checkSimpleArgs 2  5 {
	    {checkOption {
		{delete 	{checkSimpleArgs 1 2 {checkWord}}}
		{get 		{checkSimpleArgs 2 2 {checkWord}}}
		{keys 		{checkSimpleArgs 1 2 {checkWord checkPattern}}}
		{set 		{checkNumArgs {
		    {1  {checkSimpleArgs 1 1 {checkWord}}}
		    {3  {checkSimpleArgs 3 3 {checkWord}}}
		    {4 {checkSimpleArgs 3 4 {
			checkWord checkWord checkWord
			{checkKeyword 1 { \
			    binary none sz expand_sz dword dword_big_endian \
			    link multi_sz resource_list}}}}}
			}
		    }
		}
		{type 		{checkSimpleArgs 2 2 {checkWord}}}
		{values 	{checkSimpleArgs 1 2 {checkWord checkPattern}}}
	} {}}}}}
	resource	{::analyzer::warn nonPortCmd {} {checkOption {
	    {close 		{checkSimpleArgs 1 1 {checkWord}}}
	    {list 		{checkSimpleArgs 1 2 \
		    		    {checkResourceType checkWord}}}
	    {open 		{checkSimpleArgs 1 2 {
				    checkFileName
				    checkAccessMode
				}}}
	    {read 		{checkSimpleArgs 2 3 \
		    		    {checkResourceType checkWord}}}
	    {types 		{checkSimpleArgs 0 1 {checkWord}}}
	    {write 		{checkSwitches 0 {
				    {-id checkWord} \
				    {-name checkWord} \
				    {-file checkWord}
				} {checkSimpleArgs 2 2 \
					{checkResourceType checkWord}}}}
	} {}}}
	variable	coreTcl::checkVariableCmd
    }

    variable checkers8.1 {
	encoding	{checkSimpleArgs 1 3 {{checkOption {
	    {convertfrom	{checkSimpleArgs 1 2 {checkWord}}}
	    {convertto		{checkSimpleArgs 1 2 {checkWord}}}
	    {names 		{checkSimpleArgs 0 0 {}}}
	    {system		{checkSimpleArgs 0 1 {checkWord}}}
	} {}}}}
	fconfigure	{checkSimpleArgs 1 -1 {checkChannelID {
	    checkConfigure 1 {
		{-blocking checkBoolean}
		{-buffering {checkKeyword 0 {full line none}}}
		{-buffersize checkInt}
		{-eofchar {checkListValues 0 2 {checkWord}}}
		{-encoding {checkWord}}
		{-peername {checkSimpleArgs 0 0 {}}}
		{-mode {checkWord}}
		{-sockname {checkSimpleArgs 0 0 {}}}
		{-translation {checkListValues 0 2 {
		    {checkKeyword 1 {auto binary cr crlf lf}}}}}}
		}
	    }
	}
	lindex		{checkSimpleArgs 2  2 {checkList checkIndexExpr}}
	linsert		{checkSimpleArgs 3 -1 {checkList checkIndexExpr \
				checkWord}}
	lrange		{checkSimpleArgs 3  3 {checkList checkIndexExpr}}
	lreplace	{checkSimpleArgs 3 -1 {checkList checkIndexExpr \
				checkIndexExpr checkWord}}
	regexp		{checkSwitches 1 {
	    		    -nocase -indices -expanded -line -linestop \
			    -lineanchor -about --
			} {checkSimpleArgs 2 -1 \
				{coreTcl::checkRegexp checkWord checkVarName}}}
	string		{checkSimpleArgs 2 -1 {{checkOption {
	    {bytelength		{checkSimpleArgs 1 1 {checkWord}}}
	    {compare 		{checkHeadSwitches 0 2 {
				        -nocase {-length checkInt}
				    } {checkSimpleArgs 2 2 {checkWord}}}}
	    {equal 		{checkHeadSwitches 0 2 {
				        -nocase {-length checkInt}
				    } {checkSimpleArgs 2 2 {checkWord}}}}
	    {first 		{checkSimpleArgs 2 3 \
					{checkWord checkWord checkIndexExpr}}}
	    {index 		{checkSimpleArgs 2 2 \
				    {checkWord checkIndexExpr}}}
	    {is			{checkSimpleArgs 2 -1 {
				    {checkKeyword 0 { \
					alnum alpha ascii boolean digit \
					double false integer lower space \
					true upper wordchar}}
				    {checkHeadSwitches 0 1 {
					-strict {-failindex checkVarName}
				    } {checkSimpleArgs 1 1 {checkWord}}}}}}
	    {last 		{checkSimpleArgs 2 3 \
					{checkWord checkWord checkIndexExpr}}}
	    {length 		{checkSimpleArgs 1 1 {checkWord}}}
	    {map 		{checkHeadSwitches 0 2 {
				        -nocase
				    } {checkSimpleArgs 2 2 {
					coreTcl::checkCharMap checkWord}}}}
	    {match 		{checkHeadSwitches 0 2 {
				        -nocase
				    } {checkSimpleArgs 2 2 {
					checkPattern checkWord}}}}
	    {range 		{checkSimpleArgs 3 3 \
				    {checkWord checkIndexExpr}}}
	    {repeat 		{checkSimpleArgs 2 2 {checkWord checkInt}}}
	    {replace 		{checkSimpleArgs 3 4 {
					checkWord checkIndexExpr
					checkIndexExpr checkWord
				}}}
	    {tolower 		{checkSimpleArgs 1 3 \
				    {checkWord checkIndexExpr}}}
	    {totitle 		{checkSimpleArgs 1 3 \
				    {checkWord checkIndexExpr}}}
	    {toupper 		{checkSimpleArgs 1 3 \
				    {checkWord checkIndexExpr}}}
	    {trim 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimleft 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {trimright 		{checkSimpleArgs 1 2 {checkWord checkWord}}}
	    {wordend 		{checkSimpleArgs 2 2 \
				    {checkWord checkIndexExpr}}}
	    {wordstart 		{checkSimpleArgs 2 2 \
				    {checkWord checkIndexExpr}}}
	} {}}}}
    }

    variable checkers8.2 {
	regsub		{checkSwitches 1 {
	    		    -all -nocase -expanded -line -linestop \
			    -lineanchor -about --
			} {checkSimpleArgs 4 4 \
				{coreTcl::checkRegexp checkWord 
	                                 checkWord checkVarName}
                        }}
    }

    variable checkers8.3 {
	array		{checkSimpleArgs 2 3 {{checkOption {
	    {anymore	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {donesearch	    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {exists	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {get	    {checkSimpleArgs 1 2 {checkVarName checkPattern}}}
	    {names	    {checkSimpleArgs 1 2 {checkVarName checkPattern}}}
	    {nextelement    {checkSimpleArgs 2 2 {checkVarName checkWord}}}
	    {set	    {checkSimpleArgs 2 2 {checkVarName checkList}}}
	    {size	    {checkSimpleArgs 1 1 {checkVarName}}}
	    {startsearch    {checkSimpleArgs 1 1 {checkVarName}}}
	    {unset	    {checkSimpleArgs 1 2 {checkVarName checkPattern}}}
	} {}}}}	
	clock		{checkSimpleArgs 1 6 {{checkOption {
	    {clicks	    {checkSwitches 0 {
		{-milliseconds {}}
	    } {}}}
	    {format	    {checkSimpleArgs 1 5 {
				checkInt
				{checkSwitches 0 {
				    {-format coreTcl::checkClockFormat} 
				    {-gmt checkBoolean}
				} {}}}}
	    }
	    {scan	    {checkSimpleArgs 1 5 {
				checkWord
				{checkSwitches 0 {
				    {-base checkInt}
				    {-gmt checkBoolean}
				} {}}}}
	    }
	    {seconds	    {checkSimpleArgs 0 0 {}}}
	} {}}}}
	fconfigure	{checkSimpleArgs 1 -1 {checkChannelID {
	    checkConfigure 1 {
		{-blocking checkBoolean}
		{-buffering {checkKeyword 0 {full line none}}}
		{-buffersize checkInt}
		{-eofchar {checkListValues 0 2 {checkWord}}}
		{-encoding {checkWord}}
		{-peername {checkSimpleArgs 0 0 {}}}
		{-lasterror {::analyzer::warn nonPortCmd {} {
		    checkSimpleArgs 0 0 {}}}}
		{-mode {checkWord}}
		{-sockname {checkSimpleArgs 0 0 {}}}
		{-translation {checkListValues 0 2 {
		    {checkKeyword 1 {auto binary cr crlf lf}}}}}}
		}
	    }
	}
	file		{checkSimpleArgs 1 -1 {{checkOption {
	    {atime 		{checkSimpleArgs 1 2 {
		checkFileName checkWholeNum}}}
	    {attributes 	{checkSimpleArgs 1 -1 {checkFileName
				{checkConfigure 1 {
				    {-group {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-owner {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-permissions {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-archive {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-hidden {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-longname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-readonly {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-shortname {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-system {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-creator {::analyzer::warn nonPortCmd {} {checkWord}}}
				    {-type {::analyzer::warn nonPortCmd {} {checkWord}}}
				}}}}}
	    {channels 		{checkSimpleArgs 0 1 {checkPattern}}}
	    {copy 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 2 -1 {checkFileName}}}}
	    {delete 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 1 -1 {checkFileName}}}}
	    {dirname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {executable 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {exists 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {extension 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {isdirectory 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {isfile 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {join 		{checkSimpleArgs 1 -1 {checkFileName}}}
	    {lstat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {mkdir 		{checkSimpleArgs 1 -1 {checkFileName}}}
	    {mtime 		{checkSimpleArgs 1 2 {
		checkFileName checkWholeNum}}}
	    {nativename 	{checkSimpleArgs 1 1 {checkFileName}}}
	    {owned 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {pathtype 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readable 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {readlink 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {rename 		{checkSwitches 1 {
				    -force --
	    			} {checkSimpleArgs 2 -1 {checkFileName}}}}
	    {rootname 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {size 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {split 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {stat 		{checkSimpleArgs 2 2 {checkFileName \
		    			checkVarName}}}
	    {tail 		{checkSimpleArgs 1 1 {checkFileName}}}
	    {type 		{checkSimpleArgs 1 1 {checkFileName}}} 
	    {volume 		{checkSimpleArgs 0 0 {}}} 
	    {writable 		{checkSimpleArgs 1 1 {checkFileName}}}
	} {}}}}
	glob		{checkSwitches 1 {
	    {-directory checkFileName}
	    -join
	    -nocomplain 
	    {-path checkFileName}
	    {-types checkWord}
	    --
	} {checkSimpleArgs 1 -1 {checkPattern}}}
	lsort		{checkTailArgs \
			     {checkHeadSwitches 0 1 {
				 -ascii -integer -real -dictionary \
				 {-command {checkProcCall 2}} -increasing \
				 -decreasing {-index checkIndex} -unique
			         } {}
			     } \
	    		     {checkSimpleArgs 1 1 {checkList}} \
			     1
			}
	package		{checkSimpleArgs 1 4 {{checkOption {
	    {forget	 	{checkSimpleArgs 1 1 {checkWord}}}
	    {ifneeded 		{checkSimpleArgs 2 3 \
		    		    {checkWord checkVersion 
	    			    checkBody}}}
	    {names 		{checkSimpleArgs 0 0 {}}}
	    {present 		{checkSwitches 1 {
					-exact
	    			} {checkSimpleArgs 1 2 \
					{checkWord checkVersion}}}}
	    {provide 		{checkSimpleArgs 1 2 {checkWord 
	    			    checkVersion}}}
	    {require 		{checkSwitches 1 {
					-exact
	    			} {checkSimpleArgs 1 2 \
					{checkWord checkVersion}}}}
	    {unknown 		{checkSimpleArgs 0 1 {{checkProcCall 2}}}}
	    {vcompare 		{checkSimpleArgs 2 2 {checkVersion}}}
	    {versions 		{checkSimpleArgs 1 1 {checkWord}}}
	    {vsatisfies 	{checkSimpleArgs 2 2 {checkVersion}}}
	} {}}}}
	pkg_mkIndex	{checkSwitches 1 {-lazy} {checkSimpleArgs 2 -1 {
	    checkFileName checkPattern}}}
	regexp		{checkSwitches 1 {
	                    -nocase -indices -expanded -line -linestop \
		            -lineanchor -about -all -inline \
			    {-start checkInt} --
			} {checkSimpleArgs 2 -1 \
				{coreTcl::checkRegexp checkWord checkVarName}}}
	regsub		{checkSwitches 1 {
	    		    -all -nocase -expanded -line -linestop \
			    -lineanchor -about {-start checkInt} --
			} {checkSimpleArgs 4 4 \
				{coreTcl::checkRegexp checkWord 
	                                 checkWord checkVarName}
                        }}
	scan		{checkSimpleArgs 2 -1 \
			    {checkWord checkWord checkVarName}}
    }

    # The following additional checkers should be added to all versions in
    # order to properly handle the debugger commands.

    variable proCheckers {
	debugger_break	{checkSimpleArgs 0 1 {checkWord}}
	debugger_eval	{checkSwitches 1 {
	    		    {-name checkWord}
			    --
			} {checkSimpleArgs 1 1 {checkBody}}}
	debugger_init	{checkSimpleArgs 0 2 {checkWord checkInt}}
    }

    # Define the set of message types and their human-readable translations. 

    array set messages {
	coreTcl::badTraceOp	{"invalid operation \"%1$s\": should be one or more of rwu" err}
	coreTcl::serverAndPort	{"Option -myport is not valid for servers" err}
	coreTcl::socketArgOpt	{"no argument given for \"%1$s\" option" err}
	coreTcl::socketAsync	{"cannot set -async option for server sockets" err}
	coreTcl::socketBadOpt	{"invalid option \"%1$s\", must be -async, -myaddr, -myport, or -server" err}
	coreTcl::socketServer	{"cannot set -async option for server sockets" err}
	coreTcl::badCharMap	{"string map list should have an even number of elements" err}
	coreTcl::warnEscapeChar {"\"\\%1$s\" is a valid escape sequence in later versions of Tcl." warn upgrade}
	coreTcl::warnNotSpecial {"\"\\%1$s\" has no meaning.  Did you mean \"\\\\%1$s\" or \"%1$s\"?" warn upgrade}
	coreTcl::warnQuoteChar  {"\"\\\" in bracket expressions are treated as quotes" warn upgrade}
	coreTcl::errBadBrktExp  {"the bracket expression is missing a close bracket" err}
	coreTcl::warnY2K	{"\"%%y\" generates a year without a century. consider using \"%%Y\" to avoid Y2K errors." warn}
    }
}

# coreTcl::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer, and adding human-readable messages
#	to the message database.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc coreTcl::init {ver} {
    foreach name [lsort [info vars ::coreTcl::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::coreTcl::scanCmds$ver"} {
	    break
	}
    }
    analyzer::addScanCmds $coreTcl::proScanCmds

    foreach name [lsort [info vars ::coreTcl::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::coreTcl::checkers$ver"} {
	    break
	}
    }
    analyzer::addCheckers $coreTcl::proCheckers
    analyzer::addCheckers [list \
	    \] {::analyzer::warn warnExtraClose {} {checkWord}} \
	    \} {::analyzer::warn warnExtraClose {} {checkWord}}]
    return
}

# coreTcl::getMessage --
#
#	Convert the message type into a human readable
#	string.  
#
# Arguments:
#	type	The message type to be converted.
#
# Results:
#	Return the message string or empty string if the
#	message type is undefined.

proc coreTcl::getMessage {type} {
    variable messages

    if {[info exists messages($type)]} {
	return [lindex $messages($type) 0]
    } else {
	return $type
    }
}

# coreTcl::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc coreTcl::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# Checkers for specific commands --
#
#	Each checker is passed the tokens for the arguments to the command.
#	The name of each checker should be of the form coreTcl::check<Name>,
#	where <name> is the command being checked.
#
# Arguments:
#	tokens		The list of word tokens after the initial
#			command and subcommand names.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.

# coreTcl::checkCompletion

proc coreTcl::checkCompletion {tokens index} {
    # check the completion code for "return -code"

    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkWord $tokens $index]
    }
    if {[catch {incr value}]} {
	return [checkKeyword 1 {ok error return break continue} $tokens $index]
    }
    return [incr index]
}

# coreTcl::checkCharMap
proc coreTcl::checkCharMap {tokens index} {
    # check the map argument of "string map"

    set word [lindex $tokens $index]
    if {[getLiteral $word value]} {
	if {[catch {parse list $value {}} msg]} {
	    logError badList \
		    [list [getLiteralPos $word [lindex $::errorCode 2]] 1] $msg
	} elseif {([llength $msg] & 1)} {
	    logError coreTcl::badCharMap [getTokenRange $word]
	}
    }
    return [checkWord $tokens $index]
}

# coreTcl::checkExprCmd --

proc coreTcl::checkExprCmd {tokens index} {
    set argc [llength $tokens]

    for {set i $index} {$i < $argc} {incr i} {
	set word [lindex $tokens $i]
	if {![isLiteral $word]} {
	    logError warnExpr [getTokenRange $word]
	    return [checkSimpleArgs 1 -1 {checkWord} $tokens $index]
	}
    }

    if {($argc - $index) == 1} {
	return [checkExpr $tokens $index]
    } else {
	# TODO: We could do better here since it is a literal, but we'd need to
	# construct a new word that spans all of the remaining words.
	return [checkSimpleArgs 1 -1 {checkWord} $tokens $index]
    }
}

# coreTcl::checkIfCmd --

proc coreTcl::checkIfCmd {tokens index} {
    set i $index
    set argc [llength $tokens]
    set text {}

    set clause "if"
    set keywordNeeded 0
    while {1} {
	# At this point in the loop, lindex i refers to an expression
	# to test, either for the main expression or an expression
	# following an "elseif".  The arguments after the expression must
	# be "then" (optional) and a script to execute.

	if {$i >= $argc} {
	    set word [lindex [lindex $tokens [expr {$i - 1}]] 1]
	    set end [expr {[lindex $word 0] + [lindex $word 1]}]
	    logError noExpr [list $end 1] $clause
	    return $argc
	}
	checkExpr $tokens $i
	incr i
	if {($i < $argc) \
		&& [getLiteral [lindex $tokens $i] text] \
		&& ($text == "then")} {
	    incr i
	}

	if {$i >= $argc} {
	    set word [lindex [lindex $tokens [expr {$i - 1}]] 1]
	    set end [expr {[lindex $word 0] + [lindex $word 1]}]
	    logError noScript [list $end 1] $clause
	    return $argc
	}
	checkBody $tokens $i
	set keywordNeeded 1
	incr i
	if {$i >= $argc} {
	    # We completed successfully
	    return $argc
	}

	if {[getLiteral [lindex $tokens $i] text] && ($text == "elseif")} {
	    set keywordNeeded 0
	    set clause "elseif"
	    incr i
	    continue
	}
	break
    }

    # Now we check for an else clause
    if {[getLiteral [lindex $tokens $i] text] && ($text == "else")} {
	set clause "else"
	set keywordNeeded 0
	incr i

	if {$i >= $argc} {
	    set word [lindex [lindex $tokens [expr {$i - 1}]] 1]
	    set end [expr {[lindex $word 0] + [lindex $word 1]}]
	    logError noScript [list $end 1] $clause
	    return $argc
	}
    }
    if {($keywordNeeded) || (($i+1) != $argc)} {
	set word [lindex [lindex $tokens [expr {$i - 1}]] 1]
	set end [expr {[lindex $word 0] + [lindex $word 1]}]
	logError warnIfKeyword [list $end 1]
    }
    return [checkBody $tokens $i]
}


# coreTcl::checkForeachCmd --

proc coreTcl::checkForeachCmd {tokens index} {
    set argc [llength $tokens]
    if {($argc < 4) || ($argc % 2)} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }

    # Make sure all odd args except for the last are varnames or lists of
    # varnames.  Only the last argument to the foreach command is a Tcl script.

    while {$index < ($argc - 1)} {
	set word [lindex $tokens $index]
	if {[getLiteral $word literal]} {
	    set index [checkListValues 1 -1 checkVarName $tokens $index]
	} else {
	    set index [checkVarName $tokens $index]
	}
	set index [checkWord $tokens $index]
    }
    return [checkBody $tokens $index]
}

# coreTcl::checkReadCmd --

proc coreTcl::checkReadCmd {tokens index} {
    set argc [llength $tokens]
    if {($argc < 2) || ($argc > 3)} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkSimpleArgs 1 2 {checkChannelID checkInt} $tokens $index]
    }
    if {$value == "-nonewline"} {
	incr index
    }
    return [checkSimpleArgs 1 2 {checkChannelID checkInt} $tokens $index]
}

# coreTcl::checkReturnCmd --

proc coreTcl::checkReturnCmd {tokens index} {
    set argc [llength $tokens]
    while {$index < $argc} {
	set index [checkOption {
	    {-code coreTcl::checkCompletion}
	    {-errorinfo checkWord}
	    {-errorcode checkWord}
	} {checkSimpleArgs 0 1 {checkWord}} $tokens $index]
    }
    return $index
}

# coreTcl::checkSocketCmd --

proc coreTcl::checkSocketCmd {tokens index} {
    set argc [llength $tokens]
    if {$argc < 3} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    
    set server 0
    set async  0
    set myPort 0

    for {} {$index < $argc} {} {
	set word [lindex $tokens $index]
	if {[getLiteral $word literal]} {
	    if {[string index $literal 0] == "-"} {
		if {$literal == "-server"} {
		    if {$async} {
			logError coreTcl::socketAsync \
				[getTokenRange [lindex $tokens $index]]
			return [checkCommand $tokens $index]
		    }
		    set server 1
		    incr index
		    if {$index >= $argc} {
			logError noSwitchArg \
				[getTokenRange [lindex $tokens $index]] \
				$literal
			return [checkCommand $tokens $index]
		    } else {
			set index [checkWord $tokens $index]
		    }
		} elseif {$literal == "-myaddr"} {
		    incr index
		    if {$index >= $argc} {
			logError noSwitchArg \
				[getTokenRange [lindex $tokens $index]] \
				$literal
			return [checkCommand $tokens $index]
		    } else {
			set index [checkWord $tokens $index]
		    }
		} elseif {$literal == "-myport"} {
		    set myPort 1
		    set myPortIndex $index
		    incr index
		    if {$index >= $argc} {
			logError noSwitchArg \
				[getTokenRange [lindex $tokens $index]] \
				$literal
			return [checkCommand $tokens $index]
		    } else {
			set index [checkInt $tokens $index]
		    }
		} elseif {$literal == "-async"} {
		    if {$server} {
			logError coreTcl::socketServer \
				[getTokenRange [lindex $tokens $index]]
			return [checkCommand $tokens $index]
		    }
		    set async 1
		    incr index
		} else {
		    logError badOption \
			    [getTokenRange [lindex $tokens $index]] \
			    "-async, -myaddr, -myport, or -server" $literal
		    return [checkCommand $tokens $index]
		}
	    } else {
		break
	    }
	} else {
	    return [checkCommand $tokens $index]
	}
    }
    if {$server} {
	if {$myPort} {
	    logError coreTcl::serverAndPort \
		    [getTokenRange [lindex $tokens $myPortIndex]]
	    return [checkCommand $tokens $index]
	}
	return [checkSimpleArgs 1 1 {checkInt} $tokens $index]
    } else {
	return [checkSimpleArgs 2 2 {checkWord checkInt} $tokens $index]
    }
}

# coreTcl::checkSourceCmd --

proc coreTcl::checkSourceCmd {tokens index} {
    set argc [llength $tokens]

    if {$argc == 1} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    if {$argc == 2} {
	return [checkFileName $tokens $index]
    } else {
	set word [lindex $tokens $index]
	if {![getLiteral $word value]} {
	    return [checkSimpleArgs 2 3 {checkWord checkWord checkFilename} \
		    $tokens $index]
	}
	incr index 
	if {$value == "-rsrc"} {
	    return [checkSimpleArgs 1 2 {checkWord checkFileName} \
		    $tokens $index] 
	} elseif {$value == "-rsrcid"} {
	    return [checkSimpleArgs 1 2 {checkInt checkFileName} \
		    $tokens $index]
	} else {
	    logError numArgs {}
	    return [checkCommand $tokens $index]
	}
    }
}

# coreTcl::checkSwitchCmd --

proc coreTcl::checkSwitchCmd {tokens index} {
    set end  [llength $tokens]
    set argc [expr {$end - $index}]
    set i $index

    if {$argc < 2} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    
    # The index points at the first argument after the switches
    # The next argument should be the string to switch on.

    set i [checkWord $tokens $i]

    # We are then left with two cases: 1. one argument which
    # need to split into words.  Or 2. a bunch of pattern body
    # pairs.

    if {($i + 1) == $end} {
	# Check to be sure the body doesn't contain substitutions

	set bodyToken [lindex $tokens $i]
	if {![isLiteral $bodyToken]} {
	    return [checkWord $tokens $i]
	}
	
	# If the body token contains backslash sequences, there will
	# be more than one subtoken, so we take the range for the whole
	# body and subtract the braces.  Otherwise it's a "simple" word
	# with only one part and we can get the range from the text
	# subtoken. 

	if {[llength [lindex $bodyToken 2]] > 1} {
	    set range [lindex $bodyToken 1]
	    set range [list [expr {[lindex $range 0] + 1}] \
		    [expr {[lindex $range 1] - 2}]]
	} else {
	    set range [lindex [lindex [lindex $bodyToken 2] 0] 1]
	}

	set script [getScript]
	set i [checkList $tokens $i]
	catch {
	    foreach {pattern body} [parse list $script $range] {
		if {$body == ""} {
		    logError noScript [getTokenRange [lindex $tokens $i]]
		}

		# If the body is not "-", parse it as a command word and pass
		# the result to parseBody.  This isn't quite right, but it
		# should handle the common cases.

		if {$body != "" && [parse getstring $script $body] != "-"} {
		    checkBody [lindex [parse command $script $body] 3] 0
		}
	    }
	}
    } else {
	while {$i < $end} {
	    set i [checkWord $tokens $i]
	    if {$i < $end} {
		if {(![getLiteral [lindex $tokens $i] string] \
			|| $string == "-")} {
		    set i [checkWord $tokens $i]
		} else {
		    set i [checkBody $tokens $i]
		}
	    }
	}
    }
    return $i
}

# coreTcl::checkTraceOp --

proc coreTcl::checkTraceOp {tokens index} {
    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkWord $tokens $index]
    }
    if {![regexp {^[rwu]+$} $value]} {
	logError coreTcl::badTraceOp [getTokenRange $word] $value
    }
    return [incr index]
}

# coreTcl::checkVariableCmd --

proc coreTcl::checkVariableCmd {tokens index} {
    set argc [llength $tokens]
    if {$argc < 1} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    while {$index < $argc} {
	set index [checkVarName $tokens $index]
	if {$index < $argc} {
	    set index [checkWord $tokens $index]
	}
    }
    return $index
}

proc coreTcl::checkUplevelCmd {tokens index} {
    set word [lindex $tokens $index]
    set argc [expr {[llength $tokens] - 1}]

    # If there are more than 1 arguments, and the first is a literal
    # level, then check the remaining args as eval args.  Otherwise
    # check all args as eval args.

    if {($argc > 1) \
	    && [getLiteral [lindex $tokens $index] literal] \
	    && [regexp {^\#?[0-9]+$} $literal]} {
	incr index
    }
    return [checkEvalArgs $tokens $index]
}


proc coreTcl::checkUpvarCmd {tokens index} {
    set word [lindex $tokens $index]
    set argc [expr {[llength $tokens] - 1}]

    # If there are odd numbers of arguments, assume that the first argument
    # is a level.  Check to see if the level is a valid value.

    if {round( fmod($argc, 2))} {
	if {[getLiteral $word level]} {
	    if {[string index $level 0] == "#"} {
		set level [string range $level 1 end]
	    }
	    if {[catch {incr level}]} {
		logError badLevel [getTokenRange $word] $level
	    }
	    incr index
	} else {
	    set index [checkWord $tokens $index]
	}
    }

    foreach {orig new} [lrange $tokens $index end] {
	if {[getLiteral $orig literal]} {
	    checkVariable $literal [getTokenRange $orig]
	} else {
	    checkWord $tokens $index
	}
	incr index
	if {$new == ""} {
	    logError numArgs {}
	} else {
	    checkVarName $tokens $index
	}
	incr index
    }
    return $index
}


# coreTcl::checkSwitchCmd --

proc coreTcl::checkCaseCmd {tokens index} {
    set end  [llength $tokens]
    set argc [expr {$end - $index}]
    set i $index

    logError warnDeprecated {} "switch" 

    if {$argc < 2} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    
    # The index points at the first argument after the switches
    # The next argument should be the string to switch on.

    set i [checkWord $tokens $i]

    # Look for the case specific keyword "in"

    if {([getLiteral [lindex $tokens $i] keyword]) && ($keyword == "in")} {
	incr i
    }

    # We are then left with two cases: 1. one argument which
    # need to split into words.  Or 2. a bunch of pattern body
    # pairs.

    if {($i + 1) == $end} {
	# Check to be sure the body doesn't contain substitutions

	set bodyToken [lindex $tokens $i]
	if {![isLiteral $bodyToken]} {
	    return [checkWord $tokens $i]
	}
	
	# If the body token contains backslash sequences, there will
	# be more than one subtoken, so we take the range for the whole
	# body and subtract the braces.  Otherwise it's a "simple" word
	# with only one part and we can get the range from the text
	# subtoken. 

	if {[llength [lindex $bodyToken 2]] > 1} {
	    set range [lindex $bodyToken 1]
	    set range [list [expr {[lindex $range 0] + 1}] \
		    [expr {[lindex $range 1] - 2}]]
	} else {
	    set range [lindex [lindex [lindex $bodyToken 2] 0] 1]
	}

	set script [getScript]
	set i [checkList $tokens $i]
	catch {
	    foreach {pattern body} [parse list $script $range] {
		if {$body == ""} {
		    logError noScript [getTokenRange [lindex $tokens $i]]
		}

		# If the body is not "-", parse it as a command word and pass
		# the result to parseBody.  This isn't quite right, but it
		# should handle the common cases.

		if {$body != "" && [parse getstring $script $body] != "-"} {
		    checkBody [lindex [parse command $script $body] 3] 0
		}
	    }
	}
    } else {
	while {$i < $end} {
	    set i [checkWord $tokens $i]
	    if {$i < $end} {
		if {(![getLiteral [lindex $tokens $i] string] \
			|| $string == "-")} {
		    set i [checkWord $tokens $i]
		} else {
		    set i [checkBody $tokens $i]
		}
	    }
	}
    }
    return $i
}

# coreTcl::checkRegexp --

proc coreTcl::checkRegexp {tokens index} {
    # When upgrading Tcl 8.0 to 8.1, warn about possible incompatabilities
    # from the old regexp packages.  The new regexp package defines many
    # new special chars that follow backslashes.  As well, backslashes in
    # brackets have changed meaning.  They are now quotes, not a simple char.
    # The three types of warnings are:
    # 
    # (1) Backslash followed by 8.1 ESCAPE char:
    #      Warn about change of behavior in 8.1.
    #
    # (2) Backslash followed by non-special char in 8.0 or 8.1.
    #      Warn them this could be superfluous or missing another '\'.
    #
    # (3) Inside brackets, odd number of backslashes.
    #      Warn that the \ is now a quote and not a char.
    
    set escapeChar {
	a A b B c d D e f
	n m M r t u U v
	s S w W x y Y Z 0
    }
    set specialChar {\"\*+?.^$()[]|{}}
    
    set word  [lindex $tokens $index]
    set range [getTokenRange $word]

    if {![getLiteral $word value]} {
	return [checkWord $tokens $index]
    }

    while {$value != {}} {
	set bsFirst [string first "\\" $value]
	set bkFirst [string first "\[" $value]
	
	if {($bsFirst < 0) && ($bkFirst < 0)} {
	    # No backslashes or brackets.  This is a simple expression.
	    # Do noting and return.

	    break
	} elseif {($bkFirst == -1) || (($bsFirst < $bkFirst) && ($bsFirst != -1))} {
	    # Found a backslash first.  Check according to (1) and (2).
	    # When this body is done, 'i' should point to the char
	    # immediately after the backslashed characyer.

	    set i [expr {$bsFirst + 1}]
	    set c [string index $value $i]
	    
	    if {[lsearch -exact $escapeChar $c] >= 0} {
		# The next character is an escape char in Tcl8.1.
		# Warn the user that this regexp will change in 8.1.

		if {[configure::getCheckVersion coreTcl] < 8.1} {
		    logError coreTcl::warnEscapeChar $range $c
		}

	    } elseif {[string first $c $specialChar] < 0} {
		# The next character has no meaning when quoted.
		# Generate an error stating that the backslash has no
		# purpose or could be missing an additional backslash.

		logError coreTcl::warnNotSpecial $range $c
	    }
	    incr i
	} else {
	    # Found a open bracket first.  Check according to (3).
	    # When this body is done, 'i' should point to the char 
	    # just after the closing bracket.

	    set v [string range $value $bkFirst end]

	    # Extract the string within the brackets.  Strip off leading
	    # ^\]s or \]s to simplify the scan.  If there are backslashes
	    # inside of the brackets, check for odd numger of brackets. 
	    # Otherwise bump the index to the char after the trailing
	    # bracket and continue.  

	    set exp  {}
	    set brkt {}

	    if {[regexp {\[(\]|\^\]|)([^\]]*)(\])?} $v match lead exp brkt]} {
		# Only check for quotes inside of brackets for 8.0 or older.
		# If there is an odd number of backslashes in a row, warn the
		# user that the semantics will change in 8.1.

		if {[configure::getCheckVersion coreTcl] < 8.1} {
		    set numBs 0
		    for {set i 0} {$i < [string length $exp]} {incr i} {
			if {[string index $exp $i] == "\\"} {
			    incr numBs
			} else {
			    if {[expr {$numBs % 2}]} {
				logError coreTcl::warnQuoteChar $range
			    }
			    set numBs 0
			}
		    }
		    if {[expr {$numBs % 2}]} {
			logError coreTcl::warnQuoteChar $range
		    }
		}
		set i [expr {$bkFirst + [string length $match]}]
	    } else {
		# We should never get here, but if we do it is probably
		# because the regular expression above was ill-formed.

		puts "internal error: the expression could not be parsed."
		return [checkWord $tokens $index]
	    }
	    
	    # If the regexp above did not find a closing bracket, the 
	    # brkt variable will be an empty string.  Warn the use 
	    # they have a poorly formed bracket expression.

	    if {$brkt == {}} {
		logError coreTcl::errBadBrktExp $range
	    }
	} 

	# The next backslash or bracket expression has just been checked.
	# Modify the "value" string to point to the next char to check.
	# The 'i' variable shouldbe pointing to the next char.

	set value [string range $value $i end]

    }
    return [incr index]
}

# coreTcl::checkClockFormat --

proc coreTcl::checkClockFormat {tokens index} {
    set word [lindex $tokens $index]
    if {![getLiteral $word value]} {
	return [checkWord $tokens $index]
    }
    if {[string first "%y" $value] >= 0} {
	logError coreTcl::warnY2K [getTokenRange $word]
    }
    return [incr index]
}
