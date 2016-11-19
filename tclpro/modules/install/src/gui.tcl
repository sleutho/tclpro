# gui.tcl --
#
#	This file contains the GUI for the Unix installer for TclPro.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
# See the file "license.terms" for information on usage and redistribution of this file.
# 
# RCS: @(#) $Id: gui.tcl,v 1.8 2002/05/27 23:39:47 andreas_kupries Exp $

namespace eval gui {
    # need Expect for the 
    wm withdraw .

    # These variables store window navigation information. 
    #   thisIndex	Stores the index into the windowFlow list of the
    #			current window being displayed.  Initialize to 0 so the
    #			Welcome window is the first window displayed.
    #   direction	The direction that was just requested (back or next)
    #   mainMenuFork	The window index to display after the main fork.
    #   sharedMenuFork	The alternative window index to display from the menu.
    variable thisIndex      0
    variable direction      next
    variable mainMenuFork   0
    variable sharedMenuFork 0

    # windowFlow -
    # This is a state diagram that indicates the flow from one window to the 
    # next.  It dictates which window is shown, based on where you are and
    # which button was pressed.  The XXXFork and XXXLoopback windows are a 
    # pseudo windows, with the sole purpose of determining which window to
    # display next. 

    variable windowFlow {
	Welcome
	PreMenuFork	
	MainMenu


	MainMenuFork	
	AcrobatLicense
	AcrobatDestination
	AcrobatReady
	AcrobatInstall
	AcrobatFinish
	MainMenuLoopback


	MainMenuFork	
	TclProLicense
	TclProDestination
	TclProPlatform
	TclProComponents
	TclProReady
	TclProInstall
	TclProFinish
	MainMenuLoopback


	MainMenuFork
	SharedLicense
	TclProDestination
	TclProPlatform
	TclProComponents
	TclProReady
	TclProInstall
	SharedHostPort
	TclProFinish
	MainMenuLoopback
	

	MainMenuFork	
	ServerLicense
	ServerDirs
	ServerUserGroup
	ServerPort
	ServerReady
	ServerInstall
	ServerLaunch
	ServerFinish
	MainMenuLoopback
    }

    # windowState -
    # This array stores information about the window that is used when 
    # displaying a particular window.  Foreach window, the button state 
    # of the three main buttons (backBut, nextBut and doneBut) are 
    # indicated, as well as a command to call to determine if the window
    # should be displayed and a command that is called when the next 
    # button is pressed.

    variable windowState 
    array set windowState {
	Welcome		   {disabled active   normal   {} {}}
	PreMenuFork	   {normal   active   normal   {} {}}
	MainMenu  	   {normal   active   normal   {} {}}	
	MainMenuFork	   {normal   active   normal   {} {}}
	MainMenuLoopback   {normal   active   normal   {} {}}	

	AcrobatLicense	   {normal disabled  normal   {} {}}
	AcrobatDestination  {normal   active   normal   
	                   {} {gui::MakeAcrobatDestDir}}
	AcrobatReady	   {normal   active   normal   {} {}}	
	AcrobatInstall	   {disabled disabled active   {} {}}
	AcrobatFinish	   {disabled active   normal   {} {}}	

	TclProLicense	   {normal disabled  normal   {} {}}
	TclProDestination  {normal   active   normal   
	                   {} {gui::MakeTclProDestDir}}
	TclProPlatform	   {normal   active   normal
	                   {gui::ShowPlatforms} {}}
	TclProComponents   {normal   active   normal   
	                   {gui::ShowComponents} {}}
	TclProReady	   {normal   active   normal   {} {}}	
	TclProInstall	   {disabled disabled active  
	                   {gui::ShowTclProInstall} {}}
	TclProInstallKey   {disabled active   normal   
	                   {gui::ShowLicenseKey} {gui::LaunchLicense}}
	TclProFinish	   {disabled  active  normal {} {}}	

	SharedLicense	   {normal disabled normal   {} {}}
	SharedHostPort     {disabled active   normal   
	                   {gui::ShowLicenseKey} {gui::MakeLicenseFile}}

	ServerLicense	   {normal  disabled   normal   {} {}}
	ServerDirs	   {normal   active   normal  
	                   {} {gui::MakeServerDirs}}	
	ServerUserGroup	   {normal   active   normal   
                           {} {gui::CheckServerUserGroup}}	
	ServerPort	   {normal   active   normal   {} {gui::CheckServerPort}}	
	ServerReady	   {normal   active   normal   {} {}}	
	ServerInstall	   {disabled disabled disabled {} {}}
	ServerLaunch       {disabled active   normal
	                   {} {gui::LaunchServer}}
	ServerFinish	   {disabled active   normal   {} {}}	
    }

    # Widgets that are used throughout the GUI.

    variable mainWin   .mainWin
    variable mainFrm   {}
    variable backBut   {}
    variable nextBut   {}
    variable doneBut   {}
    variable sharedRad {}
    variable serverRad {}

    # Text variables used by each pane to set the button names and window 
    # title.

    variable backVar
    variable nextVar
    variable doneVar
    variable titleVar

    # label for required disk space
    variable requiredSpace

    # The name of the splash screen gif.

    variable image [image create photo -file $IMAGE]

    # The destination directory to install TclPro into.
    # Booleans indicating if Tcl, Tk, Incr, TclX, Expect should 
    # be installed.

    variable destDir        $::DEFTCLPRODIR
    variable acrobatDestDir $::DEFACROBATDIR
    variable serverDestDir  $::DEFSERVERDIR
    variable serverLogDir   $::DEFSERVERLOGDIR
    variable serverGID      $::DEFSERVERGID
    variable serverUID      $::DEFSERVERUID
    variable serverPort     $::DEFSERVERPORT
    variable launchServer   1
    variable installLicense 1

    # These are used by the Ajuba Solutions License Server.
    
    variable hostVar
    variable portVar

    # Initialize each install option based on what platforms and components
    # are available.

    set lop {}
    foreach {plat desc} [install::getPlatforms $::installImageRoot] {
	variable install$plat 0
	lappend lop $plat
    }
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	variable install$comp 0
    }

    # Cache configuration options so they dont need to be recalculated
    # each time.

    variable titleFont {Helvetica 14 bold}
    variable msgWidth  {}
    variable initialDisplay 1

    # Encourage a sane font on all platforms

    option add *Label.font {Helvetica 11}
    option add *Button.font {Helvetica 11}
    option add *Checkbutton.font {Helvetica 11}
    option add *Radiobutton.font {Helvetica 11}
    option add *Text.font {Helvetica 11}
    option add *Entry.font {Helvetica 11}
}

# gui::showWindow --
#
#	Show the main installation window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::showWindow {} {
    # Initialize the menu options to be the first item in the list.  Do this
    # now because this is the first time the window flow and the necessary
    # procs have been defined.  If we did this in the View routine, it would
    # override the value on each display.

    variable mainMenuFork   [gui::GetWindowIndex TclProLicense]
    variable sharedMenuFork [gui::GetWindowIndex SharedLicense]

    # Set the checkbox that corresponds to the OS the installer is running on
    # and checkbox for the common option to true.    

    if {[info exists gui::install$::tclproPlatform]} {
	set gui::install$::tclproPlatform 1
    }
    if {[info exists gui::installcommon]} {
	set gui::installcommon 1
    }
    if {[info exists gui::installCDev]} {
	set gui::installCDev 1
    }

    # calculate file sizes & file counts now
    install::calculateSizeAndCount $::installImageRoot

    # Now create the window.
    gui::CreateWindow
}

# gui::CreateWindow --
#
#	Create the framework for the installation GUI.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::CreateWindow {} {
    variable mainWin
    variable thisIndex    
    variable mainFrm
    variable backBut
    variable nextBut
    variable doneBut
    variable titleFont
    
    set top [toplevel $mainWin]
    wm protocol $top WM_DELETE_WINDOW {gui::ExitInstaller}
    wm minsize  $top 350 350

    # Add a trace on the title variable so panes can set the title 
    # without knowledge of the main window name.

    trace variable ::gui::titleVar w {gui::SetWindowTitle}
    set gui::titleVar $::TCLPRO_TITLE

    set bd 2
    set pad 6
    set width 10

    # This wont affect the American verison, but allows the strings to
    # change without clipping any new strings in the buttons.

    foreach s [list $::BACK_BUT $::NEXT_BUT $::DONE_BUT \
	    $::FINISH_BUT $::IAGREE_BUT $::QUIT_BUT $::MENU_BUT] {
	if {[string length $s] > $width} {
	    set width [string length $s]
	}
    }

    # Create an pack the widgets.  The bindings and state for the buttons 
    # will be established in the gui::updateWindow routine.

    set mainFrm [frame $top.mainFrm -bd $bd -relief raised]
    set butFrm  [frame $top.butFrm]
    set backBut [button $butFrm.backBut -width $width -default disabled \
	    -state   [gui::GetBackState $thisIndex] \
	    -command {gui::GotoWindow back} \
            -textvariable gui::backVar]
    set nextBut [button $butFrm.nextBut -width $width -default disabled \
	    -state   [gui::GetNextState $thisIndex] \
	    -command {gui::GotoWindow next} \
            -textvariable gui::nextVar]
    set doneBut [button $butFrm.doneBut -width $width -default disabled \
	    -state   [gui::GetDoneState $thisIndex] \
	    -command gui::ExitInstaller \
            -textvariable gui::doneVar]

    bind $backBut <Return> {%W invoke}
    bind $nextBut <Return> {%W invoke}
    bind $doneBut <Return> {%W invoke}

    grid $backBut -row 0 -column 0 -sticky e -padx $pad
    grid $nextBut -row 0 -column 1 -sticky e
    grid $doneBut -row 0 -column 3 -sticky e
    grid columnconfigure $butFrm 2 -minsize 20

    grid $butFrm  -row 1 -column 0 -sticky e -padx $pad -pady $pad
    grid $mainFrm -row 0 -column 0 -sticky nswe -padx $pad -pady $pad
    grid columnconfigure $mainWin 0 -weight 1
    grid rowconfigure    $mainWin 0 -weight 1

    # Now display the initial window.

    gui::ViewWindowIndex $thisIndex
    focus $nextBut
    return
}

# gui::GotoWindow --
#
#	Goto the previous or next window in the window flow list.
#
# Arguments:
#	dir	The direction to goto (back or next.)
#
# Results:
#	None.

proc gui::GotoWindow {dir} {
    variable direction
    variable mainFrm
    variable thisIndex
    variable backBut
    variable nextBut
    variable doneBut

    # If we are going forward, and there is a value for the next command
    # evaluate the command.  If it returns true, the values for this 
    # window are OK, set the command to empty so it is not executed next 
    # time.  Otherwise, if the command failed, the user needs to fix the
    # values for this window.  Just return without advancing the display.
    
    set nextCmd [gui::GetNextCmd $thisIndex]
    if {($dir == "next") && ($nextCmd != {})} {
	if {![eval $nextCmd]} {
	    return
	}
    }

    # Destroy all of the children in the main frame.

    eval {destroy} [winfo children $mainFrm]

    # Loop until a window that is OK to display is found.  A window
    # is OK to display if the command checker is an empty string or
    # the command checker returns true when evaluated.

    set newIndex $thisIndex
    while {1} {
	set newIndex [gui::GetNewWindowIndex $newIndex $dir]
	if {$newIndex == $thisIndex} {
	    error "Error: looping back to the same window as before!"
	}
	set cmd [gui::GetWindowChecker $newIndex]
	if {($cmd == {}) || [eval $cmd]} {
	    break
	}
    }
    set thisIndex $newIndex
    set direction $dir

    # Call the routine that draws the new window and set the focus
    # to the next button.

    focus $nextBut
    gui::ViewWindowIndex $thisIndex

    return
}

# gui::ViewWindowIndex --
#
#	View the window pane at a particular index.
#
# Arguments:
#	index	The index of the window to view.
#
# Results:
#	None.

proc gui::ViewWindowIndex {index} {
    variable backBut
    variable nextBut
    variable doneBut

    # Now update the state of the three main buttons.

    $backBut configure -state [gui::GetBackState $index]
    $nextBut configure -state [gui::GetNextState $index]
    $doneBut configure -state [gui::GetDoneState $index]

    gui::View[lindex $gui::windowFlow $index]
    return
}

# gui::ExitInstaller --
#
#	Trap exit events and verify that this is what they want to do.
#	If the done button contains the finish string, then no warning
#	should be generated before exiting, otherwise warn before exiting.
#
# Arguments:
#	None.
#
# Results:
#	None.  If the user verifies the exit event, then quit.

proc gui::ExitInstaller {} {
    variable mainWin
    variable doneVar

    if {$doneVar != $::FINISH_BUT} {
	set button [tk_messageBox -default yes -icon question \
	    -parent $mainWin -title "Exit Install" -type yesno \
	    -message $::INSTALL_ABORT]
	
	if {$button == "yes"} {
	    exit
	}
    } else {
	exit
    }
    return
}

# gui::ViewWelcome --
#
#	Show the Welcome Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewWelcome {} {
    variable initialDisplay
    variable mainWin
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar
    variable image

    set pad   6
    set pad2 20

    # Create the TclPro image and Welcome text message.

    set proLbl   [label $mainFrm.tclpro -image $image]
    set titleLbl [label $mainFrm.title -text $::TITLE_WELCOME \
	    -font $gui::titleFont -anchor w -textvariable gui::titleStr]
    set msgLbl   [label $mainFrm.msg -justify left -text $::WELCOME_GUI]

    # Set the namespace var that caches the message label width.  All
    # remaining message labels will use this value as the wraplength.

    set gui::msgWidth [expr {[winfo reqwidth $proLbl] - (3*$pad) + (2*$pad2)}]
    $msgLbl configure -wraplength [expr {$gui::msgWidth - (2*$pad2)}]

    pack $proLbl   -padx $pad2 -pady $pad
    pack $titleLbl -anchor w -padx $pad2 -fill x -expand true
    pack $msgLbl   -anchor w -padx $pad2 -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    if {$initialDisplay} {
	# ORDER MATTERS IN THIS ROUTINE!!!
	# 1) Withdraw the window so it does not flicker on the screen
	# 2) Update all idletasks so the winfo commands report good values.
	# 3) Put the longest title string in the title and update idletasks.
	# 4) Move the window so it is centered in the middle of the screen.
	# 5) Deiconify the window.

	wm withdraw $mainWin
	update idletasks

	set baseStr   $gui::titleStr
	set maxWidth  [winfo width $titleLbl]
	foreach t [info vars ::TITLE_*] {
	    set ::gui::titleStr [set $t]
	    if {[winfo reqwidth $titleLbl] > $maxWidth} {		
		set maxWidth [winfo reqwidth $titleLbl]
		set maxStr $t
	    }
	}
	set gui::titleStr $maxStr
	update idletasks

	# Center the window in the middle of the screen.
	
	set width  [expr {[winfo reqwidth  $mainWin] + 20}]
	set height [winfo reqheight $mainWin]
	set w [winfo screenwidth .]
	set h [winfo screenheight .]
	set x [expr {($w/2)-($width/2)}]
	set y [expr {($h/2)-($height/2)}]
	wm geometry $mainWin ${width}x${height}+${x}+${y}
	
	set gui::titleStr $baseStr
	wm minsize $mainWin $width $height
	wm deiconify $mainWin
	set initialDisplay 0
    }

    return
}

# gui::ViewPreMenuFork --
#
#	Determine if the menu should be shown at all.  If it cannot, then
#	jump to the TclProLicense window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewPreMenuFork {} {
    variable thisIndex
    variable mainMenuFork

    if {$gui::direction == "back"} {
	incr thisIndex -1
    } elseif {[install::hasAcrobat $::installImageRoot $::tclproPlatform] \
	    || [install::hasServer $::installImageRoot $::tclproPlatform]} {
	incr thisIndex  1
    } else {
	set thisIndex [gui::GetWindowIndex TclProLicense]
    }

    gui::ViewWindowIndex $thisIndex

    return
}

# gui::ViewMainMenu --
#
#	Show the Main Menu Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewMainMenu {} {
    variable backVar
    variable nextVar
    variable doneVar
    variable mainFrm
    variable sharedRad
    variable serverRad
    variable shareTclProRad
    variable servMsgLbl
    variable noteLbl

    set pad   6
    set pad2 20
    set pad3 40

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_MAIN_MENU \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::MAIN_MENU_GUI \
	    -wraplength $gui::msgWidth]
    set tclproRad  [radiobutton $mainFrm.tclproRad -text $::SINGLE \
            -value [gui::GetWindowIndex TclProLicense] \
            -variable gui::mainMenuFork -justify left \
	    -command {gui::UpdateMainMenuOptions 0}]

    pack $titleLbl   -anchor w -padx $pad -pady $pad
    pack $msgLbl     -anchor w -padx $pad
    pack $tclproRad  -anchor w -padx $pad2 -pady $pad2

    # Only show the server option if the install file exists.

    if {[install::hasServer $::installImageRoot $::tclproPlatform]} {
	set shareTclProRad [radiobutton $mainFrm.shareTclProRad -justify left \
		-text $::SHARED -anchor s \
		-variable gui::mainMenuFork \
		-command {gui::UpdateMainMenuOptions 1}]

	set servMsgLbl [label $mainFrm.servMsgLbl -justify left \
		-text $::SHARED_MENU_GUI \
		-wraplength [expr {$gui::msgWidth - (2*$pad3)}]]
	set noteLbl   [label $mainFrm.note -justify left \
		-text $::SHARED_MENU_NOTE \
		-wraplength [expr {$gui::msgWidth - (2*$pad3)}]]
	set sharedRad  [radiobutton $mainFrm.sharedRad -text $::TCLPRO \
		-value [gui::GetWindowIndex SharedLicense] \
		-variable gui::sharedMenuFork \
		-command {gui::UpdateMainMenuOptions 1}]
	set serverRad  [radiobutton $mainFrm.serverRad -text $::SERVER \
		-value [gui::GetWindowIndex ServerLicense] \
		-variable gui::sharedMenuFork \
		-command {gui::UpdateMainMenuOptions 1}]
	
	pack $shareTclProRad -anchor w -padx $pad2
	pack $servMsgLbl -anchor w -padx $pad3
	pack $noteLbl    -anchor w -padx $pad3
	pack $sharedRad  -anchor w -padx $pad3
	pack $serverRad  -anchor w -padx $pad3

	if {$gui::mainMenuFork == $gui::sharedMenuFork} {
	    gui::UpdateMainMenuOptions 1
	} else {
	    gui::UpdateMainMenuOptions 0
	}
    }

    # Only show the acrobat option if the install file exists.

    if {[install::hasAcrobat $::installImageRoot $::tclproPlatform]} {
	set acrobatRad [radiobutton $mainFrm.acrobatRad -text $::ACROBAT \
		-value [gui::GetWindowIndex AcrobatLicense] \
		-variable gui::mainMenuFork -justify left \
		-command {gui::UpdateMainMenuOptions 0}]
	pack $acrobatRad -anchor w -padx $pad2 -pady $pad2
    }

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::UpdateMainMenuOptions --
#
#	Update the radio buttons based on which one is selected.
#
# Arguments:
#	enable	Boolean indicating if the shared radiobuttons should be active.
#
# Results:
#	None.

proc gui::UpdateMainMenuOptions {enable} {
    variable sharedRad
    variable serverRad
    variable shareTclProRad
    variable servMsgLbl
    variable noteLbl
    
    if {![winfo exists $sharedRad] || ![winfo exists $sharedRad]} {
	return
    }
    if {$enable} {
	$sharedRad configure -state normal
	$serverRad configure -state normal
	$sharedRad configure -variable gui::sharedMenuFork
	$serverRad configure -variable gui::sharedMenuFork
	$servMsgLbl configure -foreground [$sharedRad cget -foreground]
	$noteLbl    configure -foreground [$sharedRad cget -foreground]
	set gui::mainMenuFork $gui::sharedMenuFork
	$shareTclProRad configure -value $gui::sharedMenuFork
    } else {
	$sharedRad configure -state disabled
	$serverRad configure -state disabled
	$sharedRad configure -variable ""
	$serverRad configure -variable ""
	$servMsgLbl configure -foreground [$sharedRad cget -disabledforeground]
	$noteLbl    configure -foreground [$sharedRad cget -disabledforeground]
    }
    return
}

# gui::ViewMainMenuFork --
#
#	Pseudo Window.  This routine does not display a window, instead it
#	changes the current window variable to the next window to display
#	and displays that window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewMainMenuFork {} {
    variable thisIndex
    variable mainMenuFork

    if {$gui::direction == "back"} {
	incr thisIndex -1
    } else {
	set thisIndex $mainMenuFork
    }

    gui::ViewWindowIndex $thisIndex

    return
}

# gui::ViewMainMenuLoopback --
#
#	Pseudo Window.  This routine does not display a window, instead it
#	changes the current window variable to the main menu window and
#	displays that window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewMainMenuLoopback {} {
    variable thisIndex
    variable direction

    set direction "next"
    set thisIndex [gui::GetWindowIndex PreMenuFork]
    gui::ViewWindowIndex $thisIndex

    return
}

# gui::ViewSharedMenu --
#
#	Show the Shared Menu Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewSharedMenu {} {
    variable backVar
    variable nextVar
    variable doneVar
    variable mainFrm

    set pad   6
    set pad2 20

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_SHARED_MENU \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::SHARED_MENU_GUI \
	    -wraplength $gui::msgWidth]
    set tclproRad  [radiobutton $mainFrm.tclproRad -text $::TCLPRO \
            -value [gui::GetWindowIndex SharedLicense] \
            -variable gui::sharedMenuFork]
    set serverRad  [radiobutton $mainFrm.serverRad -text $::SERVER \
            -value [gui::GetWindowIndex ServerLicense] \
            -variable gui::sharedMenuFork]
    set noteLbl   [label $mainFrm.note -justify left \
	    -text $::SHARED_MENU_NOTE \
	    -wraplength $gui::msgWidth]

    pack $titleLbl   -anchor w -padx $pad -pady $pad
    pack $msgLbl     -anchor w -padx $pad
    pack $tclproRad  -anchor w -padx $pad2
    pack $serverRad  -anchor w -padx $pad2
    pack $noteLbl    -anchor w -padx $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ViewSharedMenuFork --
#
#	Pseudo Window.  This routine does not display a window, instead it
#	changes the current window variable to the next window to display
#	and displays that window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewSharedMenuFork {} {
    variable thisIndex
    variable sharedMenuFork

    if {$gui::direction == "back"} {
	set thisIndex [gui::GetWindowIndex SharedMenu]
    } else {
	set thisIndex $sharedMenuFork
    }

    gui::ViewWindowIndex $thisIndex

    return
}

# gui::ViewTclProLicense --
#
#	Show the License Window for the TclPro branch.  This routine simply
#	calls the ViewLicense, but is needed to maintain the correct window
#	flow order.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProLicense {} {
    gui::ViewLicense $::LICENSE_GUI_TERMS $::LICENSE_TXT_NOLNBRK
    return
}

# gui::ViewSharedLicense --
#
#	Show the License Window for the Shared TclPro branch.  This routine
#	simply calls the ViewLicense, but is needed to maintain the correct
#	window flow order.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewSharedLicense {} {
    gui::ViewLicense $::LICENSE_GUI_TERMS $::LICENSE_TXT_NOLNBRK
    return
}

# gui::ShowPlatforms --
#
#	This routine determines if we have the necessary bits to show the
#	platforms window.
#
# Arguments:
#	None.
#
# Results:
#	Return a boolean, 1 means that we should show the Components
#	window, 0 means do not show it.

proc gui::ShowPlatforms {} {
    # If there is only one platform available for installation, do not 
    # display the Platform window.  Just set the install variable for
    # the single platform to true.

    set plat [install::getPlatforms $::installImageRoot]
    if {[expr {[llength $plat] <= 2}]} { 
	set ::gui::install[lindex $plat 0] 1
	return 0 
    } else {
	return 1
    }
}

# gui::ViewTclProPlatform --
#
#	Show the TclPro Platform Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProPlatform {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 20

    # Create the title and message widgets.

    set titleLbl [label $mainFrm.titleLbl \
            -text $::TITLE_PLATFORM \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::PLATFORM_GUI  \
	    -wraplength $gui::msgWidth]
    set filler  [frame $mainFrm.filler -height 10]
    set noteLbl  [label $mainFrm.note -justify left \
	    -text $::PLATFORM_GUI_NOTE -wraplength $gui::msgWidth]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $filler   -anchor w -padx $pad

    # Foreach UNIX platform that we support, display a checkbox for that
    # platform.

    foreach {os desc} [install::getPlatforms $::installImageRoot] {
	set chk [checkbutton $mainFrm.chk$os \
            -text $desc -variable gui::install$os]
	pack $chk -anchor w -padx $pad2
    }
    pack $noteLbl  -anchor w -padx $pad -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ViewTclProDestination --
#
#	Show the TclPro Destination Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProDestination {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6

    # Create the title, message, and directory entry.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_DESTDIR \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::DEST_DIR_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set dirEnt   [entry $mainFrm.dirEnt -textvariable gui::destDir]
    bind $dirEnt <Return> {$gui::nextBut invoke}

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $dirEnt   -fill x -padx [expr {$pad*2}] -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::MakeTclProDestDir --
#
#	Verify and create the install directory.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::MakeTclProDestDir {} {
    variable mainWin
    variable destDir

    # Disallow relative paths

    if {[file pathtype $destDir] == "relative"} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message [format $::DEST_DIR_ENTER_REL_PATH $destDir]]
	return 0
    }

    # If the dir doesn't exist, ask the user if they want to create it.

    if {![file exists $destDir]} {
	set button [tk_messageBox -default yes -icon question \
		-parent $mainWin -title $::TCLPRO_TITLE -type yesno \
		-message $::DEST_DIR_GUI_NOTEXIST]
	if {$button == "no"} {
	    return 0
	}
    }
    
    # Create the destination directory and any parent directories as needed.

    if {[catch {file mkdir $destDir} msg]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $msg]
	return 0
    }

    # Test to see if the directory is writable.

    if {![file writable $destDir]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $::DEST_DIR_NO_WRITE_PERMISSION]
	return 0
    }

    # After all that, everything is OK.

    return 1
}

# gui::ShowComponents --
#
#	This routine determines if we have the necessary bits to show the
#	component window.
#
# Arguments:
#	None.
#
# Results:
#	Return a boolean, 1 means that we should show the Components
#	window, 0 means do not show it.

proc gui::ShowComponents {} {
    # If there is only one component available for installation, do not 
    # display the Component window.  Just set the install variable for
    # the single component to true.

    set lop  [gui::GetSelectedPlatforms]
    set comp [install::getComponents $::installImageRoot $lop]
    if {[expr {[llength $comp] <= 2}]} { 
	set gui::install[lindex $comp 0] 1
	return 0 
    } else {
	return 1
    }
}

# install::calculateRequireSpace
#
#      This proc sets the value of gui::requiredSpace
#
# Arguments:
#       None
#
# Results:
#	none

proc gui::calculateRequiredSpace {} {

    set gui::requiredSpace [expr {[install::calculateRequiredSpace \
	    [gui::GetSelectedComponents] \
	    [gui::GetSelectedPlatforms]]/1024}]
    append gui::requiredSpace " k"
    return
}

# gui::ViewTclProComponents --
#
#	Show the TclPro Components Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProComponents {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 20
    set pad3 40

    # Create the title and message widgets.

    set titleLbl [label $mainFrm.titleLbl \
            -text $::TITLE_COMPONENTS \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::COMPONENTS_GUI  \
	    -wraplength $gui::msgWidth]
    set filler  [frame $mainFrm.filler -height 10]
    set subframe [frame $mainFrm.sub -bd 0 -relief flat]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $filler   -anchor w -padx $pad
    pack $subframe -anchor w -padx $pad

    # Foreach component that we ship, display a checkbox for that component.
    # Then set the TclPro checkbox to true since it doesn't hurt to suggest.

    set lop [gui::GetSelectedPlatforms]
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	set size [install::componentSize $comp $lop] 
	set chk [checkbutton $subframe.chk$comp \
            -text $desc -anchor w \
	    -variable gui::install$comp -command gui::calculateRequiredSpace]
	set sz [label $subframe.sz$comp -text "$size k" -anchor e]

	grid $chk $sz -sticky we
    }
    grid columnconfigure $subframe 0 -weight 1

    gui::calculateRequiredSpace

    set l1 [label $subframe.l1 -text "Disk Space Required"]
    set reqLbl [label $subframe.req \
	    -textvariable gui::requiredSpace] 
    grid $l1 $reqLbl -sticky we -ipady 10

    # Change the names of the main buttons.
    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ViewTclProReady --
#
#	Show the TclPro Ready Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProReady {} {
    variable destDir
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad 6

    set osList {}
    set osCount 0
    foreach {os desc} [install::getPlatforms $::installImageRoot] {
	if {[set gui::install$os] == 1} {
	    incr osCount
	    lappend osList $desc
	}
    }
    if {$osCount == 0} {
	set osList "None"
    }
    if {$osCount == 1} {
	set osPlurality " "
    } else {
	set osPlurality "s"
    }
    
    set compList {}
    set compCount 0
    set lop [gui::GetSelectedPlatforms]
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	if {[set gui::install$comp] == 1} {
	    incr compCount
	    lappend compList $desc
	}
    }
    if {$compCount == 0} {
	set compList "None\n"
    }
    if {$compCount == 1} {
	set compPlurality " "
    } else {
	set compPlurality "s"
    }

    # Create the title and message widgets.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_READY \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::INSTALL_GUI_READY_1 -wraplength $gui::msgWidth]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad

    # Create a grid for the description.
    # The old code used to use format and tabs -ugh!

    set subframe [frame $mainFrm.body]
    pack $subframe   -anchor w -padx $pad

    label $subframe.dest -text Destination -anchor w
    label $subframe.plat -text Platform$osPlurality -anchor w
    label $subframe.comp -text Component$compPlurality -anchor w

    set rightColumnWrapWidth [expr {int($gui::msgWidth * .667)}]
    label $subframe.destValue -text $destDir \
	    -wraplength $rightColumnWrapWidth -anchor w -justify left
    label $subframe.platValue -text [join $osList \n] \
	    -wraplength $rightColumnWrapWidth -anchor w -justify left
    label $subframe.compValue -text [join $compList \n] \
	    -wraplength $rightColumnWrapWidth -anchor w -justify left


    grid $subframe.dest $subframe.destValue -sticky nw
    grid $subframe.plat $subframe.platValue -sticky nw
    grid $subframe.comp $subframe.compValue -sticky nw

    set msgLbl2   [label $mainFrm.msg2 -justify left \
	    -text $::INSTALL_GUI_READY_2 -wraplength $gui::msgWidth]
    pack $msgLbl2   -anchor w -padx $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ShowTclProInstall --
#
#	This routine determines if we should show the Install window.  If 
#	no TclPro Components were selected, there is nothing to show.
#
# Arguments:
#	None.
#
# Results:
#	Return a boolean, 1 means that we should show the Components
#	window, 0 means do not show it.

proc gui::ShowTclProInstall {} {
    set result 0
    set lop [gui::GetSelectedPlatforms]
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	if {[set gui::install$comp] == 1} {
	    set result 1
	    break
	}
    }
    return $result
}

# gui::ViewTclProInstall --
#
#	Show the TclPro Install Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProInstall {} {
    global tclproPlatform installImageRoot
    variable mainWin
    variable mainFrm
    variable doneBut
    variable backVar
    variable nextVar
    variable doneVar
    variable counter 0
    variable statusSlider
    variable total

    set pad 6

    # Create the title, message, and directory entry.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_INSTALLING \
	    -font $gui::titleFont]

    set scaleFrm [frame $mainFrm.scaleFrm]
    set statusBar [frame $scaleFrm.statusBar -relief sunken -bd 2]
    set statusSlider [frame $statusBar.statusSlider -relief raised -bd 2 \
	    -bg blue]
    set statusEnt [entry $scaleFrm.entry -textvariable ::gui::statusVar \
	    -relief flat -bg [$mainFrm cget -bg] -bd 0 -justify left]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $scaleFrm -fill both -expand 1 -padx $pad -pady $pad

    grid $statusEnt -row 0 -column 1 -sticky we -columnspan 2 -pady $pad
    grid $statusBar   -row 1 -column 1 -sticky nswe
    grid rowconfigure $scaleFrm 1 -minsize 24
    grid columnconfigure $scaleFrm 0 -weight 1
    grid columnconfigure $scaleFrm 1 -weight 4
    grid columnconfigure $scaleFrm 2 -weight 1

    place $statusSlider -x 0 -y 0 -height 19

    # Convert the boolean install values into a list of platforms and a list
    # of component to be installed.

    set lop [gui::GetSelectedPlatforms]
    set loc [gui::GetSelectedComponents]

    $mainWin   configure -cursor "watch"
    $statusEnt configure -cursor "watch"
    $doneBut   configure -cursor "top_left_arrow"

    focus $doneBut
    update

    set total [install::estimate $installImageRoot $lop $loc]

    if {[catch {
	install::installPro $installImageRoot $gui::destDir \
		::gui::ProgressLog $lop $loc
    } msg]} {
	global errorInfo
	set message [format $::INSTALL_ERROR $msg]
	tk_messageBox -default ok -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $message
	catch {setup::openLogFile $gui::destDir}
	catch {setup::writeLogFile "\nInstall Error: $message\n"}
	catch {setup::writeLogFile "\n$errorInfo\n"}
	catch {setup::closeLogFile}
	exit
    }

    $mainWin   configure -cursor {}
    $statusEnt configure -cursor {}
    $doneBut   configure -cursor {}

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    after 20 {$gui::nextBut configure -state normal; $gui::nextBut invoke}
    return
}

# gui::ProgressLog --
#
#	This function is called whenever the back end generates a logging
#	message.
#
# Arguments:
#	msg	The logging message.
#
# Results:
#	None.

proc gui::ProgressLog {msg} {
    variable counter
    variable statusSlider
    variable destDir
    variable total

    set values [split $msg :]
    set name [string trim [lindex $values 1]]
    set file [file join ${destDir} *]

    if {[string match $file $name]} {
	set name [string range $name [string length ${destDir}/] end]
    } elseif {[string match [file nativename $file] $name]} {
	set name [string range $name \
		[string length [file nativename ${destDir}]/] end]
    } elseif {[string match "creating ${destDir}/*" $name]} {
	set index [string length "creating ${destDir}/"]
	set name  "Creating [string range $name $index end]"
    } elseif {[string match "Patching ${destDir}/*" $name]} {
	set index [string length "Patching ${destDir}/"]
	set name  "Patching [string range $name $index end]"
    }

    set ::gui::statusVar $name
    incr counter
    set part [expr {double($counter) / $total}]
    if {$part > 1} {
	set part 1.0
    }
    place $statusSlider -relwidth $part -x 0 -y 0 -height 19
    update idletasks
    
    return
}

# gui::ViewTclProInstallKey --
#
#	Show the TclPro Install License Key Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ShowLicenseKey {} {
    if {([lsearch [gui::GetSelectedComponents] "common"] >= 0) \
	    && ([lsearch [gui::GetSelectedPlatforms] \
	    $::tclproPlatform] >= 0)} {
	return 1
    } else {
	return 0
    }
}

# gui::ViewTclProInstallKey --
#
#	Show the TclPro Install License Key Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProInstallKey {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 12

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_INSTALL_KEY \
	    -font $gui::titleFont]
    set msgLbl [label $mainFrm.msg -justify left \
	    -text $::INSTALL_GUI_KEY \
	    -wraplength $gui::msgWidth]
    set yesRad [radiobutton $mainFrm.yesRad -text $::YES_BUT -value 1 \
	    -variable gui::installLicense]
    set noRad  [radiobutton $mainFrm.noRad -text $::NO_BUT -value 0 \
	    -variable gui::installLicense]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $yesRad   -anchor w -padx $pad2
    pack $noRad    -anchor w -padx $pad2

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::LaunchLicense --
#
#	If the user wants to install licenses, launch prolicense.
#
# Arguments:
#	None.
#
# Results:
#	Return a boolean, 1 means that we should show the next window
#	window, 0 means do not show it.

proc gui::LaunchLicense {} {
    global tclproPlatform
    variable installLicense

    if {$installLicense} {
	if {[catch {
	    exec [file join $gui::destDir $tclproPlatform \
		    bin $::TCLPRO_LICENSE] -nolicense &
	} msg]} {
	    puts $msg
	    return 0
	}
    }

    return 1
}

# gui::ViewSharedHostPort --
#
#	Show the Shared Network License Host Port Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewSharedHostPort {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 20

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_HOST_PORT \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::SHARED_GUI_HOST_PORT \
	    -wraplength $gui::msgWidth]
    set lblFrm [frame $mainFrm.lblGrm]
    set hostLbl [label $lblFrm.hostLbl -justify left \
	    -text $::SHARED_HOST \
	    -wraplength $gui::msgWidth]
    set hostEnt [entry $lblFrm.hostEnt -textvariable gui::hostVar \
	    -width 10]
    set portLbl [label $lblFrm.portLbl -justify left \
	    -text $::SHARED_PORT \
	    -wraplength $gui::msgWidth]
    set portEnt [entry $lblFrm.portEnt -textvariable gui::portVar \
	    -width 10]

    bind $hostEnt <Return> {$gui::nextBut invoke}
    bind $portEnt <Return> {$gui::nextBut invoke}

    grid $titleLbl -row 0 -column 0 -sticky nw   -padx $pad -pady $pad
    grid $msgLbl   -row 1 -column 0 -sticky nw   -padx $pad
    grid $lblFrm   -row 2 -column 0 -sticky nsew -padx $pad -pady $pad
    pack $hostLbl -side left -padx 20
    pack $hostEnt -side left
    pack $portLbl -side left -padx 20
    pack $portEnt -side left

    grid columnconfigure $mainFrm 3 -weight 1
    grid rowconfigure    $mainFrm 3 -weight 1

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::MakeLicenseFile --
#
#	Make the license file for a Shared Network License.
#
# Arguments:
#	None.
#
# Results:
#	Return a boolean, 1 means that we should show the next window
#	window, 0 means do not show it.

proc gui::MakeLicenseFile {} {
    variable mainWin
    variable hostVar
    variable portVar

    if {$hostVar == {}} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $::SHARED_NEED_HOST]
	return 0
    }
    if {$portVar == {}} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $::SHARED_NEED_PORT]
	return 0
    }
    if {[catch {incr portVar 0} msg]} {
	puts $msg
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $::SHARED_BAD_PORT]
	return 0
    }

    if {[catch { 
	install::saveLicenseFile $hostVar $portVar $gui::destDir
    } msg]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TCLPRO_TITLE -type ok \
		-message $msg]
	return 0
    }

    return 1
}

# gui::ViewTclProFinish --
#
#	Show the TclPro Finish Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewTclProFinish {} {
    global tclproPlatform
    variable mainFrm
    variable destDir
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 12

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_COMPLETE \
	    -font $gui::titleFont]

    set showPaths 0
    set lop [gui::GetSelectedPlatforms]
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	if {[set gui::install$comp] == 1} {
	    if { $comp == "common" } {
		set showPaths 1
	    }
	}
    }

    # Display a different message whether the Basic (common) component
    # is installed

    if {$showPaths == 0} {
	set doneMsg $::INSTALL_GUI_DONE_NO_PATHS
    } else {
	set osList {}
	foreach {os desc} [install::getPlatforms $::installImageRoot] {
	    if {[set gui::install$os] == 1} {
		append osList "\t[file join [file nativename $destDir] \
			$os bin]\n"
	    }
	}
	set doneMsg [format $::INSTALL_GUI_DONE $osList]
    }

    set msgLbl [text $mainFrm.msg -wrap word \
	    -relief flat -takefocus 0 ]
    $msgLbl insert 0.0 $doneMsg
    $msgLbl configure -state disabled
    
    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad -fill both -expand 1

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::MENU_BUT
    set doneVar $::FINISH_BUT

    # If there is only one option to show in the main menu, then do not
    # allow them to traverse back to the main menu.  Only enable the 
    # done button which exits the installer.

    if {![install::hasAcrobat $::installImageRoot $::tclproPlatform] \
	    && ![install::hasServer $::installImageRoot $::tclproPlatform]} {
	set nextVar $::NEXT_BUT
	$gui::nextBut configure -state disabled
	$gui::doneBut configure -state active
	focus $gui::doneBut
    }

    return
}

# gui::ViewServerLicense --
#
#	Show the License Window for the Server branch.  This routine simply
#	calls the ViewLicense, but is needed to maintain the correct window
#	flow order.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerLicense {} {
    gui::ViewLicense $::LICENSE_GUI_TERMS $::LICENSE_TXT_NOLNBRK
    return
}

# gui::ViewServerUserGroup --
#
#	Show the Server UserGroup Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerUserGroup {} {
    variable backVar
    variable nextVar
    variable doneVar
    variable mainFrm

    set pad   6
    set pad2 20

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_USER_GROUP \
	    -font $gui::titleFont]

    set uidMsgLbl   [label $mainFrm.uidMsg -justify left \
	    -text $::SERVER_USERID_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set uidEnt   [entry $mainFrm.uidEnt -textvariable gui::serverUID]
    bind $uidEnt <Return> {$gui::nextBut invoke}

    set gidMsgLbl   [label $mainFrm.gidMsg -justify left \
	    -text $::SERVER_GROUPID_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set gidEnt   [entry $mainFrm.gidEnt -textvariable gui::serverGID]
    bind $gidEnt <Return> {$gui::nextBut invoke}

    pack $titleLbl  -anchor w -padx $pad -pady $pad
    pack $uidMsgLbl -anchor w -padx $pad
    pack $uidEnt    -anchor w -padx [expr {$pad*2}] -pady $pad
    pack $gidMsgLbl -anchor w -padx $pad
    pack $gidEnt    -anchor w -padx [expr {$pad*2}] -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}


# gui::CheckServerUserGroup --
#
#	Verify and create the install directory.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::CheckServerUserGroup {} {
    variable mainWin
    variable serverUID
    variable serverGID

    package require Tclx

    # check that the serverUID is either a valid username or userid
    set badUID 0

    # check if it's a valid user
    if {[catch {
	if {[id convert user $serverUID] == ""} {
	    set badUID 1
	}
    } msg]} {
	# see if it's a user ID
	if {[catch {
	    if {[id convert userid $serverUID] == ""} {
		set badUID 1
	    }
	} msg]} {
	    set badUID 1
	}
    }

    if { $badUID } {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::SERVER_GUI_BAD_UID $serverUID]]
	return 0
    }

    # check that the serverGID is either a valid groupname or groupid

    set badGID 0

    # check if it's a valid user
    if {[catch {
	if {[id convert group $serverGID] == ""} {
	    set badGID 1
	}
    } msg]} {
	# see if it's a user ID
	if {[catch {
	    if {[id convert groupid $serverGID] == ""} {
		set badGID 1
	    }
	} msg]} {
	    set badGID 1
	}
    }

    if { $badGID } {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::SERVER_GUI_BAD_GID $serverGID]]
	return 0
    }

    return 1
}

# gui::ViewServerPort --
#
#	Show the Server Port Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerPort {} {
    variable backVar
    variable nextVar
    variable doneVar
    variable mainFrm

    set pad   6
    set pad2 20

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_PORT \
	    -font $gui::titleFont]

    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::SERVER_PORT_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set portEnt   [entry $mainFrm.portEnt -textvariable gui::serverPort]
    bind $portEnt <Return> {$gui::nextBut invoke}

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $portEnt  -anchor w -padx [expr {$pad*2}] -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::CheckServerPort --
#
#	Verify server port number
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the port was valid,
#	0 indicated the port was not a number.

proc gui::CheckServerPort {} {
    variable mainWin
    variable serverPort
    variable serverGID

    if { ![scan $serverPort {%[0-9]} dummy] } {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::SERVER_GUI_BAD_PORT $serverPort]]
	return 0
    }

    return 1
}

# gui::ViewServerDirs --
#
#	Show the Server Dirs Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerDirs {} {
    variable backVar
    variable nextVar
    variable doneVar
    variable mainFrm

    set pad   6
    set pad2 20

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_SERVER_DIRS \
	    -font $gui::titleFont]

    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::DEST_DIR_SERVER_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set dirEnt   [entry $mainFrm.dirEnt -textvariable gui::serverDestDir]
    bind $dirEnt <Return> {$gui::nextBut invoke}

    set logMsgLbl   [label $mainFrm.logMsg -justify left \
	    -text $::LOG_DIR_SERVER_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set logDirEnt   [entry $mainFrm.logDirEnt -textvariable gui::serverLogDir]
    bind $logDirEnt <Return> {$gui::nextBut invoke}

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $dirEnt   -fill x -padx [expr {$pad*2}] -pady $pad
    pack $logMsgLbl   -anchor w -padx $pad
    pack $logDirEnt   -fill x -padx [expr {$pad*2}] -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::MakeServerDestDirs --
#
#	Verify and create the install directories.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::MakeServerDirs {} {
    if {[gui::MakeServerDestDir]} {
	return [gui::MakeServerLogDir]
    } else {
	return 0
    }
}

# gui::MakeServerDestDir --
#
#	Verify and create the server install directory.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::MakeServerDestDir {} {
    variable mainWin
    variable serverDestDir

    # Disallow relative paths

    if {[file pathtype $serverDestDir] == "relative"} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::DEST_DIR_ENTER_REL_PATH $serverDestDir]]
	return 0
    }

    # If the dir doesn't exist, ask the user if they want to create it.

    if {![file exists $serverDestDir]} {
	set button [tk_messageBox -default yes -icon question \
		-parent $mainWin -title $::SERVER_TITLE -type yesno \
		-message [format $::DEST_DIRNAME_GUI_NOTEXIST $serverDestDir]]
	if {$button == "no"} {
	    return 0
	}
    }
    
    # Create the destination directory and any parent directories as needed.

    if {[catch {file mkdir $serverDestDir} msg]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message $msg]
	return 0
    }

    # Test to see if the directory is writable.

    if {![file writable $serverDestDir]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::DEST_DIRNAME_NO_WRITE_PERMISSION $serverDestDir]]
	return 0
    }

    # After all that, everything is OK.

    return 1
}
# gui::MakeServerLogDir --
#
#	Verify and create the server log directory.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::MakeServerLogDir {} {
    variable mainWin
    variable serverLogDir

    # Disallow relative paths

    if {[file pathtype $serverLogDir] == "relative"} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::DEST_DIR_ENTER_REL_PATH $serverLogDir]]
	return 0
    }

    # If the dir doesn't exist, ask the user if they want to create it.

    if {![file exists $serverLogDir]} {
	set button [tk_messageBox -default yes -icon question \
		-parent $mainWin -title $::SERVER_TITLE -type yesno \
		-message [format $::DEST_DIRNAME_GUI_NOTEXIST $serverLogDir]]
	if {$button == "no"} {
	    return 0
	}
    }
    
    # Create the destination directory and any parent directories as needed.

    if {[catch {file mkdir $serverLogDir} msg]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message $msg]
	return 0
    }

    # Test to see if the directory is writable.

    if {![file writable $serverLogDir]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
		-message [format $::DEST_DIRNAME_NO_WRITE_PERMISSION $serverLogDir]]
	return 0
    }

    # After all that, everything is OK.

    return 1
}

# gui::ViewServerReady --
#
#	Show the Server Ready Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerReady {} {
    variable serverDestDir
    variable serverLogDir
    variable serverPort
    variable serverUID
    variable serverGID
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad 6

    # Create the title and message widgets.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_READY \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text [format $::INSTALL_SERVER_GUI_READY $serverDestDir \
	            $serverLogDir $serverUID $serverGID $serverPort ] \
	    -wraplength $gui::msgWidth]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ViewServerInstall --
#
#	Show the Server Install Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerInstall {} {
    global tclproPlatform installImageRoot
    variable mainWin
    variable mainFrm
    variable doneBut
    variable backVar
    variable nextVar
    variable doneVar
    variable serverDestDir
    variable serverLogDir
    variable serverUID
    variable serverGID
    variable serverPort
    
    set pad 6

    # Create the title, message, and directory entry.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_INSTALLING \
	    -font $gui::titleFont]

    set resultFrm [frame $mainFrm.resultFrm -height 15]
    set resultText [text $mainFrm.resultFrm.text -width 1 -height 15 \
	    -wrap word -takefocus 0 -yscroll [list $mainFrm.resultFrm.sb set]]
    set resultSb [scrollbar $mainFrm.resultFrm.sb \
	    -command [list $resultText yview]]

    set statusLbl [label $mainFrm.statusLbl -justify left \
	    -text $::INSTALL_SERVER_GUI_RUNNING -wraplength $gui::msgWidth]

    pack $titleLbl -anchor w -padx $pad -pady $pad

    pack $resultSb -fill y -expand 0 -side right
    pack $resultText -fill both -expand 1 -side left

    pack $resultFrm -fill x -expand 0 -padx $pad -pady $pad
    pack $statusLbl -anchor w  -expand 1 -padx $pad -pady $pad

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    $mainWin   configure -cursor "watch"
    $doneBut   configure -cursor "top_left_arrow"
    $resultText configure -cursor "watch"

    update

    if {[catch {
	set msg [install::installServer $installImageRoot $serverDestDir \
		$serverLogDir $serverUID $serverGID $serverPort]
    } msg]} {
	# install failed
	# leave the next button disabled
	$gui::doneBut configure -state normal
	set outMsg $msg
	$statusLbl configure -text $::INSTALL_SERVER_GUI_FAILED
    } else {
	# install successful
	$gui::nextBut configure -state normal
	$gui::doneBut configure -state normal
	set outMsg $msg
	$statusLbl configure -text $::INSTALL_SERVER_GUI_SUCCESSFUL
    }

    $resultText insert 0.0 $outMsg

    $mainWin   configure -cursor {}
    $doneBut   configure -cursor {}
    $resultText configure -cursor {}
    
    return
}

# gui::ViewServerFinish --
#
#	Show the Server Finish Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerFinish {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar
    variable serverDestDir
    variable serverPort

    set pad   6
    set pad2 12

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_COMPLETE \
	    -font $gui::titleFont]

    # use a text widget for the msgLbl, so the text can be selected
    # and copied to the clipboard
    set msgLbl [text $mainFrm.msg -wrap word \
	    -relief flat -takefocus 0 ]
    $msgLbl insert 0.0 [format $::INSTALL_SERVER_GUI_DONE [info hostname] \
	    $serverPort [file join [file nativename $serverDestDir] \
	    $::SERVER_EXE]]
    $msgLbl configure -state disabled

    pack $titleLbl  -anchor w -padx $pad -pady $pad
    pack $msgLbl    -anchor w -padx $pad -fill both -expand 1

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::MENU_BUT
    set doneVar $::FINISH_BUT

    if {![install::hasAcrobat $::installImageRoot $::tclproPlatform] \
	    && ![install::hasServer $::installImageRoot $::tclproPlatform]} {
	set nextVar $::NEXT_BUT
	$gui::nextBut configure -state disabled
	$gui::doneBut configure -state active
	focus $gui::doneBut
    }

    return
}

# gui::ViewServerLaunch -- 
#
#	Show the Server Launch window
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewServerLaunch {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 12

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_LAUNCH_SERVER \
	    -font $gui::titleFont]
    set msgLbl [label $mainFrm.msg -justify left \
	    -text $::SERVER_GUI_LAUNCH \
	    -wraplength $gui::msgWidth]
    set yesRad [radiobutton $mainFrm.yesRad -text $::YES_BUT -value 1 \
	    -variable gui::launchServer]
    set noRad  [radiobutton $mainFrm.noRad -text $::NO_BUT -value 0 \
	    -variable gui::launchServer]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $yesRad   -anchor w -padx $pad2
    pack $noRad    -anchor w -padx $pad2

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}


# gui::LaunchServer --
#
#	Launch the license server if the option is set
#
# Arguments:
#	None.
#
# Results:
#	None

proc gui::LaunchServer {} {
    variable serverDestDir
    variable mainWin

    if {$gui::launchServer} {
	if {[catch {
	    exec [file join $serverDestDir $::SERVER_EXE] &
	} msg ]} {
	    tk_messageBox -icon error -parent $mainWin -title $::TCLPRO_TITLE \
		    -type ok -message $msg
	    return 0
	}
	return 1
    }
    return 1
}

# gui::ViewAcrobatLicense --
#
#	Show the License Window for the Acrobat branch.  This routine simply
#	calls the ViewLicense, but is needed to maintain the correct window
#	flow order.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewAcrobatLicense {} {
    gui::ViewLicense $::ACROBAT_LICENSE_GUI_TERMS \
	    $::ACROBAT_LICENSE_TXT_NOLNBRK
    return
}

# gui::ViewAcrobatDestination --
#
#	Show the Acrobat Destination Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewAcrobatDestination {} {
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6

    # Create the title, message, and directory entry.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_DESTDIR \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text $::DEST_DIR_ACROBAT_GUI_CHOOSE \
	    -wraplength $gui::msgWidth]
    set dirEnt   [entry $mainFrm.dirEnt -textvariable gui::acrobatDestDir]
    bind $dirEnt <Return> {$gui::nextBut invoke}

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad
    pack $dirEnt   -fill x -padx [expr {$pad*2}] -pady $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::MakeAcrobatDestDir --
#
#	Verify and create the install directory.
#
# Arguments:
#	nextPane	The next pane to view after this is done.
#
# Results:
#	Return a boolean, 1 indicates that the directory was made,
#	0 indicated the directory could not be made.

proc gui::MakeAcrobatDestDir {} {
    variable mainWin
    variable acrobatDestDir

    # Disallow relative paths

    if {[file pathtype $acrobatDestDir] == "relative"} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TITLE_ACROBAT -type ok \
		-message [format $::DEST_DIR_ENTER_REL_PATH $acrobatDestDir]]
	return 0
    }

    # If the dir doesn't exist, ask the user if they want to create it.

    if {![file exists $acrobatDestDir]} {
	set button [tk_messageBox -default yes -icon question \
		-parent $mainWin -title $::TITLE_ACROBAT -type yesno \
		-message $::DEST_DIR_GUI_NOTEXIST]
	if {$button == "no"} {
	    return 0
	}
    }
    
    # Create the destination directory and any parent directories as needed.

    if {[catch {file mkdir $acrobatDestDir} msg]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TITLE_ACROBAT -type ok \
		-message $msg]
	return 0
    }

    # Test to see if the directory is writable.

    if {![file writable $acrobatDestDir]} {
	set button [tk_messageBox -icon error \
		-parent $mainWin -title $::TITLE_ACROBAT -type ok \
		-message $::DEST_DIR_NO_WRITE_PERMISSION]
	return 0
    }

    # After all that, everything is OK.

    return 1
}


# gui::ViewAcrobatReady --
#
#	Show the Acrobat Ready Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewAcrobatReady {} {
    variable acrobatDestDir
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad 6

    # Create the title and message widgets.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_READY \
	    -font $gui::titleFont]
    set msgLbl   [label $mainFrm.msg -justify left \
	    -text [format $::INSTALL_ACROBAT_GUI_READY $acrobatDestDir $::ACROBAT ] \
	    -wraplength $gui::msgWidth]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    return
}

# gui::ViewAcrobatInstall --
#
#	Checks to see if we need to install acrobat, then does so.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewAcrobatInstall {} {
    global tclproPlatform installImageRoot
    variable acrobatDestDir
    variable mainWin
    variable total
    variable mainWin
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar
    variable counter 0
    variable statusSlider
    variable total
    set result 1
    
    # Ensure that expect is loaded so we can use it to wrap the Acrobat
    # installer. 
    package require Expect

    set pad 6

    # Create the title, message, and directory entry.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_INSTALLING \
	    -font $gui::titleFont]

    set scaleFrm [frame $mainFrm.scaleFrm]
    set statusBar [frame $scaleFrm.statusBar -relief sunken -bd 2]
    set statusSlider [frame $statusBar.statusSlider -relief raised -bd 2 \
	    -bg blue]
    set statusEnt [entry $scaleFrm.entry -textvariable gui::statusVar \
	    -relief flat -bg [$mainFrm cget -bg] -bd 0 -justify left]

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $scaleFrm -fill both -expand 1 -padx $pad -pady $pad
    update idletasks

    grid $statusEnt -row 0 -column 1 -sticky we -columnspan 2 -pady $pad
    grid $statusBar   -row 1 -column 1 -sticky nswe
    grid rowconfigure $scaleFrm 1 -minsize 24
    grid columnconfigure $scaleFrm 0 -weight 1
    grid columnconfigure $scaleFrm 1 -weight 4
    grid columnconfigure $scaleFrm 2 -weight 1

    place $statusSlider -x 0 -y 0 -height 19

    $gui::nextBut configure -state disabled
    $gui::backBut configure -state disabled
    $gui::doneBut configure -state disabled
    update idletasks
    
    # launch the expect script here.
    
    set targetDir $acrobatDestDir
    # get the name of the install script
    
    set total 5
    gui::ProgressLog ":Uncompressing Acrobat Installer"
    update
    
    set install::acrobatTmpDir ""
    set install::acrobatOldDir ""

    catch {setup::openLogFile $gui::acrobatDestDir}
    if {[catch {
	log_user 0
        set installer [install::getAcrobatInstaller $installImageRoot \
		$tclproPlatform]

        # spawn the installer
	gui::ProgressLog ":Launching Acrobat Installer"
        set pid [exp_spawn -noecho $installer]

        # skip the license
        expect {
            -gl "--More--" {exp_send "q\r"}
	    "LICREAD.TXT" {exp_send "q\r"}
            timeout {error "error: Timed out waiting for license text."}
        }

        # accept the license
        expect {
            "accept the terms" {exp_send "accept\r"}
            timeout {error "error: Timed out at accept/decline"}
        }

        # tell program where to install AR
        expect {
            "Enter installation directory" {exp_send "${acrobatDestDir}\r"}
            timeout {error "error: Timed out at entering directory"}
        }
    
	gui::ProgressLog ":Installing $::ACROBAT Files"

        # give installer plenty of time to copy the files
        set timeout 600
        expect {
	    "Cannot write to directory" {
		# the directory is not writable
		exec kill $pid
		error "error: Write permission denied for ${acrobatDestDir}"
	    }
	    "Do you want to create it now" {
		# the directory should exist already, it was created by 
		# a previous panel
		exec kill $pid
		error "fatal error: Directory ${acrobatDestDir} does not exist"
	    }
	    "Cannot make directory" {
		# the directory should exist already, it was created by 
		# a previous panel
		exec kill $pid
		error "fatal error: Directory ${acrobatDestDir} does not exist"
	    }
	    eof {
		set timeout 10
            }
            timeout {
                error "error: Timed out: file copying taking too long"
            }
        }
        set timeout 10
    } msg]} {
	tk_messageBox -default ok -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
	        -message $msg

	if {$install::acrobatOldDir != ""} {
	    cd $install::acrobatOldDir
	    set install::acrobatOldDir ""
	}
	if {$install::acrobatTmpDir != ""} {
	    if {[file exists $install::acrobatTmpDir]} {
		file delete -force $install::acrobatTmpDir
	    }
	}

	catch {setup::writeLogFile "\n$msg\n"}
	catch {setup::closeLogFile}

	exit
    }

    if {[catch {
	catch {gui::ProgressLog ":Removing Temporary Files"}

	if {$install::acrobatOldDir != ""} {
	    cd $install::acrobatOldDir
	    set install::acrobatOldDir ""
	}
	if {$install::acrobatTmpDir != ""} {
	    if {[file exists $install::acrobatTmpDir]} {
		file delete -force $install::acrobatTmpDir
	    }
	}
    } msg]} {
	tk_messageBox -default ok -icon error \
		-parent $mainWin -title $::SERVER_TITLE -type ok \
	        -message $msg

	catch {setup::writeLogFile "\n$msg\n"}
    }
	
    gui::ProgressLog ":Done"

    catch {setup::writeLogFile "\nInstallation Complete\n"}
    catch {set::closeLogFile}
	
    $mainWin   configure -cursor {}
    $statusEnt configure -cursor {}
    $gui::doneBut   configure -cursor {}

    set backVar $::BACK_BUT
    set nextVar $::NEXT_BUT
    set doneVar $::DONE_BUT

    $gui::nextBut configure -state normal;
    focus $gui::doneBut
    $gui::nextBut invoke
    return $result
}



# gui::ViewAcrobatFinish --
#
#	Show the Acrobat Finish Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewAcrobatFinish {} {
    variable mainFrm
    variable acrobatDestDir
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6
    set pad2 12

    # Create the title, message, and radiobuttons inquiring if 
    # the license key should be installed.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_COMPLETE \
	    -font $gui::titleFont]
    regsub "%PATH%" $::INSTALL_ACROBAT_GUI_DONE \
	    [file join [file nativename $acrobatDestDir] bin] doneMsg

    set msgLbl [text $mainFrm.msg -wrap word \
	    -relief flat -takefocus 0 ]
    $msgLbl insert 0.0 $doneMsg
    $msgLbl configure -state disabled

    pack $titleLbl -anchor w -padx $pad -pady $pad
    pack $msgLbl   -anchor w -padx $pad -fill both -expand 1

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::MENU_BUT
    set doneVar $::FINISH_BUT

    if {![install::hasAcrobat $::installImageRoot $::tclproPlatform] \
	    && ![install::hasServer $::installImageRoot $::tclproPlatform]} {
	set nextVar $::NEXT_BUT
	$gui::nextBut configure -state disabled
	$gui::doneBut configure -state active
	focus $gui::doneBut
    }

    return
}

# gui::ViewLicense --
#
#	Show the Generic License Window.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc gui::ViewLicense {licenseGuiTerms licenseFileName} {
    variable mainWin
    variable mainFrm
    variable backVar
    variable nextVar
    variable doneVar

    set pad   6

    # Create the title and text widget that contains the license.txt file.

    set titleLbl [label $mainFrm.titleLbl -text $::TITLE_LICENSE \
	    -font $gui::titleFont]
    set readFrm  [frame $mainFrm.readFrm]
    set readText [text  $readFrm.readText -width 1 -height 10 \
	    -wrap word -takefocus 0 \
	    -yscroll [list $readFrm.vsb set]]
    set vsb [scrollbar $readFrm.vsb -command [list $readText yview]]
    set agreeText [label $readFrm.agreeTxt -text $licenseGuiTerms \
	    -wraplength $gui::msgWidth -justify left]

    grid $readText  -row 0 -column 0 -sticky nswe
    grid $vsb       -row 0 -column 1 -sticky ns
    grid $agreeText -row 1 -column 0 -sticky nswe -columnspan 2 -pady $pad
    grid columnconfigure $readFrm 0 -weight 1
    grid rowconfigure $readFrm 0 -weight 1
    pack $readFrm  -fill both -expand 1 -padx $pad -pady $pad

    # Insert the LICENSE file into the text widget.
    
    set file [open $licenseFileName]
    set data [read $file]
    $readText insert end $data
    bindtags $readText [list $readText $mainWin all]

    # Change the names of the main buttons.

    set backVar $::BACK_BUT
    set nextVar $::IAGREE_BUT
    set doneVar $::QUIT_BUT

    update

    after 250 {
	$gui::nextBut configure -state active;
    }

    return
}

# gui::GetNewWindowIndex --
#
#	Get the index of the new window.
#
# Arguments:
#	index		The index of the window.
#
# Results:
#	The index of the next window in the flow to display.

proc gui::GetWindowIndex {win} {
    return [lsearch $gui::windowFlow $win]
}

# gui::GetNewWindowIndex --
#
#	Get the index of the new window to display based on the current 
#	window being displayed and the direction.
#
# Arguments:
#	index		The index of the current window.
#	direction	The direction to look (back or next.)
#
# Results:
#	The index of the next window in the flow to display.

proc gui::GetNewWindowIndex {index direction} {
    variable windowFlow

    if {$index < 0} {
	error "Error: \"$win\" is not a valid window name"
    }

    if {$direction == "back"} {
	incr index -1
    } elseif {$direction == "next"} {
	incr index 1
    } else {
	error "Error: \"$direction\" is not a valid direction"
    }

    if {($index < 0) || ($index == [llength $windowFlow])} {
	error "Error: you're off the end of the list silly!"
    }
    
    return $index
}

# gui::GetBackState --
#
#	Get the state of the back button for this window.
#
# Arguments:
#	index		The index of the current window.
#
# Results:
#	The state of the button (normal, active or disabled.)

proc gui::GetBackState {index} {
    return [lindex $gui::windowState([lindex $gui::windowFlow $index]) 0]
}

# gui::GetNextState --
#
#	Get the state of the next button for this window.
#
# Arguments:
#	index		The index of the current window.
#
# Results:
#	The state of the button (normal, active or disabled.)

proc gui::GetNextState {index} {
    return [lindex $gui::windowState([lindex $gui::windowFlow $index]) 1]
}

# gui::GetDoneState --
#
#	Get the state of the done button for this window.
#
# Arguments:
#	index		The index of the current window.
#
# Results:
#	The state of the button (normal, active or disabled.)

proc gui::GetDoneState {index} {
    return [lindex $gui::windowState([lindex $gui::windowFlow $index]) 2]
}

# gui::GetWindowChecker --
#
#	Get the command that determines if this window should be displayed.
#
# Arguments:
#	index		The index of the current window.
#
# Results:
#	Return the command to evaluate or empty string if there is no command.

proc gui::GetWindowChecker {index} {
    return [lindex $gui::windowState([lindex $gui::windowFlow $index]) 3]
}

# gui::GetNextCmd --
#
#	Get the command to execute when the next button is pressed.
#
# Arguments:
#	index		The index of the current window.
#
# Results:
#	Return the command to evaluate or empty string if there is no command.

proc gui::GetNextCmd {index} {
    return [lindex $gui::windowState([lindex $gui::windowFlow $index]) 4]
}

# gui::SetWindowTitle --
#
#	Callback to a trace variable that sets the title bar of the 
#	main window.
#
# Arguments:
#	name1	Standard trace arg.
#	name2	Standard trace arg.
#	op	Standard trace arg.
#
# Results:
#	None.

proc gui::SetWindowTitle {name1 name2 op} {
    wm title $gui::mainWin $gui::titleVar
    return
}

# gui::GetSelectedPlatforms --
#
#	Get the list of platforms that have been selected in the window.
#
# Arguments:
#	None.
#
# Results:
#	A list of selected platforms.

proc gui::GetSelectedPlatforms {} {
    set lop {}
    foreach {plat desc} [install::getPlatforms $::installImageRoot] {
	if {[set gui::install$plat]} {
	    lappend lop $plat
	}
    }
    return $lop
}

# gui::GetSelectedComponents --
#
#	Get the list of components that have been selected in the window.
#
# Arguments:
#	None.
#
# Results:
#	A list of selected components.

proc gui::GetSelectedComponents {} {
    set loc {}
    set lop [gui::GetSelectedPlatforms]
    foreach {comp desc} [install::getComponents $::installImageRoot $lop] {
	if {[set gui::install$comp]} {
	    lappend loc $comp
	}
    }
    return $loc
}

