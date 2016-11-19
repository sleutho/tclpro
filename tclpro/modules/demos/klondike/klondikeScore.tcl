#!/usr/bin/wish -f

######################################################################
#
# klondikeScore.tcl
#
# Copyright (C) 1993-1996 by John Heidemann <johnh@isi.edu>
# See the file "license.terms" for information on usage and redistribution of this file.  See the main klondike file for a full copyright
# notice.
#
# $Id: klondikeScore.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $
#
######################################################################

set rcsid(klondikeScore.tcl) {$Id: klondikeScore.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $}



set score(scoreFileVersion) 758073443
set score(scoreFileHeader) "klondike score file version $score(scoreFileVersion)"

# this is used in making the writeScores cookie
set score(startTime) [getclock]


proc reportError {where error} {
	global table errorInfo errorCode

	set padValue $table(padValue)

	# Uncomment to enable standard Tk error handling mechanism.
	# return -code error -errorinfo $errorInfo -errorcode $errorCode $error

	set w ".error"
	catch {unmenuHelp $w}

	toplevel $w
	wmConfig $w "Klondike--error"
	wm transient $w .
	grab set $w

	frame $w.top

	label $w.top.icon -bitmap error
	pack $w.top.icon -padx $padValue -side left
	message $w.top.msg -text $error -width 4i
	pack $w.top.msg -padx $padValue -side right
	button $w.ok -text OK -padx [expr { 2*$padValue } ] -command "unmenuHelp $w"
	pack $w.top $w.ok -side top -padx $padValue -pady $padValue
}


proc readScores {scoreMethod} {
	global table errorCode score

	if { $score(writeScores) == 0 } {
		# not allowed disk access.
		if { [info exists score(list,$scoreMethod)] == 0} {
			set score(list,$scoreMethod) ""
		}
		return
	}

	set catchval [catch {
			set score(list,$scoreMethod) ""
			set f [open "$score(scorefile).$scoreMethod" r]
			while {[gets $f line] >= 0} {
				lappend score(list,$scoreMethod) $line
			}
			close $f
			if { [llength $score(list,$scoreMethod)] > 0 } {
				if {[lindex $score(list,$scoreMethod) 0] !=
						$score(scoreFileHeader) } {
					set score(list,$scoreMethod) ""
					error "Old version of score file.\nHigh scores reset."
				}
				set score(list,$scoreMethod) [lrange $score(list,$scoreMethod) 1 end]
			}
		} error]
	if { $catchval == 0 } {
		return
	}
	switch -exact [lindex $errorCode 1] {
		ENOENT {}
		default { reportError "readScores" $error }
	}
}



proc writeScores {scoreMethod} {
	global table errorCode score

	if { $score(writeScores) == 0 } {
		return
	}

	#
	# The score file is updated optimistically.
	#
	# To write scores atomically without locking
	# we write the file to a tmp file and then use rename
	# to commit our changes.
	#
	# At worst, our change is lost because of concurrent
	# update.  The score file cannot be corrupted, though.
	#
	# NEEDSWORK: We should then check to make sure our
	# update made it and re-try if it didn't.
	#

	# Generate a (almost) guaranteed unique cookie to identify us.
	set cookie "$score(startTime).[random 10000]"

	set newPath "$score(scorefile).$scoreMethod"
	set oldPath "$newPath.$cookie"
	set catchval [catch {
			set f [open $oldPath w]
			puts $f $score(scoreFileHeader)
			foreach i $score(list,$scoreMethod) {
				puts $f $i
			}
			close $f
			# commit
			frename $oldPath $newPath
		} error]
	if { $catchval != 0 } {
		# Try to clean up.
		catch {unlink $oldPath}
		reportError "writeScores" $error
	}
}

proc determineUser {} {
	global score
	global env
	global tcl_platform
    
	# cache the result
	if {[info exists score(user)] && $score(user) != ""}  {
		return $score(user)
	}
	# first try the environment
	# $USER is a bsd-ism
	if { [info exists env(USER)] && $env(USER) != "" } {
		return [set score(user) $env(USER)]
	}
	# $LOGNAME is the svr4-ism
	if { [info exists env(LOGNAME)] && $env(LOGNAME) != "" } {
		return [set score(user) $env(LOGNAME)]
	}
	# $USERNAME is for Windows NT
	if { $tcl_platform(platform) == "windows" && [info exists env(USERNAME)] && $env(USERNAME) != ""} {
		return [set score(user) $env(USERNAME)]
	}
	# If these fail, try whoami.
	# Bug workaround:  under Linux ``who'' is often set to:
	#	johnh
	#	error waiting for process to exit: No child processes
	# (We get the correct results, plus an error message attached.)
	# Work around the problem by taking only the first line here.
	if { [catch {exec "whoami"} who] == 0 } {
		return [set score(user) [lindex $who 0]]
	}

	# Give up.  Ask the user.
	queryUserForName
	global query_user_done
	vwait query_user_done
	return [set score(user)]
}


proc computeNewScoreListEntry {scoreMethod} {
	global table score env

	#
	# Get information for the score
	#
	if { $scoreMethod == "standard" } {
		set scoreValue $score(standardScore)
		set fancyScore $scoreValue
	} else {
		set scoreValue $score(casinoScore)
		set fancyScore "\$$score(casinoScore)"
	}
	# Add to scores to avoid sorting both negative and positive numbers.
	set scoreValue [expr { $scoreValue + 10000 } ]
	if { $scoreValue < 0 } { set scoreValue 0 }
	set scoreClock [getclock]
	set scoreDate [fmtclock $scoreClock "%e-%b-%Y"]
	determineUser
	set scoreName $score(user)
	# Always ASCII sort by score key.
	# Switch the sign by subtracting from 2^30.
	set scoreKey [format "%08d:%08d" $scoreValue [expr { 1073741824-$scoreClock } ]]

	set newListEntry [list $scoreKey \
			 $fancyScore $scoreDate $scoreName $scoreClock]

	return [list $newListEntry $scoreClock]
}


proc updateScoreList {newListEntry scoreMethod} {
	global score table

	readScores $scoreMethod
	set oldScoreList $score(list,$scoreMethod)

	#
	# Add score to score-list.
	# Scorelist format:
	# SortKey(score,clock) value date name clock
	#
	set score(list,$scoreMethod) [lsort -decreasing [linsert $score(list,$scoreMethod) 0 $newListEntry]]
	if { [llength $score(list,$scoreMethod)] > 100 } {
		set score(list,$scoreMethod) [lrange $score(list,$scoreMethod) 0 99]
	}

	#
	# Limit any given user to ten scores on the list.
	#
	set badScores {}
	foreach i $score(list,$scoreMethod) {
		set user [lindex $i 3]
		if { [info exists userCount($user)] == 0 } {
			set userCount($user) 1
		} else {
			incr userCount($user)
		}
		if { $userCount($user) > 10 } {
			lappend badScores $i
		}
	}
	# remove extra scores
	foreach i $badScores {
		set index [lsearch -exact $score(list,$scoreMethod) $i]
		set score(list,$scoreMethod) \
			[lreplace $score(list,$scoreMethod) $index $index]
	}
	
	if { $score(list,$scoreMethod) != $oldScoreList } {
		writeScores $scoreMethod
	}
}


proc computeNewScoreText {scoreMethod} {
	global score table

	if { [info exists table(lastScoreToken)] } {
		set ourScoreToken $table(lastScoreToken)
	} else {
		set ourScoreToken "xxx"
	}
	#
	# Regenerate score-text from score-list.
	#
	set fancyMethod "[string toupper [string index $scoreMethod 0]][string range $scoreMethod 1 end]"
	set score(text,$scoreMethod) "<big>${fancyMethod} Scores</big>\n\n<computer>"
	set j 0
	foreach i $score(list,$scoreMethod) {
		incr j
		set thisClock [lrange $i 4 4]
		set thisText ""
		if { $thisClock == $ourScoreToken } {
			set style "reverse"
		} else {
			set style ""
		}
		if { $style != "" } {
			set thisText "${thisText}<${style}>"
		}
		set thisText "${thisText}[format "%3d" $j].   [format "%8s" [lindex $i 1]]   [lindex $i 2]   [lindex $i 3] "
		if { $style != "" } {
			set thisText "${thisText}</${style}>"
		}
		set score(text,$scoreMethod) "$score(text,$scoreMethod)$thisText\n"
	}
	set score(text,$scoreMethod) "$score(text,$scoreMethod)</computer>"

	if { [llength $score(list,$scoreMethod)] == 0 } {
		set score(text,$scoreMethod) "$score(text,$scoreMethod)No current scores."
	}

	if { $score(writeScores) == 0 } {
		set score(text,$scoreMethod) "$score(text,$scoreMethod)\n<italic>Permanent storage of score file not enabled.</italic>"
	}
}





proc registerNewScore {showScores} {
	global table

	set scoreMethod $table(scoringMethod)

	#
	# Figure the new data.
	#
	set foo [computeNewScoreListEntry $scoreMethod]
	set newScoreListEntry [lindex $foo 0]
	set table(lastScoreToken) [lindex $foo 1]

	#
	# Add it to old scores.
	#
	updateScoreList $newScoreListEntry $scoreMethod

	#
	# Refigure score text.
	# 
	computeNewScoreText $scoreMethod

	if {$showScores} {
		#
		# Tell the jubliant user.
		#
		displayHighScores $scoreMethod
		#
		menuHelpScrollToTag $scoreMethod reverse 
	}
	
}


proc displayHighScores {method} {
	global score table help

	readScores $method
	computeNewScoreText $method
	
	#
	# re-use the help system code
	#

	# generate "help" text
	set help($method) $score(text,$method)
	menuHelp $method "${method} scores"
}

set query_user_done 0
set query ""

proc endqueryUserForName {} {
    global query query_user_done

    if { $query != "" } {
	set tmp $query
	set query ""

	wm deiconify .
	raise . $tmp
	focus .

	destroy $tmp.msg
	destroy $tmp.entry 
	destroy $tmp.buttons

	set query_user_done 1
	destroy $tmp
    }
}

proc queryUserForNameDlg {} {
    global query query_user_done score

    toplevel .query
    set query .query

    message $query.msg -text "What is your name for high scores?" -aspect 1000
    entry $query.entry -textvariable score(user)
    set b [frame $query.buttons]
    pack $query.msg $query.entry $query.buttons -side top -fill x
    pack $query.entry -pady 5
    button $b.ok -text OK -command { endqueryUserForName }

    wm title $query Prompt

    bind $query.entry <Return> { endqueryUserForName ; break } 
    bind $query <Destroy> { endqueryUserForName ; continue }

    pack $b.ok

    raise $query .
    focus $query.entry
    $query.entry icursor end
    $query.entry select range 0 end
}

proc queryUserForName {} {
    global query_user_done
	queryUserForNameDlg
    # vwait query_user_done
}
