#!/usr/bin/wish -f

######################################################################
#
# table.tcl
#
# Copyright (C) 1993-1996 by John Heidemann <johnh@isi.edu>
# See the file "license.terms" for information on usage and redistribution of this file.  See the main klondike file for a full copyright
# notice.
#
# $Id: table.tcl,v 1.2 2000/10/31 23:31:11 welch Exp $
#
######################################################################

#
# generic card table routines
#
set rcsid(table.tcl) {$Id: table.tcl,v 1.2 2000/10/31 23:31:11 welch Exp $}

set w ""
set ww "."
set c "$w.c"

#
# caller is expected to have set table(width) and table(height)
#
set table(id) $c

if { $tk_version < 8.0 } {
    set table(font) -*-Helvetica-Medium-R-*-140-*
} else {
    set table(font) { helvetica 14 }
}

global tk_version
if {$tk_version < 4.0} {
	set table(colormodel) [tk colormodel .]
} else {
	set table(colormodel) "color"
	if {[winfo depth .] < 8} {
		set table(colormodel) monochrome
	}
}
if { $table(colormodel) == "monochrome" } {
	set table(fg) Black
	set table(bg) White
} else {
	set table(fg) Black
	set table(bg) [lindex [. config -bg] 4]
	# was #ffe4c4
}
# cards
# (see reface card for card colors)

set table(cardWidth) 52
set table(cardHeight) 67
# cardSpace -- reasonable amount of space between card bitmaps
set table(cardSpace) 8
# cardOverlap -- required overlap when dropping cards
set table(cardOverlap) 4
# padValue -- a good value for random padding (around text)
set table(padValue) 10

set table(values) "a 2 3 4 5 6 7 8 9 t j q k"
set table(suits) "c d h s"
set table(cvalues) "xa23456789tjqkx"
set table(csuits) "xcdhsx"
set table(otherColorSuits,c) "dh"
set table(otherColorSuits,d) "cs"
set table(otherColorSuits,h) "cs"
set table(otherColorSuits,s) "dh"

# tclX
random seed [getclock]

#
# card bitmap backgrounds
#
proc setBackBitmap {} {
	global table
	if { [info exists table(backFace)] } {
		set oldBackFace $table(backFace)
	} else {
		set oldBackFace "xxx"
	}
	set table(backFace) "back_$table(backChoice)"
	#
	# Fix any cards with the old back.
	#
	if {[catch {$table(id) configure}] == 0} {
		foreach i [$table(id) find withtag card] {
			set itemBitmap [lindex [$table(id) itemconfigure $i -bitmap] 4]
			if { [regexp $oldBackFace $itemBitmap] } {
				refaceCard $i $table(id) $table(backFace)
			}
		}
	}
}

proc chooseCardBackground {} {
	global table

	#
	# get our choices
	#
	set choices ""
	# Note:  wish-4.1 under linux seems to have a bug
	# with the glob failing.  If so, take our
	# known good cases.
	if { [catch {
		set possibleChoices [glob [string trimleft "$table(bitmapdir)/c_back_*.xbm" "@"]]
	}] } {
		set possibleChoices "c_back_crane.xbm c_back_pagoda.xbm c_back_plain.xbm"
	}
	foreach i $possibleChoices {
		regexp {c_back_(.*)\.xbm$} $i trash token
		lappend choices $token
	}
	if { $choices == "" } {
		return -errorinfo "No background bitmap found."
	}
	set table(backChoices) $choices

	#
	# randomly pick one
	#
	set table(backChoice) [lindex $choices [random [llength $choices]]]
	setBackBitmap
}
chooseCardBackground


#
# table stuff
#

canvas $table(id) -relief raised \
	-width $table(width) -height $table(height) \
	-background $table(bg)

proc refaceCard {item w face} {
	global table
	switch -glob $face {
		[a23456789tjqk][cs] {
			set table($item,normFg) Black
			set table($item,normBg) White
			if { $table(colormodel) == "monochrome" } {
				set table($item,highFg) White
				set table($item,highBg) Black
			} else {
				set table($item,highFg) Black
				set table($item,highBg) Gray70
			}
		}
		[a23456789tjqk][dh] {
			set table($item,normFg) Red
			set table($item,normBg) White
			if { $table(colormodel) == "monochrome" } {
				set table($item,highFg) White
				set table($item,highBg) Black
			} else {
				set table($item,highFg) Red
				set table($item,highBg) Gray70
			}
		}
		back_*		    {
			set table($item,normFg) Black
			set table($item,normBg) White
			if { $table(colormodel) == "monochrome" } {
				set table($item,highFg) White
				set table($item,highBg) Black
			} else {
				set table($item,highFg) Black
				set table($item,highBg) Gray70
			}
		}
		space		    -
		warnspace	    {
			set table($item,normFg) $table(fg)
			set table($item,normBg) $table(bg)
			if { $table(colormodel) == "monochrome" } {
				set table($item,highFg) $table(bg)
				set table($item,highBg) $table(fg)
			} else {
				set table($item,highFg) Black
				set table($item,highBg) Gray70
			}
		}
		default		    { puts "refaceCard: unkown face $face\n" }
	}
	$w itemconfigure $item \
		-bitmap "$table(bitmapdir)/c_$face.xbm" \
		-foreground $table($item,normFg) \
		-background $table($item,normBg)

}

proc createCardBitmap {c x y face} {
	global table
	set item [ $c create bitmap $x $y -anchor nw]
	refaceCard $item $c $face
	# Remember the cards so we can change bitmaps as required.
	$c addtag card withtag $item
	# $c addtag debug withtag $item
	return $item
}


#
# deck stuff
#

proc createDeck {c x y} {
	global table deck

	set d [ createCardBitmap $c $x $y $table(backFace) ]

	set deck(cards) ""
	foreach v $table(values) {
		foreach s $table(suits) {
			set vs "$v$s"
			set deck($vs,vs) $vs
			set deck($vs,face) "$v$s"
			lappend deck(cards) $vs
		}
	}

	return $d
}

proc createEmptyDeck {c x y} {
	global table
	return [ createCardBitmap $c $x $y "space" ]
}



proc shuffleDeck {} {
	global deck
	set oldCards $deck(cards)
	set newCards ""
	while { [llength $oldCards] > 0 } {
		# tclX
		set i [random [llength $oldCards]]
		lappend newCards [lindex $oldCards $i]
		set oldCards [lreplace $oldCards $i $i]
	}
	set deck(cards) $newCards
}




#
# bindings
#

#
# deck-double press
#
$table(id) bind doubleClickableCard <ButtonRelease-1> { 
	global table
	if { $table(gameStatus) != "running" &&
			$table(gameStatus) != "starting" } {
		return
	}
	set itemId [%W find withtag current]
	eval "$table($itemId,doubleClickProc) $itemId %W %x %y"
}

#
# outlineableCard
#
$table(id) bind outlineableCard <Any-Enter> { hilightCard current %W %x %y }
proc hilightCard {item w x y} {
	global table
	set itemId [$w find withtag current]
	if { $table(gameStatus) != "running" &&
			$table(gameStatus) != "starting" } {
		return
	}
	$w itemconfig $item \
		-foreground $table($itemId,highFg) \
		-background $table($itemId,highBg)
}
$table(id) bind outlineableCard <Any-Leave> { unhilightCard current %W %x %y }
proc unhilightCard {item w x y} {
	global table
	set itemId [$w find withtag current]
	$w itemconfig $item \
		-foreground $table($itemId,normFg) \
		-background $table($itemId,normBg)
}

#
# dragableCard
#
$table(id) bind dragableCard <ButtonPress-1> { dragableCardPress [%W find withtag current] %W %x %y }
proc dragableCardPress {itemId w x y} {
	global table

	if { $table(gameStatus) == "startable" } { beginGame $itemId $w $x $y }
	if { $table(gameStatus) != "running" } { return }

	$w dtag selected
	$w addtag selected withtag $itemId
	set friends [eval "$table($itemId,dragFindFriendProc) $itemId $w $x $y"]
	# NEEDSWORK: Tk3.2 bug.  We shouldn't have to loop here, but
	# it seems that "$w addtag selected withtag $friends"
	# just adds one of the list.
	foreach i $friends {
		$w addtag selected withtag $i
	}
	$w raise selected
	set table(lastX) $x
	set table(lastY) $y
	set table(lastHit) {}
	eval "$table($itemId,cardPickProc) $itemId $w $x $y"
	set table(selectedCount) [llength [$w find withtag selected]]
}
$table(id) bind dragableCard <B1-Motion> { cardMove [%W find withtag current] %W %x %y }
proc cardMove {itemId w x y} {
	global table
	$w move selected [expr { $x-$table(lastX) } ] [expr { $y-$table(lastY) }]
	set table(lastX) $x
	set table(lastY) $y

	set hit [checkForDropableHit $itemId $w]
	if { $hit != $table(lastHit) } {
		if { $table(lastHit) != {} } {
			eval "$table($table(lastHit),dropLeaveProc) $itemId $w $x $y $table(lastHit)";
		}
		if { $hit != {} } {
			eval "$table($hit,dropEnterProc) $itemId $w $x $y $hit";
		}
		set table(lastHit) $hit
	}
}

proc checkForDropableHit { itemId w } {
	global table

	#
	# Check for hit over possible dropableCard.
	#
	set bbox [$w bbox $itemId]
	set bbox_t [expr { [lindex $bbox 0]+$table(cardOverlap) } ]
	set bbox_l [expr { [lindex $bbox 1]+$table(cardOverlap) } ]
	set bbox_b [expr { [lindex $bbox 2]-$table(cardOverlap) } ]
	set bbox_r [expr { [lindex $bbox 3]-$table(cardOverlap) } ]
	set hits [$w find overlapping $bbox_t $bbox_l $bbox_b $bbox_r]
	#
	# Go through the list of hits 
	# (in reverse order---we assume the list is sorted back-to-front).
	# Quit if we get a good hit.
	#
	if { $table($itemId,cardVS) == "6h" } {
		# puts stderr "checkForDropableHit: checking $itemId's accepts) $table($itemId,cardVS), hits=$hits"
	}
	set lastHit [llength $hits]
	for {set i [expr { [llength $hits]-2 } ] } { $i >= 0 } {incr i -1} {
		set hit [lindex $hits $i]
		#
		# Now check to see if we're over a dropableCard.
		# (Sigh, there doesn't seem any way to query the tags
		# of an object.)
		#
		if { [info exists table($hit,dropAccepts)] == 0 } { continue }
		if { $table($hit,dropAcceptsSingleOnly) && $table(selectedCount) > 1 } { continue }
		if { [string match $table($hit,dropAccepts) $table($itemId,cardVS)] == 1 }  {
			# puts stderr "$itemId: $table($itemId,cardVS),$table(selectedCount) matches $hit: $table($hit,dropAccepts) of $hits"
			return $hit;
		}
	}
	return {}
}

$table(id) bind dragableCard <ButtonRelease-1> \
		{ dragableCardRelease [%W find withtag current] %W %x %y }
proc dragableCardRelease { itemId w x y } {
	global table
	if { $table(lastHit) != {} } {
		eval "$table($itemId,cardDropProc) $itemId $w $x $y $table(lastHit)"
		eval "$table($table(lastHit),dropDropProc) $itemId $w $x $y $table(lastHit)"
	} else {
		eval "$table($itemId,cardDropProc) $itemId $w $x $y {}"
	}
	$w dtag selected
}

# this is for debugging
$table(id) bind debug <ButtonPress-3> { debugProc [%W find withtag current] %W %x %y }



#
# dropableCard
#
proc genericDropEnter {item w x y targetId} {
	global table
	$w itemconfig $targetId \
		-foreground $table($targetId,highFg) \
		-background $table($targetId,highBg)
	}
proc genericDropLeave {item w x y targetId} {
	global table
	$w itemconfig $targetId \
		-foreground $table($targetId,normFg) \
		-background $table($targetId,normBg)
}



#
# untouched stuff
#
$table(id) bind untouchedCard <ButtonPress-1> { beginGame current %W %x %y}
