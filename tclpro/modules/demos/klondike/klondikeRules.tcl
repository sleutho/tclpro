#!/usr/bin/wish -f

######################################################################
#
# klondike
#
# Copyright (C) 1993-1999 by John Heidemann <johnh@isi.edu>
# See the file "license.terms" for information on usage and redistribution of this file.  See the main klondike file for a full copyright
# notice.
#
# $Id: klondikeRules.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $
#
######################################################################

set rcsid(klondikeRules.tcl) {$Id: klondikeRules.tcl,v 1.2 2000/10/31 23:31:10 welch Exp $}


set table(cardWidth) 54
set table(cardHeight) 69
set table(gutter) 12
# We pick stackedCardOffset such that table(height) + the menu bar +
# fvwm window decorations allow the whole screen to fit on a 480-pixel
# high laptop computer display.
# At stackedCardOffset == 22 it just *barely* fits.
set table(stackedCardOffset) 22

set table(width)  [expr { 7*$table(cardWidth)+7*$table(gutter) } ]
set table(height) [expr { 2*$table(cardHeight)+3*$table(gutter)+12*$table(stackedCardOffset) } ]
source $table(table_srcfile)

source $table(menus_srcfile)
source $table(score_srcfile)

#
# do the menu thang
#
global test_old_menus
set test_old_menus 0
mkMenus

#
# build the table
#
# button $w.ok -text "OK" -command "destroy $ww"
#button $w.ok -text "OK" -command "okCmd"
proc evalCmd {} {
	set inf [open /dev/tty r]
	puts stdout "ok: " nonewline
	flush stdout
	while { -1 != [gets $inf line] } {
		set output [eval $line]
		puts stdout "output: $output"
	}
	close $inf
}

if { $tk_version <= 4.0 } {
    pack append $ww .menubar {top fillx} $table(id) {expand fill}
} elseif {$tk_version < 8.0 || $test_old_menus} {
    pack configure .menubar -in $ww -side top -fill x
    pack configure $table(id)  -in $ww  -expand 1 -fill both
} else {
    pack configure $table(id)  -in $ww  -expand 1 -fill both
    . configure -menu .menubar
}

proc nullCleanupProc {item w x y target closure} {}
proc nullFindFriendProc {item w x y} { return {} }

proc dealNextCard {} {
	global deck
	set vs [lindex $deck(cards) 0]
	set deck(cards) [lreplace $deck(cards) 0 0]
	return $vs
}

proc figureNextValue {oldValue inc} {
	global table
	return [string index $table(cvalues) \
		[expr { [string first $oldValue $table(cvalues)]+$inc } ] ]
}

proc moveAllRelatively { w items oldX oldY newX newY } {
	$w move $items [expr { $newX-$oldX }] [expr { $newY-$oldY }]
}




#
# make the deck
#
proc mkDeck {w} {
	global table deck
	set deck(x) $table(gutter)
	set deck(y) $table(gutter)
	set deck(id) [ createDeck $table(id) $deck(x) $deck(y) ]
	shuffleDeck
	$w addtag deck withtag $deck(id)
	$w addtag outlineableCard withtag $deck(id)
	$w addtag doubleClickableCard withtag $deck(id)
	set table($deck(id),doubleClickProc) deckDoubleClick
	set table($deck(id),cardState) "deck"
	set deck(pileCardIds) ""
	set deck(deckPasses) 0
	set table(cardsToReveal) [llength $deck(cards)]
}

#
# and the empty deck
#
proc mkEmptyDeck {w} {
	global table deck emptyDeck

	set emptyDeck(id) [ createEmptyDeck $w $deck(x) $deck(y) ]
	set table($emptyDeck(id),doubleClickProc) emptyDeckDoubleClick
	set table($emptyDeck(id),cardState) "emptyDeck"
	$w addtag emptyDeck withtag $emptyDeck(id)
	$w raise deck emptyDeck
}

proc enableEmptyDeck {item w} {
	$w addtag outlineableCard withtag $item
	$w addtag doubleClickableCard withtag $item
}

proc disableEmptyDeck {item w} {
	$w dtag $item outlineableCard
	$w dtag $item doubleClickableCard
}

proc normalEmptyDeck {item w} {
	global table
	refaceCard $item $w "space"
}

proc warningEmptyDeck {item w} {
	global table
	refaceCard $item $w "warnspace"
}

proc deckDoubleClick {item w x y} {
	global table deck
	#  Flash when turning cards, but don't show people what the cards are.
	set delayTime 40
	set flashCount $table(turnCount)
	set deckSize [llength $deck(cards)]
	if { $deckSize < $flashCount } {
		set flashCount $deckSize
	}
	for {set i $flashCount} { $i > 0 } { incr i -1 } {
		unhilightCard deck $table(id) {} {}
		update idletasks
		after $delayTime
		if { $i > 1 } {
			hilightCard deck $table(id) {} {}	
		}
		update idletasks
		if { $i > 1 } {
			after $delayTime
		}
	}
 	# Now actually turn the cards.
 	for {set i 0} { $i < $table(turnCount) } { incr i } {
		deckRevealCard $w
	}
	# finish flashing
	hilightCard deck $table(id) {} {}	
}

proc deckRevealCard {w} {
	global table deck

	# Abort if out of cards.
	if { [llength $deck(cards)] == 0 } {
		return
	}

	set vs [dealNextCard]
	set cardX [expr { $deck(x)+$table(cardWidth)+$table(gutter) }]
	set cardY $deck(y)
	set card [ createCardBitmap $w $cardX $cardY $deck($vs,face) ]
	$w addtag outlineableCard withtag $card
	$w addtag dragableCard withtag $card
	set table($card,dragFindFriendProc) nullFindFriendProc
	set table($card,cardPickProc) cardPick
	set table($card,cardDropProc) cardDrop
	set table($card,cardVS) $vs
	set table($card,cardState) "inPile"
	set table($card,cleanupProc) pileCleanup
	set table($card,cleanupClosure) $card

	# Add the card to the list of cards on the pile for recycling.
	lappend deck(pileCardIds) $card

	# If we're out of cards, go to the empty deck.
	if { [llength $deck(cards)] == 0 } {
		$w raise emptyDeck deck
	}
	
	# puts stderr "new card id $card has value $vs"
}

proc pileCleanup {item w x y target closure} {
	global deck
    set lastCardIndex [expr { [llength $deck(pileCardIds)]-1 }]
	set lastCardId [lindex $deck(pileCardIds) $lastCardIndex]
	if { $lastCardId != $item } {
		error "pileCleanup: last card $lastCardId is not item ($item)."
	}
	set deck(pileCardIds) [lreplace $deck(pileCardIds) $lastCardIndex $lastCardIndex]
	# One less card to play before winning.
	indicateCardPlayed $w 1
	#
	# There's a bug if we win here:
	# it's the drop onto the foundation that gives us the score.
	# If we win here we don't get those points until it's too late.
	# We therefore require that the dropDropProc handle the win check.
	#
}

proc emptyDeckDoubleClick {item w x y} {
	global table deck score

	foreach cardId $deck(pileCardIds) {
		set vs $table($cardId,cardVS)
		lappend deck(cards) $vs
		$w delete $cardId
	}
	set deck(pileCardIds) ""
	$w raise deck emptyDeck
	incr deck(deckPasses)
	if { $deck(deckPasses) >= $table(turnCount) } {
	    incr score(standardScore) [expr { ($table(turnCount)==1)?-100:-25} ]
		updateScore $w
	}
	if { $deck(deckPasses) == $table(turnCount)-1 } {
		if { $table(scoringMethod) == "casino" } {
			disableEmptyDeck $item $w
		}
		if { $table(scoringMethod) == "standard" } {
			warningEmptyDeck $item $w
		}
	}
}

proc cardPick {itemId w x y} {
	global table
	set bbox [$w bbox $itemId]
	set table(currentInitialX) [lindex $bbox 0]
	set table(currentInitialY) [lindex $bbox 1]
	# puts stderr "cardPick"
}
proc cardDrop {itemId w x y target} {
	global table
	if { $target == {} } {
		#
		# Put the card back where it started.
		# This is a little trickey since we could be dragging a
		# stack, so we compute the relative distance and
		# move selected.
		#
		set oldCoords [$w coords $itemId]
		moveAllRelatively $w selected \
			[lindex $oldCoords 0] [lindex $oldCoords 1] \
			$table(currentInitialX) $table(currentInitialY)
	} else {
		eval "$table($itemId,cleanupProc) $itemId $w $x $y $target $table($itemId,cleanupClosure)"
	}
}


#
# make the tableau (where the playing happens)
#
proc mkTableau {w} {
	global table tableau
	foreach i "0 1 2 3 4 5 6" {
	    set tableau($i,x) [ expr { $i*$table(cardWidth)+(1+$i)*$table(gutter) } ]
	    set tableau($i,y) [ expr { $table(cardHeight)+2*$table(gutter) } ]
		set tableau($i,id) [ createCardBitmap \
			$w $tableau($i,x) $tableau($i,y) "space" ]
		$w addtag tableau withtag $tableau($i,id)
		set table($tableau($i,id),cardState) "tableau"
		set table($tableau($i,id),tableauColumn) $i
		#
		# Set up to accept drops
		# (but not yet).
		#
		set table($tableau($i,id),dropAccepts) "xx"
		set table($tableau($i,id),dropAcceptsSingleOnly) 0
		set table($tableau($i,id),dropEnterProc) genericDropEnter
		set table($tableau($i,id),dropLeaveProc) genericDropLeave
		set table($tableau($i,id),dropDropProc) tableauDropDrop
		# This hack allows convient indexing of cards dropped on us.)
		set table($tableau($i,id),tableauRow) -1
	}
}

#
# make the foundation (where the aces go)
#
proc mkFoundation {w} {
	global table foundation
	foreach i "0 1 2 3" {
		set foundation($i,x) [ expr { (3+$i)*$table(cardWidth)+(4+$i)*$table(gutter) } ]
		set foundation($i,y) [ expr { $table(gutter) } ]
		set foundation($i,id) [ createCardBitmap \
			$w $foundation($i,x) $foundation($i,y) "space" ]
		$w addtag foundation withtag $foundation($i,id)
		set table($foundation($i,id),cardState) "foundation"
		#
		# set up to accept drops
		#
		set table($foundation($i,id),dropAccepts) "a\[cdhs\]"
		set table($foundation($i,id),dropAcceptsSingleOnly) 1
		set table($foundation($i,id),dropEnterProc) genericDropEnter
		set table($foundation($i,id),dropLeaveProc) genericDropLeave
		set table($foundation($i,id),dropDropProc) foundationDropDrop
	}
}

proc foundationDropDrop {itemId w x y target} {
	global table deck score

	# first unhilight the target
	genericDropLeave $itemId $w $x $y $target

	# move the card to the right place
	set bbox [$w bbox $target]
	$w coords $itemId [lindex $bbox 0] [lindex $bbox 1]

	# make the card no longer mobile
	$w dtag $itemId dragableCard
	$w dtag $itemId outlineableCard
	unhilightCard $itemId $w $x $y
	set table($itemId,cardState) "inFoundation"

	# make the card receptive of new cards	
	set vs $table($itemId,cardVS)
	set v [string index $vs 0]
	set s [string index $vs 1]
	set newV [figureNextValue $v 1]
	set table($itemId,dropAccepts) "$newV$s"
	set table($itemId,dropAcceptsSingleOnly) 1
	# puts stderr "$itemId accepts $newV$s"
	set table($itemId,dropEnterProc) genericDropEnter
	set table($itemId,dropLeaveProc) genericDropLeave
	set table($itemId,dropDropProc) foundationDropDrop

	# make the old card unreceptive (not really necessary)
	unset table($target,dropAccepts)
	unset table($target,dropEnterProc)
	unset table($target,dropLeaveProc)
	unset table($target,dropDropProc)

	# Finally update the score.
	incr score(casinoScore) 5
	incr score(standardScore) 10
	updateScore $w

	# If the card was dropped here from the pile,
	# we may have won.
	checkForWin
}


proc tableauMakeCardDropAccepting {itemId} {
	global table
	set vs $table($itemId,cardVS)
	set v [string index $vs 0]
	set s [string index $vs 1]
	set nextValue [figureNextValue $v -1]

	set table($itemId,dropAccepts) "$nextValue\[$table(otherColorSuits,$s)\]"
# for debugging:	set table($itemId,dropAccepts) "\[a2-9tjqk\]\[cdhs\]"
	set table($itemId,dropAcceptsSingleOnly) 0
	set table($itemId,dropEnterProc) genericDropEnter
	set table($itemId,dropLeaveProc) genericDropLeave
	set table($itemId,dropDropProc) tableauDropDrop
	# puts stderr "tableauMakeCardDropAccepting: $itemId now accepts $nextValue\[$table(otherColorSuits,$s)\]"
}

proc tableauMakeCardDropRejecting {itemId} {
	global table
	unset table($itemId,dropAccepts)
	unset table($itemId,dropEnterProc)
	unset table($itemId,dropLeaveProc)
	unset table($itemId,dropDropProc)
	# puts stderr "tableauMakeCardDropRejecting: $itemId now rejects"
}

#
# tableauFindFriends --
# If we grab the top card of a tableau column,
# take the rest of the column with it.
# (These cards must be dragged as a unit.)
#
proc tableauFindFriends {itemId w x y} {
	global table
	if { $table($itemId,tableauRow) == 0 } {
		set friends \
			[ $w find withtag "tableau$table($itemId,tableauColumn)" ]
	} else {
		set friends {}
	}
	# puts stderr "tableauFindFriends: friends=$friends in column $table($itemId,tableauColumn)"
	return $friends
}

#
# indicateCardPlayed -- keep track as cards are revealed
# so we can tell when the game ends.
#
# If delay is set, don't win yet.
#
proc indicateCardPlayed {w delay} {
	global table
	incr table(cardsToReveal) -1
	if { !$delay } {
		checkForWin
	}
}

proc checkForWin {} {
	global table
	if { $table(cardsToReveal) <= 0 } {
		endGame $table(id) "won" 1
	}
}


#
# tableauDoubleClick---flip the card right-side up
#
proc tableauDoubleClick {itemId w x y} {
	global table score

	set vs $table($itemId,cardVS)

	# first switch the bitmap
	refaceCard $itemId $w $vs
	$w dtag $itemId doubleClickableCard

	# next configure the card for dragging
	$w addtag dragableCard withtag $itemId
	set table($itemId,cardPickProc) cardPick
	set table($itemId,cardDropProc) cardDrop

	# and the card should accept others
	tableauMakeCardDropAccepting $itemId

	# and the card should be part of the correct tableau
	$w addtag "tableau$table($itemId,tableauColumn)" withtag $itemId
	set table($itemId,dragFindFriendProc) tableauFindFriends
	# (We must be the first visible card on the tableau.)
	set table($itemId,tableauRow) 0

	set table($itemId,cardState) "faceUpOnTableau"

	# Currently, the button is down.  This is bad
	# since we haven't done dragableCardPress yet.
	# Run it now to recover.
	dragableCardPress $itemId $w $x $y

	# Fianlly, the score.
	incr score(standardScore) 5
	updateScore $w

	# And a chance of winning.
	indicateCardPlayed $w 0

	# puts stderr "new card id $itemId has value $vs"
}

#
# fill in the tableau
#
proc mkFullTableau {w} {
	global table tableau
	foreach i "0 1 2 3 4 5 6" {
		set cardId $tableau($i,id)
		for { set j 0 } { $j <= $i } { incr j } {
			set lastCard $cardId
			set vs [dealNextCard]
	
			set cardX $tableau($i,x)
			set cardY $tableau($i,y)
			set cardId [ createCardBitmap $w $cardX $cardY $table(backFace) ]
			$w addtag outlineableCard withtag $cardId
			$w addtag doubleClickableCard withtag $cardId
			set table($cardId,doubleClickProc) tableauDoubleClick
			set table($cardId,cardVS) $vs
			set table($cardId,cardState) "burriedFaceDownInTableau"
			set table($cardId,cleanupProc) tableauCleanup
			set table($cardId,cleanupClosure) $lastCard
	
			set table($cardId,tableauColumn) $i
	
			# last card is face up
			if { $j == $i } {
				tableauDoubleClick $cardId $w $cardX $cardY
			}
		}
	}
}

proc tableauCleanup {itemId w x y target closure} {
	global table

	# puts stderr "tableauCleanup: itemId=$itemId closure=$closure"

	#
	# Fix ourselves.
	# Remove ourselves from our tableau.
	# Hack alert:  we don't do this here if we're dropping on
	# the tableau again.  This will be cleaned up in
	# tableauDropDrop.
	#
	if { $table($target,cardState) != "faceUpOnTableau" &&
			$table($target,cardState) != "tableau"} {
		$w dtag $itemId "tableau$table($itemId,tableauColumn)"
		unset table($itemId,tableauColumn)
	}

	#
	# Fix up who we used to be sitting over.
	#
	if { $closure == "null" } { 
		return
	}
	switch -- $table($closure,cardState) {
		tableau {
			# We're over the tableau.  Now it's empty.
			# Make it receptive of kings
			set table($closure,dropAccepts) "k\[cdhs\]"
		}
		burriedFaceDownInTableau {
			# don't do anything---it will just work
		}
		burriedFaceUpOnTableau {
			# We had some card (marked with closure) burriedFaceUp.
			# Reactivate it.
			tableauMakeCardDropAccepting $closure
			$w addtag dragableCard withtag $closure
			$w addtag outlineableCard withtag $closure
			set table($closure,cardState) "faceUpOnTableau"

		}
		* {
			error "tableauCleanup: unknown closure $closure, cardState: $table($closure,cardState)"
		}
	}
}

proc tableauDropDrop {itemId w x y target} {
	global table deck score

	# first unhilight the target
	genericDropLeave $itemId $w $x $y $target

	# Adjust the score.
	# (We do this early before we change the owner of the card.)
	if { $table($itemId,cardState) == "inPile" } {
		# From pile to tableau --> score.
		incr score(standardScore) 5
		updateScore $w
	}

	# Move the card to the right place.
	# Once again, handle stacks of cards correctly.
	set oldPlace [$w coords $itemId]
	set bbox [$w bbox $target]
	moveAllRelatively $w selected \
		[lindex $oldPlace 0] [lindex $oldPlace 1] \
		[lindex $bbox 0] \
		[expr { $table(stackedCardOffset)+[lindex $bbox 1] }]
	# adjust kings so there is no offset
	set vs $table($itemId,cardVS)
	if { [string index $vs 0] == "k" } {
	    $w move selected 0 [expr { -$table(stackedCardOffset) }]
	}

	# Adjust the new card's receptivity.
	# (Only if it's a single card.)
	if { $table(selectedCount) <= 1 } {
		tableauMakeCardDropAccepting $itemId
	}

	# If we're doing multiple cards,
	# the middle one should no longer be dragable.
	# (Unless it's going over an empty tableau spot).
	if { $table(selectedCount) > 1 && 
			$table($target,cardState) != "tableau" } {
		$w dtag $itemId dragableCard
		$w dtag $itemId outlineableCard
		# Don't forget to unhilight it.
		unhilightCard $itemId $w $x $y
	}

	##### target stuff here
	# Make the old card unreceptive.
	set table($target,dropAccepts) "xx"
	# If it's a middle card, make it undragable.
	if { $table($target,tableauRow) > 0 } {
		$w dtag $target dragableCard
		$w dtag $target outlineableCard
	}
	if { $table($target,cardState) == "faceUpOnTableau" } {
		# target could also be just the tableau
		set table($target,cardState) "burriedFaceUpOnTableau"
	}

	# set up closure to reactive the now burried card
	set table($itemId,cleanupProc) tableauCleanup
	set table($itemId,cleanupClosure) $target

	# Make each card part of the new tableau.
	set newTag "tableau$table($target,tableauColumn)"
	if { [regexp "OnTableau$" $table($itemId,cardState)] == 1} {
		set oldTag "tableau$table($itemId,tableauColumn)"
	    set rowChange [expr { $table($target,tableauRow)+1-$table($itemId,tableauRow) } ]
	} else {
		# puts stderr "tableauDropDrop: card $itemId, state $table($itemId,cardState) not on tableau"
		set oldTag {}
		set rowChange [expr { $table($target,tableauRow)+1 } ]
	}
	# puts stderr "tableauDropDrop: item $itemId, target $target dtag'ing $oldTag"
	foreach cardId [$w find withtag selected] {
		set table($cardId,tableauColumn) $table($target,tableauColumn)
		$w dtag $cardId $oldTag
		$w addtag $newTag withtag $cardId
		set table($cardId,dragFindFriendProc) tableauFindFriends
		# puts stderr "tableauDropDrop: dragFindFriendProc reset for $cardId"
		if { $oldTag == {} } {
			set table($cardId,tableauRow) $rowChange
		} else {
			incr table($cardId,tableauRow) $rowChange
		}
	}

	# Change the card's state.
	# (With multiple cards, they must have come from the tableau
	# and so their state is already correct.)
	if { $table(selectedCount) <= 1 } {
		set table($itemId,cardState) "faceUpOnTableau"
	}

	# Check for a win, just in case this card
	# was pulled off the pile.
	checkForWin
}


#
# ...and don't forget the score.
#
proc mkScore {w} {
	global table score
	set score(x) [expr { 2*$table(cardWidth)+3*$table(gutter) } ]
	set score(y) [expr { $table(gutter)+$table(cardWidth)/2 } ]
	set score(casinoScore) -52
    set score(standardScore) [expr { -7*5 } ]
	set score(id) [$w create text $score(x) $score(y) \
		-anchor w \
		-font $table(font) -text "" \
		-fill $table(fg) ]
	set table($score(id)) score
	updateScore $w
}

#
# Call updateScore after score changes to update the display.
#
proc updateScore {w} {
	global score table
	if { $table(scoringMethod) == "standard" } {
		set s $score(standardScore)
	} else {
		set s "\$$score(casinoScore)"
	}
	$w itemconfig $score(id) -text "$s\n$table(scoringMessage)"
}



#
# debug stuff
#
proc debugProc {itemId w x y} {
	global table
	set vs ""
	if { [info exists table($itemId,cardVS)] == 1 } {
		set vs $table($itemId,cardVS)
	}
	set state ""
	if { [info exists table($itemId,cardState)] == 1 } {
		set state $table($itemId,cardState)
	}
	set tableauColumn ""
	if { [info exists table($itemId,tableauColumn)] == 1 } {
		set tableauColumn "tableauColumn=$table($itemId,tableauColumn)"
	}
	set tableauRow ""
	if { [info exists table($itemId,tableauRow)] == 1 } {
		set tableauRow "tableauRow=$table($itemId,tableauRow)"
	}
	set dropAccepts ""
	if { [info exists table($itemId,dropAccepts)] == 1 } {
		set dropAccepts "dropAccepts=$table($itemId,dropAccepts)"
	}
	puts stderr "dragableCard $itemId $w $x $y $vs $state $tableauColumn $tableauRow $dropAccepts"
}



#
# start things
#
proc mkNewGame {w} {
	global table

	$w delete all

	set table(gameStatus) building
	set table(scoringMessage) "Preparing..."

	mkScore $w
	mkDeck $w
	mkEmptyDeck $w
	mkTableau $w
	mkFoundation $w
	mkFullTableau $w

	endGameChangeMenus

	set table(gameStatus) startable
	set table(scoringMessage) "Good\nluck!"
	updateScore $w

	$w addtag untouchedCard withtag all	
}


proc beginGame {item w x y} {
	global table emtpyDeck

	if { $table(gameStatus) != "startable" } {
		return
	}
	set table(gameStatus) running
	set table(scoringMessage) ""
	updateScore $w

	$w dtag untouchedCard
	# puts stderr "beginGame"

	# fix the empty deck based on the options
	if { $table(scoringMethod) == "standard" ||
			($table(scoringMethod) == "casino" &&
			 $table(turnCount) == 3)} {
		enableEmptyDeck emptyDeck $w
	}
	normalEmptyDeck emptyDeck $w

	#
	# score changes every 15 seconds
	# Only start the decay daemon once.
	# We used to start it every game start and then we
	# ended up with lots of them all decaying the score :->.
	#
	if { [info exists table(scoreDecayDelay)] } { } else {
		set table(scoreDecayDelay) 15000
		after $table(scoreDecayDelay) "decayScore $w $table(scoreDecayDelay)"
	}

	# Remember when we started for the possible winning bonus.
	set table(startTime) [getclock]
	set table(pauseTime) 0

	beginGameChangeMenus
}

proc decayScore {w delay} {
	global score table
	if { $table(gameStatus) == "running" } {
		incr score(standardScore) -2
		updateScore $w
		#
		# Time out the game after a while.
		#
		if { $score(standardScore) < -800 } {
			endGame $table(id) "quit" 1
		}
	}
	after $delay "decayScore $w $delay"
}

proc endGame {w how showScores} {
	# w is expected to be $table(id)
	global table score

	if { $table(gameStatus) == "paused" } { unpauseGame }

	if { $table(gameStatus) != "running" } {
		return
	}

	set table(endTime) [getclock]
	if { $how == "won" } {
		set timeDelta [expr { $table(endTime)-$table(startTime)-$table(pauseTime) } ]
		set bonusDelta [expr { ($score(standardScore)-$timeDelta)*10 } ]
		# Can't loose in bonus.
		if { $bonusDelta < 0 } { set bonusDelta 0 }
		# To track potential bonus bugs, squirrel away these values.
		set score(timeDelta) $timeDelta
		set score(bonusDelta) $bonusDelta
		incr score(standardScore) $bonusDelta
		set table(scoringMessage) "You\nwon!"
	} else {
		set table(scoringMessage) "Game\nover."
	}
	set table(gameStatus) stopped
	updateScore $w

	endGameChangeMenus

	#
	# show high scores
	#
	registerNewScore $showScores
}

mkNewGame $table(id)
