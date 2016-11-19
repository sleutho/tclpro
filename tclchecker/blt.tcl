# blt.tcl --
#
#	This file contains type and command checkers for the BLT
#	commands.
#
# Copyright (c) 1998-2000 Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: blt.tcl,v 1.3 2000/10/31 23:30:53 welch Exp $

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide blt 1.0

namespace eval blt {
    # scanCmdsX.X --
    # Define the set of commands that need to be recuresed into when 
    # generating a list of user defiend procs, namespace and Class 
    # contexts and procedure name resolutions info.

    variable scanCmds2.4 {
    }

    # checkersX.X --
    # Define the set of command-specific checkers used by this package.

    # itcl 1.5 -> Tcl 7.3
    variable checkers2.4 {
 	barchart		{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-background -borderwidth -buttonmargin -bufferelements -cursor
		-font -halo -height -invertxy -justify -leftmargin
		-plotbackground -plotborderwidth -plotpadx -plotpady
		-plotrelief -relief -rightmargin -takefocus -tile -title
		-topmargin -width
	    } {
		{-barmode  {checkKeyword 1 {normal aligned overlap stacked}}}
		{-barwidth        {blt::checkBarCoords}}
	    }}
	}}
 	beep			{checkSimpleArgs 0 1 {
	                            {blt::checkIntRange -100 100}
	                        }}
 	bgexec			{checkSimpleArgs 2 -1 {
	    checkVarRef
	    {checkSwitches 0 {
		{-error 	{checkVarName}}
		{-keepnewline	{checkBoolean}}
		{-killsignal	{blt::checkBgexecSig}}
		{-lasterror 	{checkVarName}}
		{-lastoutput 	{checkVarName}}
		{-output 	{checkVarName}}
		{-onerror	{checkWord}}
		{-onoutput	{checkWord}}
		{-update 	{checkVarName}}
	    } {checkSimpleArgs 1 -1 {checkWord}}}
	}}
 	bitmap			{checkSimpleArgs 2 -1 {{checkOptions {
	    {compose	{checkSimpleArgs 2 -1 {
		checkWord
		checkWord
		checkSwitches 0 {
		    {-font	{checkFont}}
		    {-rotate	{checkFloat}}
		    {-scale	{checkFloat}}
		} {}}}
	    }
	    {define	{checkSimpleArgs 2 -1 {
		checkWord
		checkWord
		checkSwitches 0 {
		    {-rotate	{checkFloat}}
		    {-scale	{checkFloat}}
		} {}}}
	    }
	    {data	{checkSimpleArgs 1 1 {checkWord}}}
	    {exists	{checkSimpleArgs 1 1 {checkWord}}}
	    {height	{checkSimpleArgs 1 1 {checkWord}}}
	    {source	{checkSimpleArgs 1 1 {checkWord}}}
	    {width	{checkSimpleArgs 1 1 {checkWord}}}
	} {}}}}
 	bltdebug		{checkSimpleArgs 0 1 {checkLevel}}
 	busy			{checkSimpleArgs 2 -1 {{checkOptions {
	    {configure	{checkSimpleArgs 1 -1 {
		checkWinName checkWord
	    }}}
	    {forget	{checkSimpleArgs 1 -1 {checkWinName}}}
	    {isbusy	{checkSimpleArgs 1  1 {checkPattern}}}
	    {hold	{checkSimpleArgs 1 -1 {
		checkWinName 
		{checkSwitches 0 {
		    {-cursor	{checkCursor}}
		} {}}
	    }}}
	    {release	{checkSimpleArgs 1 -1 {
		checkWinName
		checkWord
	    }}}
	    {status	{checkSimpleArgs 1 1 {checkWinName}}}
	    {windows	{checkSimpleArgs 1  1 {checkPattern}}}
	} {}}}}
 	cutbuffer		{checkSimpleArgs 2 3 {{checkOptions {
	    {get	{checkSimpleArgs 0 1 {blt::checkIntRange  0 7}}}
	    {rotate	{checkSimpleArgs 0 1 {blt::checkIntRange -7 7}}}
	    {set	{checkSimpleArgs 1 2 {
		checkWord
		{blt::checkIntRange 0 7}
	    }}}
	} {}}}}
 	drag&drop		{checkSimpleArgs 1 -1 {{checkOptions {
	    {active	{checkSimpleArgs 0 0 {}}}
	    {drop	{checkSimpleArgs 3 3 {checkWinName checkInt}}}
	    {drag	{checkSimpleArgs 3 3 {checkWinName checkInt}}}
	    {errors	{checkSimpleArgs 1 1 {checkWord}}}
	    {location	{checkNumArgs {
		{0	{}}
		{2	{checkSimpleArgs 2 2 {checkInt}}}
	    }}}
	    {source	{checkSimpleArgs 0 -1 {
			    checkWinName
			    {blt::checkDragNDrop source}
	    }}}
	    {target	{checkSimpleArgs 0 -1 {
			    checkWinName
			    {blt::checkDragNDrop target}
	    }}}
	    {token	{checkSimpleArgs 1 1 {checkWinName}}}
	} {}}}}
 	graph			{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-background -borderwidth -buttonmargin -bufferelements -cursor
		-font -halo -height -invertxy -justify -leftmargin
		-plotbackground -plotborderwidth -plotpadx -plotpady 
		-plotrelief -relief -rightmargin -takefocus -tile -title
		-topmargin -width
	    } {}}
	}}
 	hierbox			{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-background -borderwidth -cursor -exportselection
		-font -foreground -height -highlightbackground
		-highlightcolor -highlightthickness -relief
		-selectbackground -selectborderwidth -selectforeground
		-takefocus -tile -width -xscrollcommand -yscrollcommand
	    } {
		{-closecommand			{checkWord}}
		{-closerelief			{checkRelief}}
		{-dashes			{checkInt}}
		{-gadgetactivebackground	{checkColor}}
		{-gadgetactiveforeground	{checkColor}}
		{-gadgetbackground		{checkColor}}
		{-gadgetborderwidth		{checkPixels}}
		{-gadgetforeground		{checkColor}}
		{-gadgets			{checkListValues 0 2 {
		    				    checkWord
						}}}
		{-linecolor			{checkColor}}
		{-linewidth			{checkPixels}}
		{-opencommand			{checkWord}}
		{-openrelief			{checkRelief}}
		{-scrolltile			{checkBoolean}}
		{-separator			{checkWord}}
		{-trimleft			{checkWord}}
	    }}
	}}
 	htext			{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-background -cursor -font -foreground -height -linespacing
		-text -xscrollcommand -xscrollunits -yscrollcommand 
		-yscrollcommand -width
	    } {
		{-filename	{checkFileName}}
		{-specialchar	{checkInt}}
	    }}
	}}
 	spline			{checkSimpleArgs 5 5 {{checkOptions {
	    {natural	{checkSimpleArgs 4 4 {checkInt}}}
	    {quadratic	{checkSimpleArgs 4 4 {checkInt}}}
	} {}}}}
 	stripchart		{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-background -borderwidth -buttonmargin -bufferelements -cursor
		-font -halo -height -invertxy -justify -leftmargin
		-plotbackground -plotborderwidth -plotpadx -plotpady 
		-plotrelief -relief -rightmargin -takefocus -tile -title
		-topmargin -width
	    } {}}
	}}
 	table			{checkOptions {
	    {arrange	{checkSimpleArgs 1 1 {checkWinName}}}
	    {cget	{blt::checkTableCget}}
	    {configure	{blt::checkTableOptions}}
	    {extents	{checkSimpleArgs 2  2 {checkWinName checkWholeNum}}}
	    {forget	{checkSimpleArgs 1 -1 {checkWinName}}}
	    {info	{checkSimpleArgs 2  2 {checkWinName checkWholeNum}}}
	    {locate	{checkSimpleArgs 3  3 {checkWinName checkInt}}}
	    {masters	{checkSwitches 0 {
		{-pattern	{checkPattern}}
		{-slave		{checkWinName}}
	    } {}}}
	    {search	{checkSimpleArgs 1 -1 {
		coreTk::checkWinName
		{checkSwitches 0 {
		    {-pattern	{checkPattern}}
		    {-span	{checkWholeNum}}
		    {-start	{checkWholeNum}}
		} {}}
	    }}}
	} {blt::checkTableOptions}}
 	tabset			{checkSimpleArgs 1 -1 {
	    coreTk::checkWinName
	    {coreTk::checkWidgetOptions 0 {
		-activebackground -activeforeground -background -borderwidth
		-cursor	-font -foreground -height -highlightbackground
		-highlightcolor -highlightthickness -relief -scrollcommand  
		-selectbackground -selectborderwidth -selectforeground
		-takefocus -tile -width
	    } {
		{-dashes			{checkListValues 0 11 {
		    				    checkByteNum
						}}}
		{-gap				{checkInt}}
		{-pageheight			{checkPixels}}
		{-pagewidth			{checkPixels}}
		{-rotate			{checkFloat}}
		{-samewidth			{checkBoolean}}
		{-scrollincrement		{checkPixels}}
		{-scrolltile			{checkBoolean}}
		{-separator			{checkWord}}
		{-trimleft			{checkWord}}
		{-selectpad			{checkPixels}}
		{-selectcommand			{checkWord}}
		{-side				{checkKeyword 1 {
		    				    left right top bottom
						}}}
		{-tabbackground			{checkColor}}
		{-tabborderwidth		{checkPixels}}
		{-tabforeground			{checkColor}}
		{-tabrelief			{checkRelief}}
		{-textside			{checkKeyword 1 {
		    				    left right top bottom
						}}}
		{-tiers				{checkWholeNum}}
	    }}
	}}
 	tilebutton		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -default
		-disabledforeground -fg -font -foreground -height
		-highlightbackground -highlightcolor -highlightthickness -image
		-justify -padx -pady -relief -takefocus -text -textvariable
		-underline -variable -width -wraplength
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-state      {checkKeyword 1 {normal active disabled}}}
	    }}
	}}
 	tilecheckbutton		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -image -indicatoron -justify -offvalue
		-onvalue -padx -pady -relief -selectcolor -selectimage
		-takefocus -text -textvariable -underline -variable -width
		-wraplength
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-selector   {::analyzer::warn warnUnsupported "-selectcolor" \
			checkColor}}
		{-state      {checkKeyword 1 {normal active disabled}}}
	    }}
	}}
 	tileframe		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -colormap -container
		-cursor -height -highlightbackground -highlightcolor
		-highlightthickness -relief -takefocus -visual -width
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-geometry   {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}
	    }}
	}}
 	tilelabel		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-anchor -background -bd -bg -bitmap -borderwidth -cursor -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -image -justify -padx -pady -relief
		-takefocus -text -textvariable -underline -width -wraplength
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
	    }}
	}}
 	tileradiobutton		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -image -indicatoron -justify -padx -pady
		-relief -selectcolor -selectimage -takefocus -text
		-textvariable -underline -value -variable -width -wraplength
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-selector   {::analyzer::warn warnUnsupported "-selectcolor" \
			checkColor}}
		{-state      {checkKeyword 1 {normal active disabled}}}
	    }}
	}}
 	tilescrollbar		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activerelief -background
		-bd -bg -borderwidth -command -cursor -elementborderwidth
		-highlightbackground -highlightcolor -highlightthickness -jump
		-orient -relief -repeatdelay -repeatinterval -takefocus
		-troughcolor -width
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-activeforeground {::analyzer::warn warnUnsupported \
			"-activebackground" checkColor}}
		{-foreground {::analyzer::warn warnUnsupported \
			"-background" checkColor}}
	    }}
	}}
 	tiletoplevel		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -colormap -container
		-cursor -height -highlightbackground -highlightcolor
		-highlightthickness -menu -relief -screen -takefocus -use
		-visual -width
	    } {
		{-activetile {checkWord}}
		{-tile       {checkWord}}
		{-geometry   {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}
	    }}
	}}
 	vector			{checkSimpleArgs 1 -1 {{checkOptions {
	    {create	{checkVecCreate}}
	    {destroy	{checkSimpleArgs 1 -1 {checkWord}}}
	    {expr	{checkVecExpr}}
	    {names	{checkSimpleArgs 0 1 {checkPattern}}}
	} {}}}}
 	watch			{checkSimpleArgs 1 -1 {{checkOptions {
	    {activate	{checkSimpleArgs 1  1 {checkWord}}}
	    {configure	{checkSimpleArgs 1 -1 {
		checkWord
		checkSwitches 0 {
		    {-active	{checkBoolean}}
		    {-postcmd	{checkWord}}
		    {-precmd	{checkWord}}
		    {-maxlevel	{checkWholeNum}}
		} {}}
	    }}
	    {create	{checkSimpleArgs 1 -1 {
		checkWord
		checkSwitches 0 {
		    {-active	{checkBoolean}}
		    {-postcmd	{checkWord}}
		    {-precmd	{checkWord}}
		    {-maxlevel	{blt::checkMaxLevel}}
		} {}}
	    }}
	    {deactivate	{checkSimpleArgs 1  1 {checkWord}}}
	    {delete	{checkSimpleArgs 1  1 {checkWord}}}
	    {info	{checkSimpleArgs 1  1 {checkWord}}}
	    {names	{checkSimpleArgs 0  1 {{checkKeyword 1 {
		    				    left right top bottom
	                                      }}}
	    }}
	} {}}}}
 	winop			{checkSimpleArgs 1 -1 {{checkOptions {
	    {lower	{checkSimpleArgs 0 -1 {checkWinName}}}
	    {map	{checkSimpleArgs 0 -1 {checkWinName}}}
	    {move	{checkSimpleArgs 3  3 {checkWinName checkInt}}}
	    {raise	{checkSimpleArgs 0 -1 {checkWinName}}}
	    {snap	{checkSimpleArgs 2  2 {checkWinName checkWord}}}
	    {unmap	{checkSimpleArgs 0 -1 {checkWinName}}}
	    {warpto	{checkSimpleArgs 0 -1 {checkWinName}}}
	} {}}}}
    }

    # messages --
    # Define the set of message types and their human-readable translations. 

    variable messages
    array set messages {
	blt::badIntRange	{"invalid integer range, shoud be an integer between %1$s and %2$s" err}
	blt::badSignal		{"invalid mnemonic signal" err}
	blt::badSignalInt	{"invalid signal integer,, should be between 1 and 32" err}

    }

    # BLT specific widgets options and associated checkers.  These
    # values are registered in the analyzer when BLT is initialized.

    variable bltWidgetOptions {
	-buttonmargin    checkPixels
	-bufferelements  checkBoolean
	-halo            checkPixels
	-invertxy        checkBoolean
	-leftmargin      checkPixels
	-linespacing	 checkPixels
	-plotbackground  checkColor
	-plotborderwidth checkPixels
	-plotpadx        blt::checkPlotPad
	-plotpady        blt::checkPlotPad
	-plotrelief      checkRelief
	-rightmargin     checkPixels
	-tile            checkWord
	-title           checkWord
	-topmargin       checkPixels
    }

    # Mnemonic signals used by the BLT bgexec command for the "-killsignal"
    # option checker.

    variable bltSignals {
	SIGABRT SIGALRM SIGBUS SIGCHLD SIGCLD SIGCONT SIGEMT SIGFPE SIGHUP
	SIGILL SIGINT SIGIO SIGIOT SIGKILL SIGLOST SIGPIPE SIGPOLL SIGPROF
	SIGPWR SIGQUIT SIGSEGV SIGSTOP SIGSYS SIGTERM SIGTRAP SIGTSTP
	SIGTTIN SIGTTOU SIGURG SIGUSR1 SIGUSR2 SIGVTALRM SIGWINCH SIGXCPU
	SIGXFSZ
    }
}

# blt::init --
#
#	Initialize this analyzer package by loading the corresponding
#	checkers into the analyzer.
#
# Arguments:
#	ver	The requested checker version to load.
#
# Results:
#	None.

proc blt::init {ver} {
    # Add any commands that need to be scanned form proc definitions

    foreach name [lsort [info vars ::blt::scanCmds*]] {
	analyzer::addScanCmds [set $name]
	if {$name == "::blt::scanCmds$ver"} {
	    break
	}
    }

    # Add the BLT command checkers.

    foreach name [lsort [info vars ::blt::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::blt::checkers$ver"} {
	    break
	}
    }

    # Add the BLT specific set of widget options.

    analyzer::addWidgetOptions $blt::bltWidgetOptions
    return
}

# blt::getMessage --
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

proc blt::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# blt::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc blt::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# Checkers for specific commands --
#
#	Each checker is passed the tokens for the arguments to 
#	the command.  The name of each checker should be of the
#	form blt::check<Name>Cmd, where <name> is the command
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


proc blt::checkBarCoords {tokens index} {
    #TO DO: Find out what "graphic coordinates" means...

    return [checkFloat $tokens $index]
}

proc blt::checkBgexecSig {tokens index} {
    variable bltSignals
    
    # Verify that the word is either an integer between 1 and 32 or
    # a mnemonic string in the bltSignals list.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[catch {incr literal 0}]} {
	    # The literal is not an integer, check to see if the string
	    # is a known mnemonic signal.

	    if {[lsearch $bltSignals $literal] == -1} {
		logError blt::badSignal [getTokenRange $word]
	    }
	} elseif {($literal < 1) || ($literal > 32)} {
	    # The literal was a valid integer, but it was not in the
	    # correct range.

	    logError blt::badSignalInt [getTokenRange $word]
	}
	incr index
    } else {
	set index [checkWord $tokens $index]
    }
    return $index
}

proc blt::checkDragNDrop {which tokens index} {
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	incr index

	if {$literal == "handler"} {
	    # Both source and target D&D options treat this option
	    # identically.  Check for optional "dataTypes", commands
	    # and command arguments.

	    set index [checkCommand $tokens $index]
	} elseif {($literal == "handle") && ($which == "target")} {
	    # This is a target only option.  Check for a required 
	    # "dataType" and an optional value.

	    set index [checkSimpleArgs 1 2 {checkWord} $tokens $index]
	} elseif {$which == "target"} {
	    # This is a target only checker.  If the D&D option is target
	    # and the previous options (handler and handle) did not match,
	    # then there should be no more arguments.

	    set index [checkSimpleArgs 0 0 {} $tokens $index]
	} else {
	    # This is a source only checker.  Check for the existence
	    # of source specific options.

	    set index [checkSwitches2 0 {
		{-button	{blt::checkIntRange 1 5}}
		{-packagecmd	{checkWord}}
		{-rejectbg	{checkColor}}
		{-rejectfg	{checkColor}}
		{-rejectstipple	{checkWord}}
		{-selftarget	{checkBoolean}}
		{-send		{checkListValues 1 -1 {checkWord}}}
		{-sitecmd	{checkWord}}
		{-tokenanchor	{checkKeyword 0 {n ne e se s sw w nw center}}}
		{-tokenbg	{checkColor}}
		{-tokenborderwidth {checkPixel}}
		{-tokencursor	{checkCursor}}
	    } {} $tokens $index]
	}
    } else {
	set index [checkCommand $tokens $index]
    }
    return $index
}

proc blt::checkIntRange {start stop tokens index} {
    # Verify the value is an integer between "start" and "stop."

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[catch {incr literal 0}] \
		|| ($literal < $start) \
		|| ($literal > $stop)} {
	    logError blt::badIntRange $start $stop [getTokenRange $word]
	}
	incr index
    } else {
	set index [checkWord $tokens $index]
    }
    return $index
}

proc blt::checkPlotPad {tokens index} {
    # Verify the word is a list of one or two integers.

    return [checkListValues 1 2 {checkInt} $tokens $index]
}

proc blt::checkTableCget {tokens index} {
    set index [checkWinName $tokens $index]

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[regexp {C[0-9]+$} $literal]} {
	    # Check column options.

	    set index [checkSimpleArgs 1 1 {
		checkConfigure 1 {
		    -height
		    -pady
		    -resize
		}
	    } $tokens $index]
	} elseif {[regexp {R[0-9]+$} $literal]} {
	    # Check row options.
	    
	    set index [checkSimpleArgs 1 1 {
		checkConfigure 1 {
		    -padx
		    -resize
		    -width
		} 
	    } $tokens $index]
	} elseif {[string match .* $literal]} {
	    # Check slave options.

	    set index [checkSimpleArgs 1 1 {
		checkConfigure 1 {
		    -anchor
		    -columnspan
		    -columnweight
		    -fill
		    -ipadx
		    -ipady
		    -padx
		    -pady
		    -reqheight
		    -reqwidth
		    -rowspan
		    -rowweight
		}
	    } $tokens $index]
	} else {
	    # Check table options.

	    set index [checkSimpleArgs 1 1 {
		checkConfigure 1 {
		    -columns
		    -padx
		    -pady
		    -propagate
		    -rows
		} 
	    } $tokens $index]
	}
    } else {
	# We're SOL since we cannot determine which of the
	# four possible option sets to check.  One of the 
	# many reasons why overloading a Tcl command sucks.

	set index [checkCommand $tokens $index]
    }
}

proc blt::checkTableOptions {tokens index} {
    set index [checkWinName $tokens $index]

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[regexp {C[0-9]+$} $literal]} {
	    # Check column options.

	    set index [checkConfigure 0 {
		{-height	{checkListValues 0 3 {checkFloat}}}
		{-pady		{blt::checkPlotPad}}
		{-resize	{checkKeyword 0 {none expand shrink both}}}
	    } $tokens $index]
	} elseif {[regexp {R[0-9]+$} $literal]} {
	    # Check row options.
	    
	    set index [checkConfigure 0 {
		{-padx		{blt::checkPlotPad}}
		{-resize	{checkKeyword 0 {none expand shrink both}}}
		{-width		{checkListValues 0 3 {checkFloat}}}
	    } $tokens $index]
	} elseif {[string match .* $literal]} {
	    # Check slave options.

	    set index [checkConfigure 0 {
		{-anchor	{checkKeyword 0 {n ne e se s sw w nw center}}}
		{-columnspan	{checkWholeNum}}
		{-columnweight	{checkKeyword 0 {normal none full}}}
		{-fill		{checkKeyword 0 {none x y both}}}
		{-ipadx		{checkPixels}}
		{-ipady		{checkPixels}}
		{-padx		{blt::checkPlotPad}}
		{-pady		{blt::checkPlotPad}}
		{-reqheight	{checkListValues 0 3 {checkFloat}}}
		{-reqwidth	{checkListValues 0 3 {checkFloat}}}
		{-rowspan	{checkWholeNum}}
		{-rowweight	{checkKeyword 0 {normal none full}}}
	    } $tokens $index]
	} else {
	    # Check table options.

	    set index [checkConfigure 0 {
		{-columns	{checkWholeNum}}
		{-padx		{blt::checkPlotPad}}
		{-pady		{blt::checkPlotPad}}
		{-propagate	{checkBoolean}}
		{-rows		{checkWholeNum}}
	    } $tokens $index]
	}
    } else {
	# We're SOL since we cannot determine which of the
	# four possible option sets to check.  One of the 
	# many reasons why overloading a Tcl command sucks.

	set index [checkCommand $tokens $index]
    }
}


