
######################################################################
#
# klondikeMenus.tcl
#
# Copyright (C) 1993-1999 by John Heidemann <johnh@isi.edu>
# See the file "license.terms" for information on usage and redistribution of this file.  See the main klondike file for a full copyright
# notice.
#
# $Id: klondikeMenus.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $
#
######################################################################

#
# menu stuff
#
set rcsid(klondikeMenus.tcl) {$Id: klondikeMenus.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $}

global tk_version tkMenuOffset
if {$tk_version < 4.0} {
	set tkMenuOffset 0
} else {
	# tk_bisque
	set tkMenuOffset 1
}
proc menuOffset {n} {
	global tk_version tkMenuOffset
	return [expr { $n + $tkMenuOffset }]
}

proc readRelease {} {
	global table
	set catchval [catch {
			set f [open $table(releasefile) r]
			gets $f release
			close $f
			return $release
		} ret]
	if { $catchval == 2 } {
		return $ret
	} else {
		return "unknown-release"
	}
}

#
# menubuttonAndOrMenu exists to map over differences
# in menu handling between tk before and >=8.0.
# It returns the menu object needed for a menu,
# but in pre-8.0 versions it's indirected one level.
# Go figure.
#
# args are stuff that are the same between menubutton
# and cascade menus... this probably doesn't generalize very well.
# Too bad there's no easy way (that I know of) to process 
# -flag arguments from Tcl.  (Hint hint.)
#
proc menubuttonAndOrMenu {parent child label args} {
	global tk_version test_old_menus
	if {$tk_version < 8.0 || $test_old_menus} {
		eval "menubutton $parent.$child -text $label -menu $parent.$child.m $args"
		return [menu $parent.$child.m]
	} else {
		set m [menu $parent.$child]
		eval "$parent add cascade -label $label -menu $parent.$child $args"
		return $m
	}
}

proc mkMenus {} {
	global table menus helpMenuList
	global tk_version test_old_menus

	if {$tk_version < 8.0 || $test_old_menus} {
		frame .menubar -relief raised -borderwidth 1
	} else {
		menu .menubar
	}

	set table(release) [readRelease]

	set menus(file) [menubuttonAndOrMenu .menubar file "Game" -underline 0]

	$menus(file) add command -label "New" \
		-command "menuNewGame" -underline 0 -accelerator "^n"
	addToMenuBindings "n" menuNewGame
	$menus(file) add command -label "Give Up" \
		-command "menuFinishGame" -underline 0 -accelerator "^g"
	addToMenuBindings "g" menuFinishGame
	$menus(file) add command -label "Pause" \
		-command "menuPauseGame" -underline 0 -accelerator "^p"
	addToMenuBindings "p" menuPauseGame
	$menus(file) add separator
	$menus(file) add command -label "High Scores..." \
		-command "menuHighScores" -underline 0
	$menus(file) add separator
	$menus(file) add command -label "Quit" \
		-command "menuQuit" -underline 0 -accelerator "^q"
	addToMenuBindings "q" menuQuit

	set menus(options) [menubuttonAndOrMenu .menubar options "Options" -underline 0]
	set table(scoringMethod) standard
	trace variable table(scoringMethod) w scoreChange
	$menus(options) add radiobutton -label "Casino Scoring" \
		-value casino -variable table(scoringMethod) -underline 0
	$menus(options) add radiobutton -label "Standard Scoring" \
		-value standard -variable table(scoringMethod) -underline 0
	$menus(options) add separator
	set table(turnCount) 3
	$menus(options) add radiobutton -label "Turn One" \
		-value 1 -variable table(turnCount) -underline 5
	$menus(options) add radiobutton -label "Turn Three" \
		-value 3 -variable table(turnCount) -underline 5
	$menus(options) add separator
	# backFace is already set
	$menus(options) add cascade -label "Card Back" \
		-menu $menus(options).back -underline 5

	menu $menus(options).back
	foreach i $table(backChoices) {
		$menus(options).back add radiobutton \
			-label $i \
			-value $i -variable table(backChoice) \
			-command setBackBitmap
	}

	# Use rmt instead of this hack for debugging.
	# global env
	# if { $env(USER) == "johnh" } {
	# 	menubutton .menubar.debug -text "Debug" \
	# 		-menu $menus(debug) -underline 0
	# 	menu $menus(debug)
	# 	$menus(debug) add command -label "Eval" \
	# 		-command "evalCmd" -underline 0
	# }

	mkHelp
	set menus(help) [menubuttonAndOrMenu .menubar help "Help" -underline 0]
	$menus(help) add command -label "Rules..." \
		-command "menuHelp rules" -underline 0
	$menus(help) add command -label "Interface..." \
		-command "menuHelp interface" -underline 0
	$menus(help) add command -label "Scoring..." \
		-command "menuHelp scoring" -underline 0
	$menus(help) add command -label "Release notes..." \
		-command "menuHelp release" -underline 8
	$menus(help) add separator
	$menus(help) add command -label "About..." \
		-command "menuHelp about" -underline 0
	set helpWindowList {rules interface scoring release about}


	set padValue $table(padValue)
	if { $tk_version <= 4.0 } { 
		pack append .menubar \
				.menubar.file "left padx $padValue" \
				.menubar.options "left padx $padValue" \
				.menubar.help "right padx $padValue"
	} elseif {$tk_version < 8.0 || $test_old_menus} {
		pack configure .menubar.file -side left -in .menubar 
		pack configure .menubar.options -side left -in .menubar 
		pack configure .menubar.help -side right -in .menubar 
	} else {
		#
		# Don't do packing with the fancy 8.0 menus.
		#
		# support the special platform-specific menubars
		#
		# It's not documented in menu(n) or in an example
		# program how to properly configure these,
		# so I'm guessing.  Perhaps tk magic will fill in
		# the -label for each one, too.
		#
		global tcl_platform
		if {$tcl_platform(platform) == "windows"} {
			# Does windows convention require that I put
			# anything on Bill's menu?
			.menubar add cascade -menu [menu .menubar.system]
		} elseif {$tcl_platform(platform) == "macintosh"} {
			# I believe this is correct style for a Mac
			# if my memory serves.
			# Let me know if the help menu is in the wrong order.
			.menubar add cascade -menu [menu .menubar.apple]
			.menubar.apple add command -label "About Klondike..." \
					-command "menuHelp about" -underline 0
		} else {
			# unix
			# Unix is the native platform for klondike.
		}
	}
	mkMenuBindings -default
}

proc addToMenuBindings {key menu} {
	global game
#	lappend game(menuBindings) [list "<Alt-$key>" $menu]
	lappend game(menuBindings) [list "<Meta-$key>" $menu]
	lappend game(menuBindings) [list "<Control-$key>" $menu]
}

proc mkMenuBindings args {
	global game tk_version
	set default 0
	# puts $game(menuBindings)
	if {$tk_version >= 4.0} {
		set args "."
	}
	foreach i $args {
		if { $i == "-default" } { set default 1; continue }
		if {$tk_version < 4.0 } { 
		    tk_bindForTraversal $i
		}
		foreach j $game(menuBindings) {
			bind $i [lindex $j 0] [lindex $j 1]
			# puts "bind $i [lindex $j 0] [lindex $j 1]"
		}
		if {$tk_version < 4.0} {
		    if { $default } {
				focus default $i
			} else {
				focus $i
			}
		} else {
			focus $i
		}
		
	}
}

proc mkHelp {} {
	global help rcsid table
	set help(rules) {\
<big>The Layout</big>

When you start the game, you will see the basic layout of Klondike solitaire in the game window:  The <italic>deck</italic> in the upper left corner, the four <italic>foundations</italic> to the right of the deck, and the seven columns of the <italic>tableau</italic> below them.

As the game begins, Klondike deals twenty-eight cards from the deck into the tableau.  The number of cards in each pile increases from one to seven from left to right.  The top card of each column is face up, the rest face down.

<big>The Game</big>

The object of the game is to build all the cards face up on the tableau and foundations.  Each foundation builds upward, in sequence, from the ace to the king.  Only aces may be moved to an empty foundation, and only the next higher card of the same suit can be added to the foundation.

Build on the face-up cards in the tableau in descending sequence of alternating colors (shades on the computer screen).  For example, only the 9 of hearts or diamonds (``red'' suits) may play on the 10 of spades (a ``black'' suit).  All the face-up cards in a column may be moved as a single unit onto another column, if suits and values permit.  (You are allowed to move a single card when there are other face-up cards under it, but you will be assessed a scoring penalty. See Scoring.)  The lowest card of a sequence is always available to play to a foundation.

Whenever the face-up cards in a column are moved, the uncovered face-down card becomes available to turn up.  Only a king, or a sequence headed by a king, may be moved to an empty column.
}
	set help(interface) {\
<big>Cards</big>

Draggable cards will highlight when beneath the mouse cursor.  Move cards about the screen by clicking and dragging with the left button.

A single click on a face-down cards (on the deck or the tableau) will turn it over.  When all cards in the deck have been flipped, a click on the empty outline of the deck will recycle the cards (rules permitting).


<big>Menus</big>

The File menu allows games to be started (New Game) and completed (in a way) with ``Give Up''.  With standard scoring, it may be useful to pause the game (for example, if your advisor wants to ask you how to recycle the deck).  While paused your score will not decay, but you cannot see the cards.  Finally, you can show the high score list (in case you don't see it enough already).

The Options menu allows you to change scoring and card turning rules.  You can also change the pattern on the card backs.  Game-affecting options (scoring and card turning) cannot be changed during a game.

The Help menu lists various explanatory text which is probably far to complicated to explain.
}
	set help(scoring) {\
<big>Casino Scoring</big>

Scoring for the Casino Game is according to the common wagering scheme:  You ``pay'' $52 to begin play, and you ``win'' $5 for each card played on the foundations.


<big>Standard Scoring</big>

The regular game is scored more like a video game, including a penalty for slow play.  In the regular game, scores are accumulated as follows:

<italic>Plus</italic>

5 points--Adding a card to the tableau, either by playing one from the deck or by turning over the top card of an uncovered column.  Maximum: 220 points.

10 points--Adding a card to the foundations, either from the deck or the tableau.  Maximum: 520 points. 

Maximum available: 735 points.

<italic>Minus</italic>

-2 points--Every 15 seconds of elapsed time, while the Game Window is active.

-5 points--Moving a single card from one column to another column when there are face-up cards under it.

-5 points--Moving the top card from a foundation to the tableau. 

-25 points--Each pass through the deck after the first three passes, when turning up three cards at a time.

-100 points--Each pass through the deck after the first pass, when turning up one card at a time.

In addition, a <italic>Winning Bonus</italic> is calculated as follows:

[ ( End of Game score ) - ( 1 POINT per elapsed second ) ]  times 10.

The game is won when all cards are face up in the tableau and foundations, with none remaining in the deck.

Since the maximum end of game score is 735 points (assuming you took no time to win the game), the largest conceivable bonus is 7350 points.  Total scores of over 6000 can actually be achieved.
}
	set ids ""
	foreach i [array names rcsid] {
		set ids "$ids$rcsid($i)\n"
	}
	set help(release) "\
<big>Klondike $table(release)</big>

<big>New Features (1.9)</big>
    Klondike should now look better on non-Unix platforms, using native menubars and not using tk_bisque :-(.
    Makefile/configure support for TclPro wrapping tools.
    It now passes all of the TclPro debugger warnings.
    Thanks for the Scriptics folks for offering code and advice about these changes.

<big>New Features (1.8)</big>
    Klondike now supports Tk4.1.
    This version has been tested under SunOS 4.1.1, Solaris 2.1, FreeBSD 2.0, and Linux/Slackware 2.x.
    Installation now uses GNU configure.
    Menu accelerators now work.

<big>Known Bugs</big>
    Changing the scoring method should instantly change the displayed score.
    Score files employ a world-writable directory.

<big>Desired Features</big>
    Color bitmaps for face cards and card backs are desired... if you have the bitmaps, I'll write the code!
    The code is driting even further from the Jacoby/Dontspace code.  Sigh.
    Double clicking cards on the tableau should send them to the foundation.  This feature awaits the Jacoby merge.
    Option and resource processing should be more sophisticated.  All colors and features should be controllable by X11 resources.
    Sound should be incorporated into the game.  Sound can be played at game start and end (a la Mac-Klondike).
    Keyboard control of the action should be possible.
    The user-interface should be separate from the rules (to allow automated players).
    Edges of hidden cards should be displayed so you can tell how big each pile is.
    The ``table'' code should be cleanly separated from the ``klondike'' code to allow easy implementation of multiple card games.
    Context sensitive help would be so easy in Tk, it's a shame it's not there.
    The score list should not pop up if you choose ``new''.
    A ``win'' flag in the score file would be nice.
    The score file should keep the top <italic>n</italic> scores of each player.
    Undo would be nice, but it should prevent you from scoring.
    When the game is started a notice about how to get help information should appear on the screen.

<big>Design Notes</big>
    Klondike is designed as klondike-specific rules over a generic card-manipulation code.  The basic foundation should be applicable to implementation of multiple card games in Tcl/Tk.  If sufficient interest is expressed in klondike internals I can document it (and clean it up a bit).
    All klondike text windows employ a SGML-ish tag-markup approach.  This code is availble for use in other applications, see the comments for details.
    Pwishx may be of interest to some interested in a more portable wishx (for some definition of portable).
"

	set help(about) "\
<big>Klondike $table(release)</big>

Copyright (C) 1993-1999 by John Heidemann
All rights reserved.
Comments to <computer><johnh@isi.edu></computer>

Web page: <computer>http://www.isi.edu/~johnh/SOFTWARE/JACOBY/index.html</computer>

Card bitmaps by Gary Sager, <computer><75270.1453@compuserve.com></computer> from the Macintosh game <italic>Video Poker...NOT!</italic>.  Used with permission.

Scoring description and method by Mike Casteel <computer><mac@unison.com></computer>, author of the Macintosh game <italic>Klondike</italic>.  This klondike version was inspired by and is modeled after his excellent implementation and user-interface.

<italic>Implementation is the sincerest form of flattery.</italic>
   --- L. Peter Deutsch
"
}


proc beginGameChangeMenus {} {
	global menus
	$menus(file) entryconfigure [menuOffset 1] -state normal
	$menus(file) entryconfigure [menuOffset 2] -state normal
	$menus(options) entryconfigure [menuOffset 0] -state disabled
	$menus(options) entryconfigure [menuOffset 1] -state disabled
	$menus(options) entryconfigure [menuOffset 3] -state disabled
	$menus(options) entryconfigure [menuOffset 4] -state disabled
}

proc endGameChangeMenus {} {
	global menus
	$menus(file) entryconfigure [menuOffset 1] -state disabled
	$menus(file) entryconfigure [menuOffset 2] -state disabled
	$menus(options) entryconfigure [menuOffset 0] -state normal
	$menus(options) entryconfigure [menuOffset 1] -state normal
	$menus(options) entryconfigure [menuOffset 3] -state normal
	$menus(options) entryconfigure [menuOffset 4] -state normal
}




proc menuNewGame {} {
	global table
	endGame $table(id) "quit" 0
	mkNewGame $table(id)
}

proc menuFinishGame {} {
	global table
	endGame $table(id) "quit" 1
}

proc menuPauseGame {} {
	global table menus
	if { $table(gameStatus) == "paused" } {
		unpauseGame
		return
	}
	$menus(file) entryconfigure [menuOffset 2] -label "Continue"
	set w $table(id)
	$w create rectangle 0 0 $table(width) $table(height) \
		-fill $table(bg) -tag pauseItems
	$w create text [expr { $table(width)/2 } ] [expr { $table(height)/2 } ] \
			-anchor center -fill $table(fg) \
			-text "Game paused.\nClick to continue." \
			-tag pauseItems
	$w bind pauseItems <ButtonRelease-1> {unpauseGame}
	set table(gameStatus) "paused"
	set table(pauseStartTime) [getclock]
}

proc unpauseGame {} {
	global table menus
	$menus(file) entryconfigure [menuOffset 2] -label "Pause"
	set w $table(id)
	$w delete pauseItems
	set table(gameStatus) "running"
	set table(pauseEndTime) [getclock]
	set pauseDelta [expr { $table(pauseEndTime)-$table(pauseStartTime) }]
	incr table(pauseTime) $pauseDelta
}

proc menuHighScores {} {
	global table
	displayHighScores $table(scoringMethod)
}

proc menuQuit {} {
	global table
	# quit game in progress, if any
	endGame $table(id) "quit" 0
	# bail
	exit 0
}



#----------------------------------------------------------------------
# (stolen from Ousterhout's demo program's mkBasic)
# and hacked to add SGML-ish (actually more MIME-ish) tags.

#
# Put the next window up tiled after the last window to go up.
# Maintain a list of relevant windows in the global variable stackList.
#
proc wmConfig {w title} {
	global stackList
	#
	# configure random wm stuff
	#
	if { [info exists stackList] == 0 } {
		# setup a list with something that should never get removed
		set stackList "."
	}
	#
	# first geometry
	#
	set geometry [wm geometry [lindex $stackList [expr { [llength $stackList] - 1 } ]]]
	set geoElems [split $geometry "x+"]
	set geoX [lindex $geoElems 2]
	set geoY [lindex $geoElems 3]
	set neoGeoX [expr { $geoX + 50 } ]
	set neoGeoY [expr { $geoY + 50 } ]
	wm geometry $w [format "+%d+%d" $neoGeoX $neoGeoY]
	lappend stackList $w
	#
	# cleanup
	#
	wm protocol $w WM_DELETE_WINDOW "unmenuHelp $w"
	#
	# group-hood
	#
	wm group $w .
	#
	# titles
	#
	wm title $w $title

	global tcl_platform
	if {$tcl_platform(platform) == "unix"} { 
	    wm iconname $w $title
	}
}
proc unmenuHelp {w} {
	global stackList
	# puts "unmenuHelp called on $w"
	if { [set listPos [lsearch -exact $stackList $w]] != -1 } {
		set stackList [lreplace $stackList $listPos $listPos]
	}
	destroy $w
}
proc menuHelp {topic {titleWord ""}} {
	global help helpWindowList table
    global tk_version

	set w ".${topic}"
	#
	# destroy any existing window
	# NEEDSWORK: should just bring it forward.
	#
	catch {unmenuHelp $w}
	#
	# create a new window	
	#
	toplevel $w
	# default title
	if { $titleWord == "" } { set titleWord	$topic }
	wmConfig $w "Klondike--$titleWord"
	set padValue $table(padValue)
	button $w.ok -text OK -padx [expr { 2*$padValue } ] -command "unmenuHelp $w"
	# NEEDSWORK: font selection should be configurable.
	#
	# If you use this code elsewhere, please follow two conscious
	# style choices.  First, wide things are hard to read
	# (50 chars is about the most reasonable---consider newspaper
	# columns).  Second, we allow the user to resize the window.
	# (The user should always have control, even to do stupid things.)
	#
	if { $tk_version < 8.0 } {
	    text $w.t \
		    -relief raised -bd 2 -yscrollcommand "$w.s set" \
		    -setgrid true -wrap word \
		    -width 50 -padx $padValue -pady $padValue \
		    -font -*-Times-Medium-R-*-140-*
	    set defFg [lindex [$w.t configure -foreground] 4]
	    set defBg [lindex [$w.t configure -background] 4]
	    $w.t tag configure italic -font -*-Times-Medium-I-Normal-*-140-*
	    $w.t tag configure computer -font -*-Courier-Medium-R-Normal-*-120-*
	    $w.t tag configure big -font -*-Times-Bold-R-Normal-*-180-*
	    $w.t tag configure reverse -foreground $defBg -background $defFg
	} else {
	    text $w.t \
		    -relief raised -bd 2 -yscrollcommand "$w.s set" \
		    -setgrid true -wrap word \
		    -width 50 -padx $padValue -pady $padValue \
		    -font { times 14 }
	    set defFg [lindex [$w.t configure -foreground] 4]
	    set defBg [lindex [$w.t configure -background] 4]

	    $w.t tag configure italic -font { times 14 italic }
	    $w.t tag configure computer -font { courier 12 }
	    $w.t tag configure big -font { times 18 bold }
	    $w.t tag configure reverse -foreground $defBg -background $defFg
	}

	scrollbar $w.s -relief flat -command "$w.t yview"

	if { $tk_version <= 4.0 } {
		pack append $w $w.ok {bottom} $w.s {right filly} $w.t {expand fill}
	} else {
		pack configure $w.ok -side bottom -in $w 
		pack configure $w.s -side right -fill y -in $w
		pack configure $w.t -expand 1 -fill both -in $w
	}

	$w.t mark set insert 0.0
	bind $w <Any-Enter> "focus $w.t"

	#
	# Scan the text for tags.
	#
	set t $help($topic)
	while { [regexp -indices {<([^@>]*)>} $t match inds] == 1 } {
		set start [lindex $inds 0]
		set end [lindex $inds 1]

		set keyword [string range $t $start $end]
		# puts stderr "tag $keyword found at $inds"

		# insert the left hand text into the thing
		set oldend [$w.t index end]
		$w.t insert end [string range $t 0 [expr { $start-2} ]]
		purgeAllTags $w.t $oldend insert

		# check for begin/end tag
		if { [string range $keyword 0 0] == "/" } {
			# end region
			set keyword [string trimleft $keyword "/"]
			if { [info exists tags($keyword)] == 0 } {
				error "end tag $keyword without beginning"
			}
			$w.t tag add $keyword $tags($keyword) insert
			# puts stdout "tag $keyword added from $tags($keyword) to [$w.t index insert]"
			unset tags($keyword)
		} else {
			if { [info exists tags($keyword)] == 1 } {
				error "nesting of begin tag $keyword"
			}
			set tags($keyword) [$w.t index insert]
			# puts stdout "tag $keyword begins at [$w.t index insert]"
		}

		# continue with the rest
		set t [string range $t [expr { $end+2 } ] end]
	}
	set oldend [$w.t index end]
	$w.t insert end $t
	purgeAllTags $w.t $oldend insert
	#
	# Disable the text so the user can't mess with it.
	#
	$w.t configure -state disabled
}

proc purgeAllTags {w start end} {
	# remote any bogus tags
	# puts stderr "Active tags at $start are [$w tag names $start]"
	foreach tag [$w tag names $start] {
		$w tag remove $tag $start $end
	}
}

proc menuHelpScrollToTag {topic tag} {
	set w ".${topic}"
	
	catch {$w.t yview -pickplace reverse.first}
}

