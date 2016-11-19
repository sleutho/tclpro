# coreTk.tcl --
#
#	This file contains checks for Tk specific commands and types.
#
# Copyright (c) 1998-2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# SCCS: @(#) coreTk.tcl 1.44 98/08/26 15:39:57

package require analyzer 1.0
namespace import -force ::analyzer::*

package provide coreTk 1.0

namespace eval coreTk {
    
    # The following lists contain checkers that apply for the specified
    # version of Tk.  Later versions are assumed to include previous versions,
    # with the understanding that later values override earlier values.

    variable checkers3.6 {
	bell		{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	bind		{checkSimpleArgs 1  3 {coreTk::checkTag \
		{coreTk::checkSequence 0} checkWord}}
	bindtags	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	button		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -image -padx -pady -relief
		-text -textvariable -variable -width
	    } {
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	canvas		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-background -bd -bg -bitmap -borderwidth -closeenough -confine
		-cursor -height -insertbackground -insertborderwidth
		-insertofftime -insertontime -insertwidth -relief -scrollregion
		-selectbackground -selectborderwidth -selectforeground
		-width -xscrollcommand -yscrollcommand
	    } {
		{-scrollincrement checkPixels}}}
	    }
	}
	checkbutton	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -offvalue -onvalue -padx -pady
		-relief -selectimage -text -textvariable -variable -width
	    } {
		{-selector checkColor}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	clipboard	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	destroy 	{checkSimpleArgs 0 -1 {checkWinName}}
	entry	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -bitmap -borderwidth -cursor
		-exportselection -fg -font -foreground -insertbackground 
		-insertborderwidth -insertofftime -insertontime -insertwidth 
		-relief -scrollcommand -selectbackground -selectborderwidth
		-selectforeground -textvariable -width
	    } {
		{-state {checkKeyword 1 {normal disabled}}}}}
	    }
	}
	event	{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	focus		{checkSimpleArgs 0 2 {{checkSwitches 0 {
	    		    -displayof -force -lastfor} {
			    checkSimpleArgs 1 1 checkWinName}}}
	}
	font	{::analyzer::warn warnReserved "Tk 8.0" checkCommand}
	frame	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -cursor -height -relief
		-width
	    } {
		{-geometry {coreTk::checkGeometry}}}}
	    }
	}
	grab		{
	    checkOption {
		{current	{checkSimpleArgs 0 1 checkWinName}}
		{release	{checkSimpleArgs 1 1 checkWinName}}
		{set		{checkSwitches 0 {-global} {
		    checkSimpleArgs 1 1 checkWinName}}
		}
		{status		{checkSimpleArgs 1 1 checkWinName}}
	    } {checkSwitches 0 {-global} {
		checkSimpleArgs 1 1 checkWinName}
	    }
	}
	grid	{::analyzer::warn warnReserved "Tk 4.1" checkCommand}
	image	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	label	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-anchor -background -bd -bg -bitmap -borderwidth -cursor -fg
		-font -foreground -height -padx -pady -relief -text
		-textvariable -width
	    } {}}}
	}
	listbox	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -cursor -exportselection -fg
		-font -foreground -relief -selectbackground -selectborderwidth
		-selectforeground -setgrid -xscrollcommand -yscrollcommand
	    } {
		{-geometry {coreTk::checkGeometry}}}}
	    }
	}
	lower		{checkSimpleArgs 1  2 {checkWinName}}
	menu		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background  -bd -bg 
		-borderwidth -cursor -disabledforeground -fg -font -foreground
	    } {
		{-activeborderwidth {checkPixels}}
		{-postcommand {checkCommand}}
	    }}}
	}
    	menubutton	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background  -bd
		-bg -bitmap -borderwidth -cursor -disabledforeground -fg
		-font -foreground -height  -highlightbackground -highlightcolor
		-highlightthickness -image -justify -padx -pady -relief
		-takefocus -text -textvariable -underline -width -wraplength
	    } {
		{-direction {checkKeyword 1 {above below left right flush}}}
		{-indicatoron {checkBoolean}}
		{-menu {checkWinName}}
		{-state {checkKeyword 1 {normal active disabled}}}
	    }}}
	}
	message		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-anchor -background -bd -bg -borderwidth -cursor -fg
		-font -foreground -highlightbackground -highlightcolor
		-highlightthickness -justify -padx -pady -relief 
		-takefocus -text -textvariable -width
	    } {
		{-aspect {checkWholeNum}}
	    }}}
	}
	option		{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	pack		{checkOption {
	    {append	{::analyzer::warn warnDeprecated \
		    "-before or -after configure option" \
		    {checkSimpleArgs 1 -1 {checkWord}}}}
	    {configure 	{coreTk::checkWinThenOptions {
		    {-after 	{checkWinName}}
		    {-anchor 	{checkKeyword 0 {n ne e se s sw w nw center}}}
		    {-before 	{checkWinName}}
		    {-expand 	{checkBoolean}}
		    {-fill 	{checkKeyword 0 {none x y both}}}
		    {-in 	{checkWinName}}
		    {-ipadx 	{checkPixels}}
		    {-ipady 	{checkPixels}}
		    {-padx 	{checkPixels}}
		    {-pady 	{checkPixels}}
		    {-side 	{checkKeyword 0 {left right top bottom}}}
	        }}
	    }
	    {forget 	{checkSimpleArgs 1 -1 {checkWinName}}}
	    {newinfo 	{checkSimpleArgs 1  1 {checkWinName}}}
	    {propagate 	{checkSimpleArgs 1  2 {checkWinName 
	    			checkBoolean}}}
	    {slaves 	{checkSimpleArgs 1  1 {checkWinName}}}
	} {coreTk::checkWinThenOptions {
	    {-after 	{checkWinName}}
	    {-anchor 	{checkKeyword 0 {n ne e se s sw w nw center}}}
	    {-before 	{checkWinName}}
	    {-expand 	{checkBoolean}}
	    {-fill 	{checkKeyword 0 {none x y both}}}
	    {-in 	{checkWinName}}
	    {-ipadx 	{checkPixels}}
	    {-ipady 	{checkPixels}}
	    {-padx 	{checkPixels}}
	    {-pady 	{checkPixels}}
	    {-side 	{checkKeyword 0 {left right top bottom}}}
	}}}
	place		{checkOption {
		{configure {checkSimpleArgs 1 -1 {
		    checkWinName
		    {checkConfigure 0 {
			{-in checkWinName}
			{-x checkPixels}
			{-relx checkPixels}
			{-y checkPixels}
			{-rely checkPixels}
			{-anchor {checkKeyword 1 {n ne e se s sw w nw center}}}
			{-width checkPixels}
			{-relwidth checkFloat}
			{-height checkPixels}
			{-relheight checkFloat}
			{-bordermode {checkKeyword 0 {inside outside ignore}}}}}
			}
		    }
		}
		{forget {checkSimpleArgs 1 1 checkWinName}}
		{info {checkSimpleArgs 1 1 checkWinName}}
		{slaves {checkSimpleArgs 1 1 checkWinName}}
	    } {coreTk::checkWinThenOptions {
		{-in checkWinName}
		{-x checkPixels}
		{-relx checkPixels}
		{-y checkPixels}
		{-rely checkPixels}
		{-anchor {checkKeyword 1 {n ne e se s sw w nw center}}}
		{-width checkPixels}
		{-relwidth checkFloat}
		{-height checkPixels}
		{-relheight checkFloat}
		{-bordermode {checkKeyword 0 {inside outside ignore}}}
		}
	    }
	}
	radiobutton	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -padx -pady -relief -text
		-textvariable -value -variable -width
	    } {
		{-selector checkColor}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	raise		{checkSimpleArgs 1  2 {checkWinName}}
	scale		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background -bd -bg
		-borderwidth -command -cursor -fg -font -foreground -from
		-label -length -orient -relief -showvalue -sliderlength
		-tickinterval -to -width
	    } {
		{-command {checkProcCall 1}}
		{-sliderforeground checkColor}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	scrollbar	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -bd -bg -borderwidth -command -cursor -orient
		-relief -repeatdelay -repeatinterval -width
	    } {
		{-background {::analyzer::warn upgrade "-troughcolor" \
			checkColor}}
		{-foreground {::analyzer::warn upgrade "-background" \
			checkColor}}
		{-activeforeground {::analyzer::warn upgrade "-activebackground" \
			checkColor}}}}
	    }
	}
	selection	{
	    checkOption {
		{clear {checkSwitches 0 {
		    {-displayof checkWinName}
		    {-selection checkWord}
		} {checkSimpleArgs 0  1 {{
		    warn warnDeprecated "-displayof" checkWinName}}}}
		}
		{get {checkSwitches 0 {
		    {-displayof checkWinName}
		    {-selection checkWord}
		    {-type checkWord}
		} {checkSimpleArgs 0  1 {{
		    warn warnDeprecated "-type" checkWord}}}}
		}
		{handle {checkSwitches 0 {
		    {-selection checkWord}
		    {-type checkWord}
		    {-format checkWord}} {
			checkSimpleArgs 2 2 {checkWinName checkWord}}
		    }
		}
		{own {checkNumArgs {
		    {0 {checkSimpleArgs 0 0 {}}}
		    {1 {checkWinName}}
		    {2 {checkSwitches 0 {
			{-displayof checkWinName}
			{-selection checkWord}} {}}
		    }
		    {3  {checkSwitches 0 {
			{-command checkBody}
			{-selection checkWord}} {
			    checkWinName}
			}
		    }
		    {4 {checkSwitches 0 {
			{-displayof checkWinName}
			{-selection checkWord}} {}}
		    }
		    {5  {checkSwitches 0 {
			{-command checkBody}
			{-selection checkWord}} {
			    checkWinName}}}
			}
		    }
		}
	    } {}
	}
	send		{
	    checkSwitches 1 {
		-async
		{-displayof checkWinName}
		--
	    } {checkSimpleArgs 2 -1 {
		checkWord checkEvalArgs}
	    }
	}
	text {checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -cursor -exportselection -fg
		-font -foreground -height -insertbackground -insertborderwidth
		-insertofftime -insertontime -insertwidth -padx -pady -relief
		-selectbackground -selectborderwidth -selectforeground -setgrid
		-width -wrap -yscrollcommand
	    } {
		{-state {checkKeyword 1 {normal disabled}}}}}
	    }
	}
	tk		{checkOption {
	    {colormodel	{checkSimpleArgs 1 2 {
		checkWinName {checkKeyword 0 {color monochrome}}}}}
	    } {}
	}
	tk_bindForTraversal	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_bisque	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_chooseColor	{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	tk_dialog	{checkSimpleArgs 6 -1 {
	    checkWinName checkWord checkWord coreTk::checkBitmap
	    {coreTk::checkNullOrType checkInt} checkWord}
	}
	tk_focusFollowsMouse	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_focusNext	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_focusPrev	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_getOpenFile	{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	tk_getSaveFile	{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	tk_menuBar	{checkSimpleArgs 1 -1 {checkWinName}}
	tk_messageBox	{::analyzer::warn warnReserved "Tk 4.2" checkCommand}
	tk_optionMenu	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_setPalette	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tk_popup	{::analyzer::warn warnReserved "Tk 4.0" checkCommand}
	tkerror		{checkSimpleArgs 1  1 {checkWord}}
	tkwait		{checkOption {
	    {variable	{checkSimpleArgs 1 1 checkVarName}}
	    {visibility	{checkSimpleArgs 1 1 checkWinName}}
	    {window	{checkSimpleArgs 1 1 checkWinName}}
	} {}}
	toplevel {checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -cursor -height -relief
		-screen -width
	    } {
		{-geometry {coreTk::checkGeometry}}}}
	    }
	}
        winfo		{checkOption {
	    {atom		{checkSimpleArgs 1 1 {checkWinName}}}
	    {atomname		{checkSimpleArgs 1 1 {checkInt}}}
	    {cells		{checkSimpleArgs 1 1 {checkWinName}}}
	    {children		{checkSimpleArgs 1 1 {checkWinName}}}
	    {class		{checkSimpleArgs 1 1 {checkWinName}}}
	    {containing		{checkSimpleArgs 2 2 {checkPixels}}}
	    {depth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {exists		{checkSimpleArgs 1 1 {checkWinName}}}
	    {fpixels		{checkSimpleArgs 2 2 {
		checkWinName checkPixels}}
	    }
	    {geometry		{checkSimpleArgs 1 1 {checkWinName}}}
	    {height		{checkSimpleArgs 1 1 {checkWinName}}}
	    {id			{checkSimpleArgs 1 1 {checkWinName}}}
	    {interps		{checkSimpleArgs 0 0 {}}}
	    {ismapped		{checkSimpleArgs 1 1 {checkWinName}}}
	    {manager		{checkSimpleArgs 1 1 {checkWinName}}}
	    {name		{checkSimpleArgs 1 1 {checkWinName}}}
	    {parent		{checkSimpleArgs 1 1 {checkWinName}}}
	    {pathname		{checkSimpleArgs 1 1 {checkInt}}}
	    {pixels		{checkSimpleArgs 2 2 {
		checkWinName checkPixels}}
	    }
	    {reqheight		{checkSimpleArgs 1 1 {checkWinName}}}
	    {reqwidth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {rgb			{checkSimpleArgs 2 2 {
		checkWinName checkColor}}
	    }
	    {rootx		{checkSimpleArgs 1 1 {checkWinName}}}
	    {rooty		{checkSimpleArgs 1 1 {checkWinName}}}
	    {screen		{checkSimpleArgs 1 1 {checkWinName}}}
	    {screencell		{checkSimpleArgs 1 1 {checkWinName}}}
	    {screendepth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenmmheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenmmwidth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenvisual	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenwidth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {toplevel		{checkSimpleArgs 1 1 {checkWinName}}}
	    {viewable		{checkSimpleArgs 1 1 {checkWinName}}}
	    {visual		{checkSimpleArgs 1 1 {checkWinName}}}
	    {visualid		{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrootheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrootwidth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrootx		{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrooty		{checkSimpleArgs 1 1 {checkWinName}}}
	    {width		{checkSimpleArgs 1 1 {checkWinName}}}
	    {x			{checkSimpleArgs 1 1 {checkWinName}}}
	    {y			{checkSimpleArgs 1 1 {checkWinName}}}
	} {}}
    }

    # The following list contains the common options for all versions of the wm
    # command.  We'll add a few more in 4.0 but it's better to avoid
    # duplicating all of this in the 4.0 table.

    variable wmOptions {
	{aspect		{::analyzer::warn nonPortOption {} {checkNumArgs {
	    {1	checkWinName}
	    {5	{checkSimpleArgs 5 5 {
		checkWinName
		{checkListValues 0 1 checkInt}}}}}}
	    }
	}
	{client		{checkSimpleArgs 1 2 {
	    checkWinName checkWord}}
	}
	{command		{checkSimpleArgs 1 2 {
	    checkWinName checkWord}}
	}
	{deiconify	{checkSimpleArgs 1 1 {checkWinName}}}
	{focusmodel	{::analyzer::warn nonPortOption {} {checkSimpleArgs 1 2 {
	    checkWinName {checkKeyword 0 {passive active}}}}}
	}
	{frame		{checkSimpleArgs 1 1 {checkWinName}}}
	{geometry	{checkSimpleArgs 1 2 {
	    checkWinName coreTk::checkGeometry}}
	}
	{grid		{checkNumArgs {
	    {1	checkWinName}
	    {5	{checkSimpleArgs 5 5 {
		checkWinName
		{checkListValues 0 1 checkInt}}}}}
	    }
	}
	{group		{checkSimpleArgs 1 2 {
	    checkWinName
	    {checkListValues 0 1 checkWinName}}}
	}
	{iconbitmap	{::analyzer::warn nonPortOption {} {checkSimpleArgs 1 2 {
	    checkWinName coreTk::checkBitmap}}}
	}
	{iconify		{checkSimpleArgs 1 1 {checkWinName}}}
	{iconmask	{::analyzer::warn nonPortOption {} {checkSimpleArgs 1 2 {
	    checkWinName coreTk::checkBitmap}}}
	}
	{iconname	{::analyzer::warn nonPortOption {} {checkSimpleArgs 1 2 {
	    checkWinName checkWord}}}
	}
	{iconposition	{::analyzer::warn nonPortOption {} {checkNumArgs {
	    {1	checkWinName}
	    {3	{checkSimpleArgs 3 3 {
		checkWinName
		{checkListValues 0 1 checkInt}}}}}}
	    }
	}
	{iconwindow	{::analyzer::warn nonPortOption {} {checkSimpleArgs 1 2 {
	    checkWinName
	    {checkListValues 0 1 checkWinName}}}}
	}
	{maxsize		{checkNumArgs {
	    {1	checkWinName}
	    {3	{checkSimpleArgs 3 3 {
		checkWinName checkInt}}}}
	    }
	}
	{minsize		{checkNumArgs {
	    {1	checkWinName}
	    {3	{checkSimpleArgs 3 3 {
		checkWinName checkInt}}}}
	    }
	}
	{overrideredirect {checkSimpleArgs 1 2 {
	    checkWinName checkBoolean}}
	}
	{positionfrom	{checkSimpleArgs 1 2 {
	    checkWinName
	    {checkKeyword 0 {program user}}}}
	}
	{protocol	{checkSimpleArgs 1 3 {
	    checkWinName
	    coreTk::checkWmProtocol
	    checkBody}}
	}
	{sizefrom	{checkSimpleArgs 1 2 {
	    checkWinName
	    {checkKeyword 0 {"" program user}}}}
	}
	{state		{checkSimpleArgs 1 1 {checkWinName}}}
	{title		{checkSimpleArgs 1 2 {
	    checkWinName
	    checkWord}}
	}
	{transient	{checkSimpleArgs 1 2 {
	    checkWinName}}
	}
	{withdraw	{checkSimpleArgs 1 1 {checkWinName}}}
    }
    lappend checkers3.6 wm "checkOption {$wmOptions} {}"

    variable checkers4.0 {
	bell		{checkSimpleArgs 0 2 {
	    {checkSwitches 0 {{-displayof checkWinName}} {}}}
	}
	bindtags	{checkSimpleArgs 1  2 {
	    checkWinName {checkListValues 0 -1 coreTk::checkTag}}
	}
	button		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor
		-disabledforeground -fg -font -foreground -height
		-highlightbackground -highlightcolor -highlightthickness -image
		-justify -padx -pady -relief -takefocus -text -textvariable
		-underline -variable -width -wraplength
	    } {
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	canvas		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-background -bd -bg -bitmap -borderwidth -closeenough -confine
		-cursor -height -highlightbackground -highlightcolor
		-highlightthickness -insertbackground -insertborderwidth
		-insertofftime -insertontime -insertwidth -relief -scrollregion
		-selectbackground -selectborderwidth -selectforeground
		-takefocus -width -xscrollcommand -xscrollincrement
		-yscrollcommand -yscrollincrement
	    } {
		{-scrollincrement {::analyzer::warn warnUnsupported \
			"-xscrollincrement or -yscrollincrement" \
			checkPixels}}}}
	    }
	}
	checkbutton	{checkSimpleArgs 1 -1 {
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
		{-selector {::analyzer::warn warnUnsupported "-selectcolor" \
			checkColor}}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	clipboard	{checkOption {
	    {clear	    {checkSimpleArgs 0 2 {
				{checkSwitches 0 {
				    {-displayof checkWinName}
				} {}}}}
	    }
	    {append	    {checkSwitches 0 {
				{-displayof checkWinName}
				{-format checkWord}
				{-type checkWord}
				--
			    } {checkSimpleArgs 1 1 checkWord}}
	    }
	} {}}
	entry	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -bitmap -borderwidth -cursor 
		-exportselection -fg -font -foreground -highlightbackground 
		-highlightcolor -highlightthickness -insertbackground 
		-insertborderwidth -insertofftime -insertontime -insertwidth 
		-justify -relief -selectbackground -selectborderwidth 
		-selectforeground -show -takefocus -textvariable -width 
		-xscrollcommand
	    } {
		{-scrollcommand {::analyzer::warn warnUnsupported \
			"-xscrollcommand" {}}}
		{-state {checkKeyword 1 {normal disabled}}}}}
	    }
	}
	frame	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -colormap -cursor
		-height -highlightbackground -highlightcolor
		-highlightthickness -relief -takefocus -visual -width
	    } {
		{-geometry {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}}}}
	}
	image		{checkOption {
	    {create {checkOption {
		    {bitmap {coreTk::checkNameAndPairs {
			{-background checkColor}
			{-data checkWord}
			{-file checkFileName}
			{-foreground checkColor}
			{-maskdata checkWord}
			{-maskfile checkFileName}}}
		    }
		    {photo {coreTk::checkNameAndPairs {
			{-data checkWord}
			{-file checkFileName}
			{-format checkWord}
			{-gamma checkFloat}
			{-height checkInt}
			{-palette coreTk::checkPalette}
			{-width checkInt}}}
		    }
		} {checkSimpleArgs 1 -1 checkWord}}
	    }
	    {delete {checkSimpleArgs 0 -1 checkWord}}
	    {height {checkSimpleArgs 1 1 checkWord}}
	    {names {checkSimpleArgs 0 0 {}}}
	    {type {checkSimpleArgs 1 1 checkWord}}
	    {types {checkSimpleArgs 0 0 {}}}
	    {width {checkSimpleArgs 1 1 checkWord}}
	} {}}
	label	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-anchor -background -bd -bg -bitmap -borderwidth -cursor -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -image -justify -padx -pady -relief
		-takefocus -text -textvariable -underline -width -wraplength
	    } {}}}
	}
	listbox	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -cursor -exportselection -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -relief -selectbackground
		-selectborderwidth -selectforeground -selectmode -setgrid
		-takefocus -width -xscrollcommand -yscrollcommand
	    } {
		{-geometry {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}}}}
	}
	menu		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background  -bd -bg
		-borderwidth -cursor -disabledforeground -fg -font -foreground
		-relief -selectcolor -takefocus
	    } {
		{-activeborderwidth {checkPixels}}
		{-postcommand {checkCommand}}
		{-tearoff {checkBoolean}}
	    }}}
	}
	pack		{checkOption {
	    {append	{::analyzer::warn warnDeprecated \
		    "-before or -after configure option" \
		    {checkSimpleArgs 1 -1 {checkWord}}}}
	    {configure 	{coreTk::checkWinThenOptions {
		    {-after 	{checkWinName}}
		    {-anchor 	{checkKeyword 0 {n ne e se s sw w nw center}}}
		    {-before 	{checkWinName}}
		    {-expand 	{checkBoolean}}
		    {-fill 	{checkKeyword 0 {none x y both}}}
		    {-in 	{checkWinName}}
		    {-ipadx 	{checkPixels}}
		    {-ipady 	{checkPixels}}
		    {-padx 	{checkPixels}}
		    {-pady 	{checkPixels}}
		    {-side 	{checkKeyword 0 {left right top bottom}}}
		}}
	    }
	    {forget 	{checkSimpleArgs 1 -1 {checkWinName}}}
	    {info 	{checkSimpleArgs 1  1 {checkWinName}}}
	    {newinfo 	{::analyzer::warn warnUnsupported "info" \
		    {checkSimpleArgs 1  1 {checkWinName}}}}
	    {propagate 	{checkSimpleArgs 1  2 {checkWinName 
	    			checkBoolean}}}
	    {slaves 	{checkSimpleArgs 1  1 {checkWinName}}}
	} {coreTk::checkWinThenOptions {
	    {-after 	{checkWinName}}
	    {-anchor 	{checkKeyword 0 {n ne e se s sw w nw center}}}
	    {-before 	{checkWinName}}
	    {-expand 	{checkBoolean}}
	    {-fill 	{checkKeyword 0 {none x y both}}}
	    {-in 	{checkWinName}}
	    {-ipadx 	{checkPixels}}
	    {-ipady 	{checkPixels}}
	    {-padx 	{checkPixels}}
	    {-pady 	{checkPixels}}
	    {-side 	{checkKeyword 0 {left right top bottom}}}
	}}}
	radiobutton	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -disabledforeground -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -image -indicatoron -justify -padx -pady
		-relief -selectcolor -selectimage -takefocus -text
		-textvariable -underline -value -variable -width -wraplength
	    } {
		{-selector {::analyzer::warn warnUnsupported "-selectcolor" \
			checkColor}}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	scale		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background -bd -bg
		-bigincrement -borderwidth -command -cursor -digits -fg -font
		-foreground -from -highlightbackground -highlightcolor
		-highlightthickness -label -length -orient -relief -repeatdelay
		-repeatinterval -resolution -showvalue -sliderlength
		-sliderrelief -takefocus -tickinterval -to -troughcolor
		-variable -width
	    } {
		{-command {checkProcCall 1}}
		{-sliderforeground {::analyzer::warn warnUnsupported \
			"-background" checkColor}}
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	scrollbar	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activerelief -background
		-bd -bg -borderwidth -command -cursor -elementborderwidth
		-highlightbackground -highlightcolor -highlightthickness -jump
		-orient -relief -repeatdelay -repeatinterval -takefocus
		-troughcolor -width
	    } {
		{-activeforeground {::analyzer::warn warnUnsupported \
			"-activebackground" checkColor}}
		{-foreground {::analyzer::warn warnUnsupported \
			"-background" checkColor}}}}
	    }
	}
	text {checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -cursor -exportselection -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -insertbackground -insertborderwidth
		-insertofftime -insertontime -insertwidth -padx -pady -relief
		-selectbackground -selectborderwidth -selectforeground -setgrid
		-spacing1 -spacing2 -spacing3 -tabs -takefocus -width -wrap
		-xscrollcommand -yscrollcommand
	    } {
		{-state {checkKeyword 1 {normal disabled}}}}}
	    }
	}
	tk		{checkOption {
	    {appname	{checkSimpleArgs 0 1 checkWord}}
	} {}}
	tk_bindForTraversal {::analyzer::warn warnUnsupported menu {}}
	tk_bisque	{checkSimpleArgs 0  0 {}}
	tk_focusFollowsMouse	{checkSimpleArgs 0  0 {}}
	tk_focusNext	{checkSimpleArgs 1  1 {checkWinName}}
	tk_focusPrev	{checkSimpleArgs 1  1 {checkWinName}}
	tk_menuBar	{::analyzer::warn warnUnsupported menu {}}
	tk_optionMenu	{checkSimpleArgs 3 -1 {
	    checkWinName checkVarName checkWord}
	}
	tk_popup	{checkSimpleArgs 3  4 {
	    checkWinName checkInt checkInt checkWord}
	}
	tk_setPalette	{checkNumArgs {
	    {1	 	{checkSimpleArgs 1  1 {checkColor}}}
	    {-1 	{coreTk::checkSetPalette}}
	}}
	toplevel {checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -colormap -container
		-cursor -height -highlightbackground -highlightcolor
		-highlightthickness -menu -relief -screen -takefocus -use
		-visual -width
	    } {
		{-geometry {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}}}}
	}
	winfo		{checkOption {
	    {atom		{checkSwitches 0 {
		{-displayof checkWinName}} {
		    checkSimpleArgs 1 1 {checkWinName}}
		}
	    }
	    {atomname		{checkSwitches 0 {
		{-displayof checkWinName}} {
		    checkSimpleArgs 1 1 {checkInt}}
		}
	    }
	    {cells		{checkSimpleArgs 1 1 {checkWinName}}}
	    {children		{checkSimpleArgs 1 1 {checkWinName}}}
	    {class		{checkSimpleArgs 1 1 {checkWinName}}}
	    {colormapfull	{checkSimpleArgs 1 1 {checkWinName}}}
	    {containing		{checkSwitches 0 {
		{-displayof checkWinName}} {
		    checkSimpleArgs 2 2 {checkPixels}}
		}
	    }
	    {depth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {exists		{checkSimpleArgs 1 1 {checkWinName}}}
	    {fpixels		{checkSimpleArgs 2 2 {
		checkWinName checkPixels}}
	    }
	    {geometry		{checkSimpleArgs 1 1 {checkWinName}}}
	    {height		{checkSimpleArgs 1 1 {checkWinName}}}
	    {id			{checkSimpleArgs 1 1 {checkWinName}}}
	    {interps		{checkSimpleArgs 0 2 {{checkOption {
		{-displayof {checkWinName}}
	    } {}}}}}
	    {ismapped		{checkSimpleArgs 1 1 {checkWinName}}}
	    {manager		{checkSimpleArgs 1 1 {checkWinName}}}
	    {name		{checkSimpleArgs 1 1 {checkWinName}}}
	    {parent		{checkSimpleArgs 1 1 {checkWinName}}}
	    {pathname		{checkSwitches 0 {
		{-displayof checkWinName}
	    } {checkSimpleArgs 1 1 {checkInt}}}}
	    {pixels		{checkSimpleArgs 2 2 {
		checkWinName checkPixels}}
	    }
	    {pointerx		{checkSimpleArgs 1 1 {checkWinName}}}
	    {pointerxy		{checkSimpleArgs 1 1 {checkWinName}}}
	    {pointery		{checkSimpleArgs 1 1 {checkWinName}}}
	    {reqheight		{checkSimpleArgs 1 1 {checkWinName}}}
	    {reqwidth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {rgb		{checkSimpleArgs 2 2 {
		checkWinName checkColor}}
	    }
	    {rootx		{checkSimpleArgs 1 1 {checkWinName}}}
	    {rooty		{checkSimpleArgs 1 1 {checkWinName}}}
	    {screen		{checkSimpleArgs 1 1 {checkWinName}}}
	    {screencells	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screendepth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenmmheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenmmwidth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenvisual	{checkSimpleArgs 1 1 {checkWinName}}}
	    {screenwidth	{checkSimpleArgs 1 1 {checkWinName}}}
	    {server		{checkSimpleArgs 1 1 {checkWinName}}}
	    {toplevel		{checkSimpleArgs 1 1 {checkWinName}}}
	    {viewable		{checkSimpleArgs 1 1 {checkWinName}}}
	    {visual		{checkSimpleArgs 1 1 {checkWinName}}}
	    {visualid		{checkSimpleArgs 1 1 {checkWinName}}}
	    {visualsavailable	{checkSimpleArgs 1 2 {
		checkWinName {checkKeyword 1 {includeids}}}}
	    }
	    {vrootheight	{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrootwidth		{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrootx		{checkSimpleArgs 1 1 {checkWinName}}}
	    {vrooty		{checkSimpleArgs 1 1 {checkWinName}}}
	    {width		{checkSimpleArgs 1 1 {checkWinName}}}
	    {x			{checkSimpleArgs 1 1 {checkWinName}}}
	    {y			{checkSimpleArgs 1 1 {checkWinName}}}
	} {}}
    }
    lappend checkers4.0 wm "checkOption {
	$wmOptions
	{colormapwindows		{checkSimpleArgs 1 2 {
	    checkWinName
	    {checkListValues 0 -1 {checkWinName}}}}
	}
	{resizable		{checkNumArgs {
	    {1	checkWinName}
	    {3	{checkSimpleArgs 3 3 {
		checkWinName checkBoolean}}}}
	    }
	}
    } {}"

    variable checkers4.1 {
	grid			{checkOption {
	    {bbox		{checkNumArgs {
		{1 checkWinName}
		{3 {checkSimpleArgs 3 3 {checkWinName checkInt}}}
		{5 {checkSimpleArgs 5 5 {checkWinName checkInt}}}}}
	    }
	    {columnconfigure	{checkSimpleArgs 2 -1 {
		checkWinName
		{checkListValues 1 -1 checkInt}
		{checkConfigure 1 {
		    {-minsize checkInt}
		    {-weight checkInt}
		    {-pad checkInt}}}}
		}
	    }
	    {configure		coreTk::checkGridOptions}
	    {forget 		{checkSimpleArgs 1 -1 checkWinName}}
	    {info 		{checkSimpleArgs 1 1 checkWinName}}
	    {location 		{checkSimpleArgs 3 3 {
		checkWinName checkInt checkInt}}
	    }
	    {propagate 		{checkSimpleArgs 1 2 {
		checkWinName checkBoolean}}
	    }
	    {rowconfigure 	{checkSimpleArgs 2 -1 {
		checkWinName
		{checkListValues 1 -1 checkInt}
		{checkConfigure 1 {
		    {-minsize checkInt}
		    {-weight checkInt}
		    {-pad checkInt}}}}
		}
	    }
	    {remove 		{checkSimpleArgs 1 -1 checkWinName}}
	    {size 		{checkSimpleArgs 1 1 checkWinName}}
	    {slaves 		{checkSimpleArgs 1 3 {
		checkWinName
		{checkSwitches 0 {{-row checkInt} {-column checkInt}} {}}}}
	    }
	} {coreTk::checkGridOptions}}
	menu		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background  -bd -bg
		-borderwidth -cursor -disabledforeground -fg -font -foreground
		-relief -selectcolor -takefocus
	    } {
		{-activeborderwidth {checkPixels}}
		{-postcommand {checkCommand}}
		{-tearoff {checkBoolean}}
		{-tearoffcommand {checkBoolean}}
		{-transient {checkBoolean}}
	    }}}
	}
	tkerror		{::analyzer::warn warnDeprecated bgerror {
	    checkSimpleArgs 1  1 {checkWord}}
	}
    }

    variable checkers4.2 {
	event		{checkOption {
	    {add	{checkSimpleArgs 2 -1 {coreTk::checkVirtual
				{coreTk::checkSequence 1}}}}
	    {delete	{checkSimpleArgs 1 -1 {coreTk::checkVirtual
				{coreTk::checkSequence 1}}}}
	    {generate	{checkSimpleArgs 2 -1 {
		checkWinName
		coreTk::checkEvent
		{checkWidgetOptions 0 {-borderwidth -height -width} {
		    {-above checkWinName}
		    {-button checkWholeNum}
		    {-count checkInt}
		    {-detail {checkKeyword 1 {\
			    NotifyAncestor NotifyNonlinearVirtual \
			    NotifyDetailNone NotifyPointer \
			    NotifyInferior NotifyPointerRoot \
			    NotifyNonlinear NotifyVirtual \
			}   }   }
		    {-focus checkBoolean}
		    {-keycode checkInt}
		    {-keysym coreTk::checkKeysym}
		    {-mode {checkKeyword 1 {\
		     NotifyNormal NotifyGrab NotifyUngrab NotifyWhileGrabbed \
		    }   }   }
	            {-override checkBoolean}
		    {-place {checkKeyword 1 {\
			    PlaceOnTop PlaceOnBottom \
		    }   }   }
    		    {-root coreTk::checkRoot}
		    {-rootx checkPixels}
		    {-rooty checkPixels}
		    {-sendevent checkBoolean}
		    {-serial checkInt}
		    {-state coreTk::checkState}
		    {-subwindow  checkWinName}
		    {-time checkInt}
		    {-when {checkKeyword 1 {\
			    now tail head mark \
		    }   }   }
		    {-x checkPixels}
        	    {-y checkPixels}}}}}}
	    {info	{checkSimpleArgs 0 1 coreTk::checkVirtual}}
	} {}}
	option		{checkOption {
	    {add	{checkSimpleArgs 2  3 {checkWord checkWord
				coreTk::checkPriority}}}
	    {clear	{checkSimpleArgs 0  0 {}}}
	    {get	{checkSimpleArgs 3  3 {checkWinName
				checkWord}}}
	    {readfile	{checkSimpleArgs 1 2 {checkFileName 
				coreTk::checkPriority}}}
	} {}}
	menu		{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -background  -bd -bg
		-borderwidth -cursor -disabledforeground -fg -font -foreground
		-relief -selectcolor -takefocus
	    } {
		{-activeborderwidth {checkPixels}}
		{-postcommand {checkCommand}}
		{-tearoff {checkBoolean}}
		{-tearoffcommand {checkBoolean}}
		{-title {checkWord}}
		{-type {checkKeyword 1 {menubar tearoff normal}}}
	    }}}
	}
	tk_chooseColor	{checkSwitches 0 {
	    {-initialcolor checkColor}
	    {-parent checkWinName}
	    {-title checkWord}
	} {}}
	tk_getOpenFile		{checkSwitches 0 {
		{-defaultextension checkWord}
		{-filetypes     {checkListValues 1 -1 {
		    {checkListValues 2 3 {
			checkWord
			{checkListValues 1 -1 checkWord}}}}
		    }
		}
		{-initialdir checkFileName}
		{-initialfile checkFileName}
		{-parent checkWinName}
		{-title checkWord}
	    } {}
	}
	tk_getSaveFile		{checkSwitches 0 {
		{-defaultextension checkWord}
		{-filetypes {checkListValues 1 -1 {
		    {checkListValues 2 3 {
			checkWord
			{checkListValues 1 -1 checkWord}}}}
		    }
		}
		{-initialdir checkFileName}
		{-initialfile checkFileName}
		{-parent checkWinName}
		{-title checkWord}
	    } {}
	}
	tk_messageBox	coreTk::checkMessageBox
    }

    variable checkers8.0 {
	button		{checkSimpleArgs 1 -1 {
	    checkWinName
	    {checkWidgetOptions 0 {
		-activebackground -activeforeground -anchor -background -bd -bg
		-bitmap -borderwidth -command -cursor -default
		-disabledforeground -fg -font -foreground -height
		-highlightbackground -highlightcolor -highlightthickness -image
		-justify -padx -pady -relief -takefocus -text -textvariable
		-underline -variable -width -wraplength
	    } {
		{-state {checkKeyword 1 {normal active disabled}}}}}
	    }
	}
	font		{checkOption {
	    {actual	{checkSimpleArgs 1 -1 {checkWord {checkOption {
		{-displayof {checkSimpleArgs 1 2 {checkWinName {
		    checkKeyword 1 {-family -size -weight -slant \
			    -underline -overstrike}}}}}
		} {checkSimpleArgs 0 1 {{checkKeyword 1 {
		    -family -size -weight -slant -underline -overstrike}}}}}}
		}
	    }
	    {configure	{checkSimpleArgs 1 -1 {checkWord {checkConfigure 1 {
		{-family checkWord}
		{-size checkInt}
		{-weight {checkKeyword 1 {normal bold}}}
		{-slant {checkKeyword 1 {roman italic}}}
		{-underline checkBoolean}
		{-overstrike checkBoolean}}}}}
	    }
	    {create	coreTk::checkFontCreateCmd}
	    {delete	{checkSimpleArgs 1 -1 checkWord}}
	    {families	{checkSimpleArgs 0 2 {{checkConfigure 0 {
		{-displayof checkWinName}}}}}
	    }
	    {measure	{checkSimpleArgs 2 4 {
		checkWord
		{checkOption {
		    {-displayof {checkSimpleArgs 2 2 {
			checkWinName checkWord}}
		    }
		} {checkSimpleArgs 1 1 checkWord}}}}
	    }
	    {metrics	{checkSimpleArgs 1 -1 {
		checkWord
		{checkOption {
		    {-displayof {checkSimpleArgs 1 2 {
			checkWinName 
			{checkKeyword 1 {-ascent -descent -linespace -fixed}}}}
		    }
		} {checkSimpleArgs 1 1 {
		    {checkKeyword 1 {-ascent -descent -linespace -fixed}}}}}}
		}
	    }
	    {names	{checkSimpleArgs 0  0 {}}}
	} {}}
	frame	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -class -colormap -container
		-cursor -height -highlightbackground -highlightcolor
		-highlightthickness -relief -takefocus -visual -width
	    } {
		{-geometry {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}}}}
	}
	tk		{checkOption {
	    {appname	{checkSimpleArgs 0 1 checkWord}}
	    {scaling	{checkSimpleArgs 0 3 {{checkSwitches 0 {
		{-displayof checkWinName}} {checkSimpleArgs 0 1 checkFloat}}
	    }}}
	} {}}
	tkerror		{::analyzer::warn obsoleteCmd bgerror {
	    checkSimpleArgs 1  1 {checkWord}}
	}
    }

    variable checkers8.1 {
    }

    variable checkers8.2 {
    }

    variable checkers8.3 {
	entry	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -bitmap -borderwidth -cursor 
		-exportselection -fg -font -foreground -highlightbackground 
		-highlightcolor -highlightthickness -insertbackground 
		-insertborderwidth -insertofftime -insertontime -insertwidth 
		-justify -relief -selectbackground -selectborderwidth 
		-selectforeground -show -takefocus -textvariable -width 
		-xscrollcommand
	    } {
		{-invalidcommand checkBody}
		{-invcmd checkBody}
		{-scrollcommand {::analyzer::warn warnUnsupported \
			"-xscrollcommand" {}}}
		{-state {checkKeyword 1 {normal disabled}}}
		{-validatecommand checkBody}
		{-vcmd checkBody}
		{-validate {checkKeyword 1 \
			{none focus focusin focusout key all}}}
	    }}}}
	event		{checkOption {
	    {add	{checkSimpleArgs 2 -1 {coreTk::checkVirtual
				{coreTk::checkSequence 1}}}}
	    {delete	{checkSimpleArgs 1 -1 {coreTk::checkVirtual
				{coreTk::checkSequence 1}}}}
	    {generate	{checkSimpleArgs 2 -1 {
		checkWinName
		coreTk::checkEvent
		{checkWidgetOptions 0 {-borderwidth -height -width} {
		    {-above checkWinName}
		    {-button checkWholeNum}
		    {-count checkInt}
		    {-detail {checkKeyword 1 {\
			    NotifyAncestor NotifyNonlinearVirtual \
			    NotifyDetailNone NotifyPointer \
			    NotifyInferior NotifyPointerRoot \
			    NotifyNonlinear NotifyVirtual \
			}   }   }
		    {-focus checkBoolean}
		    {-keycode checkInt}
		    {-keysym coreTk::checkKeysym}
		    {-mode {checkKeyword 1 {\
		     NotifyNormal NotifyGrab NotifyUngrab NotifyWhileGrabbed \
		    }   }   }
	            {-override checkBoolean}
		    {-place {checkKeyword 1 {\
			    PlaceOnTop PlaceOnBottom \
		    }   }   }
    		    {-root coreTk::checkRoot}
		    {-rootx checkPixels}
		    {-rooty checkPixels}
		    {-sendevent checkBoolean}
		    {-serial checkInt}
		    {-state coreTk::checkState}
		    {-subwindow  checkWinName}
		    {-time checkInt}
		    {-warp checkBoolean}
		    {-when {checkKeyword 1 {\
			    now tail head mark \
		    }   }   }
		    {-x checkPixels}
        	    {-y checkPixels}}}}}}
	    {info	{checkSimpleArgs 0 1 coreTk::checkVirtual}}
	} {}}
	listbox	{checkSimpleArgs 1 -1 {
	    checkWinName 
	    {checkWidgetOptions 0 {
		-background -bd -bg -borderwidth -cursor -exportselection -fg
		-font -foreground -height -highlightbackground -highlightcolor
		-highlightthickness -relief -selectbackground
		-selectborderwidth -selectforeground -selectmode -setgrid
		-takefocus -width -xscrollcommand -yscrollcommand
	    } {
		{-geometry {::analyzer::warn warnUnsupported "-width or -height" \
			coreTk::checkGeometry}}
		{-listvar {checkVarName}}
	    }}}}
	tk_chooseDirectory	{checkSwitches 1 {
	    {-initialdir checkFileName} {-parent checkWinName} 
	    {-title checkWord} {-mustexist checkBoolean}
	} {}}
    }
    lappend checkers8.3 wm "checkOption {
        {state		        {checkSimpleArgs 1 2 {
            checkWinName {
	    checkKeyword 1 {normal iconic withdrawn icon zoomed}}}}
        }
	$wmOptions
	{colormapwindows	{checkSimpleArgs 1 2 {
	    checkWinName
	    {checkListValues 0 -1 {checkWinName}}}}
	}
	{resizable		{checkNumArgs {
	    {1	checkWinName}
	    {3	{checkSimpleArgs 3 3 {
		checkWinName checkBoolean}}}}
	    }
	}
    } {}"

    # The following array contains the union of all of the standard widget
    # options in all versions of Tk.

    variable tkWidgetOptions {
	-bitmap coreTk::checkBitmap
	-screen coreTk::checkScreen
	-tabs coreTk::checkTabs
	-use {coreTk::checkNullOrType checkFloat}
	-visual coreTk::checkVisual
    }

    # Define the set of message types and their human-readable translations. 

    array set messages {
	coreTk::badColormap	{"invalid colormap \"%1$s\": must be \"new\" or a window name" err}
	coreTk::badEvent	{"invalid event type or keysym" err}
	coreTk::badGeometry	{"invalid geometry specifier" err}
	coreTk::badGridRel	{"must specify window before shortcut" err}
	coreTk::badGridMaster	{"cannot determine master window" err}	
	coreTk::badPalette	{"invalid palette spec" err}
	coreTk::badPriority	{"invalid priority keyword or value" err}
	coreTk::badScreen	{"invalid screen value" err}
	coreTk::badSticky	{"invalid stickyness value: should be one or more of nswe" err}
	coreTk::badTab		{"invalid tab list" err}
	coreTk::badTabJust	{"invalid tab justification \"%1$s\": must be left right center or numeric" err} 
	coreTk::badVirtual	{"virtual event is badly formed" err}
	coreTk::badVisual	{"invalid visual" err}
	coreTk::badVisualDepth	{"invalid visual depth" err}
	coreTk::nonPortBitmap	{"use of non-portable bitmap" warn nonPortable}
	coreTk::nonPortKeysym	{"use of non-portable keysym" warn nonPortable}
	coreTk::noVirtual	{"virtual event not allowed in definition of another virtual event" err}
	coreTk::noEvent		{"no events specified in binding" err}
    }

    variable validKeysyms [list \
	"BackSpace" "Tab" "Linefeed" "Clear" "Return" "Pause" "Escape" "Delete" \
	"Multi_key" "Kanji" "Home" "Left" "Up" "Right" "Down" "Prior" "Next" \
	"End" "Begin" "Select" "Print" "Execute" "Insert" "Undo" "Redo" "Menu" \
	"Find" "Cancel" "Help" "Break" "Mode_switch" "script_switch" "Num_Lock" \
	"KP_Space" "KP_Tab" "KP_Enter" "KP_F1" "KP_F2" "KP_F3" "KP_F4" \
	"KP_Equal" "KP_Multiply" "KP_Add" "KP_Separator" "KP_Subtract" \
	"KP_Decimal" "KP_Divide" "KP_0" "KP_1" "KP_2" "KP_3" "KP_4" "KP_5" \
	"KP_6" "KP_7" "KP_8" "KP_9" "F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" \
	"F9" "F10" "F11" "L1" "F12" "L2" "F13" "L3" "F14" "L4" "F15" "L5" "F16" \
	"L6" "F17" "L7" "F18" "L8" "F19" "L9" "F20" "L10" "F21" "R1" "F22" "R2" \
	"F23" "R3" "F24" "R4" "F25" "R5" "F26" "R6" "F27" "R7" "F28" "R8" "F29" \
	"R9" "F30" "R10" "F31" "R11" "F32" "R12" "R13" "F33" "F34" "R14" "F35" \
	"R15" "Shift_L" "Shift_R" "Control_L" "Control_R" "Caps_Lock" \
	"Shift_Lock" "Meta_L" "Meta_R" "Alt_L" "Alt_R" "Super_L" "Super_R" \
	"Hyper_L" "Hyper_R" "space" "exclam" "quotedbl" "numbersign" "dollar" \
	"percent" "ampersand" "quoteright" "parenleft" "parenright" "asterisk" \
	"plus" "comma" "minus" "period" "slash" "0" "1" "2" "3" "4" "5" "6" "7" \
	"8" "9" "colon" "semicolon" "less" "equal" "greater" "question" "at" \
	"A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" \
	"S" "T" "U" "V" "W" "X" "Y" "Z" "bracketleft" "backslash" \
	"bracketright" "asciicircum" "underscore" "quoteleft" "a" "b" "c" "d" \
	"e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" \
	"w" "x" "y" "z" "braceleft" "bar" "braceright" "asciitilde" \
	"nobreakspace" "exclamdown" "cent" "sterling" "currency" "yen" \
	"brokenbar" "section" "diaeresis" "copyright" "ordfeminine" \
	"guillemotleft" "notsign" "hyphen" "registered" "macron" "degree" \
	"plusminus" "twosuperior" "threesuperior" "acute" "mu" "paragraph" \
	"periodcentered" "cedilla" "onesuperior" "masculine" "guillemotright" \
	"onequarter" "onehalf" "threequarters" "questiondown" "Agrave" "Aacute" \
	"Acircumflex" "Atilde" "Adiaeresis" "Aring" "AE" "Ccedilla" "Egrave" \
	"Eacute" "Ecircumflex" "Ediaeresis" "Igrave" "Iacute" "Icircumflex" \
	"Idiaeresis" "Eth" "Ntilde" "Ograve" "Oacute" "Ocircumflex" "Otilde" \
	"Odiaeresis" "multiply" "Ooblique" "Ugrave" "Uacute" "Ucircumflex" \
	"Udiaeresis" "Yacute" "Thorn" "ssharp" "agrave" "aacute" "acircumflex" \
	"atilde" "adiaeresis" "aring" "ae" "ccedilla" "egrave" "eacute" \
	"ecircumflex" "ediaeresis" "igrave" "iacute" "icircumflex" "idiaeresis" \
	"eth" "ntilde" "ograve" "oacute" "ocircumflex" "otilde" "odiaeresis" \
	"division" "oslash" "ugrave" "uacute" "ucircumflex" "udiaeresis" \
	"yacute" "thorn" "ydiaeresis" "Aogonek" "breve" "Lstroke" "Lcaron" \
	"Sacute" "Scaron" "Scedilla" "Tcaron" "Zacute" "Zcaron" "Zabovedot" \
	"aogonek" "ogonek" "lstroke" "lcaron" "sacute" "caron" "scaron" \
	"scedilla" "tcaron" "zacute" "doubleacute" "zcaron" "zabovedot" \
	"Racute" "Abreve" "Cacute" "Ccaron" "Eogonek" "Ecaron" "Dcaron" \
	"Nacute" "Ncaron" "Odoubleacute" "Rcaron" "Uring" "Udoubleacute" \
	"Tcedilla" "racute" "abreve" "cacute" "ccaron" "eogonek" "ecaron" \
	"dcaron" "nacute" "ncaron" "odoubleacute" "udoubleacute" "rcaron" \
	"uring" "tcedilla" "abovedot" "Hstroke" "Hcircumflex" "Iabovedot" \
	"Gbreve" "Jcircumflex" "hstroke" "hcircumflex" "idotless" "gbreve" \
	"jcircumflex" "Cabovedot" "Ccircumflex" "Gabovedot" "Gcircumflex" \
	"Ubreve" "Scircumflex" "cabovedot" "ccircumflex" "gabovedot" \
	"gcircumflex" "ubreve" "scircumflex" "kappa" "Rcedilla" "Itilde" \
	"Lcedilla" "Emacron" "Gcedilla" "Tslash" "rcedilla" "itilde" "lcedilla" \
	"emacron" "gacute" "tslash" "ENG" "eng" "Amacron" "Iogonek" "Eabovedot" \
	"Imacron" "Ncedilla" "Omacron" "Kcedilla" "Uogonek" "Utilde" "Umacron" \
	"amacron" "iogonek" "eabovedot" "imacron" "ncedilla" "omacron" \
	"kcedilla" "uogonek" "utilde" "umacron" "overline" "kana_fullstop" \
	"kana_openingbracket" "kana_closingbracket" "kana_comma" \
	"kana_middledot" "kana_WO" "kana_a" "kana_i" "kana_u" "kana_e" "kana_o" \
	"kana_ya" "kana_yu" "kana_yo" "kana_tu" "prolongedsound" "kana_A" \
	"kana_I" "kana_U" "kana_E" "kana_O" "kana_KA" "kana_KI" "kana_KU" \
	"kana_KE" "kana_KO" "kana_SA" "kana_SHI" "kana_SU" "kana_SE" "kana_SO" \
	"kana_TA" "kana_TI" "kana_TU" "kana_TE" "kana_TO" "kana_NA" "kana_NI" \
	"kana_NU" "kana_NE" "kana_NO" "kana_HA" "kana_HI" "kana_HU" "kana_HE" \
	"kana_HO" "kana_MA" "kana_MI" "kana_MU" "kana_ME" "kana_MO" "kana_YA" \
	"kana_YU" "kana_YO" "kana_RA" "kana_RI" "kana_RU" "kana_RE" "kana_RO" \
	"kana_WA" "kana_N" "voicedsound" "semivoicedsound" "kana_switch" \
	"Arabic_comma" "Arabic_semicolon" "Arabic_question_mark" "Arabic_hamza" \
	"Arabic_maddaonalef" "Arabic_hamzaonalef" "Arabic_hamzaonwaw" \
	"Arabic_hamzaunderalef" "Arabic_hamzaonyeh" "Arabic_alef" "Arabic_beh" \
	"Arabic_tehmarbuta" "Arabic_teh" "Arabic_theh" "Arabic_jeem" \
	"Arabic_hah" "Arabic_khah" "Arabic_dal" "Arabic_thal" "Arabic_ra" \
	"Arabic_zain" "Arabic_seen" "Arabic_sheen" "Arabic_sad" "Arabic_dad" \
	"Arabic_tah" "Arabic_zah" "Arabic_ain" "Arabic_ghain" "Arabic_tatweel" \
	"Arabic_feh" "Arabic_qaf" "Arabic_kaf" "Arabic_lam" "Arabic_meem" \
	"Arabic_noon" "Arabic_heh" "Arabic_waw" "Arabic_alefmaksura" \
	"Arabic_yeh" "Arabic_fathatan" "Arabic_dammatan" "Arabic_kasratan" \
	"Arabic_fatha" "Arabic_damma" "Arabic_kasra" "Arabic_shadda" \
	"Arabic_sukun" "Arabic_switch" "Serbian_dje" "Macedonia_gje" \
	"Cyrillic_io" "Ukranian_je" "Macedonia_dse" "Ukranian_i" "Ukranian_yi" \
	"Serbian_je" "Serbian_lje" "Serbian_nje" "Serbian_tshe" "Macedonia_kje" \
	"Byelorussian_shortu" "Serbian_dze" "numerosign" "Serbian_DJE" \
	"Macedonia_GJE" "Cyrillic_IO" "Ukranian_JE" "Macedonia_DSE" \
	"Ukranian_I" "Ukranian_YI" "Serbian_JE" "Serbian_LJE" "Serbian_NJE" \
	"Serbian_TSHE" "Macedonia_KJE" "Byelorussian_SHORTU" "Serbian_DZE" \
	"Cyrillic_yu" "Cyrillic_a" "Cyrillic_be" "Cyrillic_tse" "Cyrillic_de" \
	"Cyrillic_ie" "Cyrillic_ef" "Cyrillic_ghe" "Cyrillic_ha" "Cyrillic_i" \
	"Cyrillic_shorti" "Cyrillic_ka" "Cyrillic_el" "Cyrillic_em" \
	"Cyrillic_en" "Cyrillic_o" "Cyrillic_pe" "Cyrillic_ya" "Cyrillic_er" \
	"Cyrillic_es" "Cyrillic_te" "Cyrillic_u" "Cyrillic_zhe" "Cyrillic_ve" \
	"Cyrillic_softsign" "Cyrillic_yeru" "Cyrillic_ze" "Cyrillic_sha" \
	"Cyrillic_e" "Cyrillic_shcha" "Cyrillic_che" "Cyrillic_hardsign" \
	"Cyrillic_YU" "Cyrillic_A" "Cyrillic_BE" "Cyrillic_TSE" "Cyrillic_DE" \
	"Cyrillic_IE" "Cyrillic_EF" "Cyrillic_GHE" "Cyrillic_HA" "Cyrillic_I" \
	"Cyrillic_SHORTI" "Cyrillic_KA" "Cyrillic_EL" "Cyrillic_EM" \
	"Cyrillic_EN" "Cyrillic_O" "Cyrillic_PE" "Cyrillic_YA" "Cyrillic_ER" \
	"Cyrillic_ES" "Cyrillic_TE" "Cyrillic_U" "Cyrillic_ZHE" "Cyrillic_VE" \
	"Cyrillic_SOFTSIGN" "Cyrillic_YERU" "Cyrillic_ZE" "Cyrillic_SHA" \
	"Cyrillic_E" "Cyrillic_SHCHA" "Cyrillic_CHE" "Cyrillic_HARDSIGN" \
	"Greek_ALPHAaccent" "Greek_EPSILONaccent" "Greek_ETAaccent" \
	"Greek_IOTAaccent" "Greek_IOTAdiaeresis" "Greek_IOTAaccentdiaeresis" \
	"Greek_OMICRONaccent" "Greek_UPSILONaccent" "Greek_UPSILONdieresis" \
	"Greek_UPSILONaccentdieresis" "Greek_OMEGAaccent" "Greek_alphaaccent" \
	"Greek_epsilonaccent" "Greek_etaaccent" "Greek_iotaaccent" \
	"Greek_iotadieresis" "Greek_iotaaccentdieresis" "Greek_omicronaccent" \
	"Greek_upsilonaccent" "Greek_upsilondieresis" \
	"Greek_upsilonaccentdieresis" "Greek_omegaaccent" "Greek_ALPHA" \
	"Greek_BETA" "Greek_GAMMA" "Greek_DELTA" "Greek_EPSILON" "Greek_ZETA" \
	"Greek_ETA" "Greek_THETA" "Greek_IOTA" "Greek_KAPPA" "Greek_LAMBDA" \
	"Greek_MU" "Greek_NU" "Greek_XI" "Greek_OMICRON" "Greek_PI" "Greek_RHO" \
	"Greek_SIGMA" "Greek_TAU" "Greek_UPSILON" "Greek_PHI" "Greek_CHI" \
	"Greek_PSI" "Greek_OMEGA" "Greek_alpha" "Greek_beta" "Greek_gamma" \
	"Greek_delta" "Greek_epsilon" "Greek_zeta" "Greek_eta" "Greek_theta" \
	"Greek_iota" "Greek_kappa" "Greek_lambda" "Greek_mu" "Greek_nu" \
	"Greek_xi" "Greek_omicron" "Greek_pi" "Greek_rho" "Greek_sigma" \
	"Greek_finalsmallsigma" "Greek_tau" "Greek_upsilon" "Greek_phi" \
	"Greek_chi" "Greek_psi" "Greek_omega" "Greek_switch" "leftradical" \
	"topleftradical" "horizconnector" "topintegral" "botintegral" \
	"vertconnector" "topleftsqbracket" "botleftsqbracket" \
	"toprightsqbracket" "botrightsqbracket" "topleftparens" "botleftparens" \
	"toprightparens" "botrightparens" "leftmiddlecurlybrace" \
	"rightmiddlecurlybrace" "topleftsummation" "botleftsummation" \
	"topvertsummationconnector" "botvertsummationconnector" \
	"toprightsummation" "botrightsummation" "rightmiddlesummation" \
	"lessthanequal" "notequal" "greaterthanequal" "integral" "therefore" \
	"variation" "infinity" "nabla" "approximate" "similarequal" "ifonlyif" \
	"implies" "identical" "radical" "includedin" "includes" "intersection" \
	"union" "logicaland" "logicalor" "partialderivative" "function" \
	"leftarrow" "uparrow" "rightarrow" "downarrow" "blank" "soliddiamond" \
	"checkerboard" "ht" "ff" "cr" "lf" "nl" "vt" "lowrightcorner" \
	"uprightcorner" "upleftcorner" "lowleftcorner" "crossinglines" \
	"horizlinescan1" "horizlinescan3" "horizlinescan5" "horizlinescan7" \
	"horizlinescan9" "leftt" "rightt" "bott" "topt" "vertbar" "emspace" \
	"enspace" "em3space" "em4space" "digitspace" "punctspace" "thinspace" \
	"hairspace" "emdash" "endash" "signifblank" "ellipsis" \
	"doubbaselinedot" "onethird" "twothirds" "onefifth" "twofifths" \
	"threefifths" "fourfifths" "onesixth" "fivesixths" "careof" "figdash" \
	"leftanglebracket" "decimalpoint" "rightanglebracket" "marker" \
	"oneeighth" "threeeighths" "fiveeighths" "seveneighths" "trademark" \
	"signaturemark" "trademarkincircle" "leftopentriangle" \
	"rightopentriangle" "emopencircle" "emopenrectangle" \
	"leftsinglequotemark" "rightsinglequotemark" "leftdoublequotemark" \
	"rightdoublequotemark" "prescription" "minutes" "seconds" "latincross" \
	"hexagram" "filledrectbullet" "filledlefttribullet" \
	"filledrighttribullet" "emfilledcircle" "emfilledrect" \
	"enopencircbullet" "enopensquarebullet" "openrectbullet" \
	"opentribulletup" "opentribulletdown" "openstar" "enfilledcircbullet" \
	"enfilledsqbullet" "filledtribulletup" "filledtribulletdown" \
	"leftpointer" "rightpointer" "club" "diamond" "heart" "maltesecross" \
	"dagger" "doubledagger" "checkmark" "ballotcross" "musicalsharp" \
	"musicalflat" "malesymbol" "femalesymbol" "telephone" \
	"telephonerecorder" "phonographcopyright" "caret" "singlelowquotemark" \
	"doublelowquotemark" "cursor" "leftcaret" "rightcaret" "downcaret" \
	"upcaret" "overbar" "downtack" "upshoe" "downstile" "underbar" "jot" \
	"quad" "uptack" "circle" "upstile" "downshoe" "rightshoe" "leftshoe" \
	"lefttack" "righttack" "hebrew_aleph" "hebrew_beth" "hebrew_gimmel" \
	"hebrew_daleth" "hebrew_he" "hebrew_waw" "hebrew_zayin" "hebrew_het" \
	"hebrew_teth" "hebrew_yod" "hebrew_finalkaph" "hebrew_kaph" \
	"hebrew_lamed" "hebrew_finalmem" "hebrew_mem" "hebrew_finalnun" \
	"hebrew_nun" "hebrew_samekh" "hebrew_ayin" "hebrew_finalpe" "hebrew_pe" \
	"hebrew_finalzadi" "hebrew_zadi" "hebrew_kuf" "hebrew_resh" \
	"hebrew_shin" "hebrew_taf" "Hebrew_switch" \
    ]

    variable validModifiers [list \
	"Control" "Shift" "Lock" "Meta" "Alt" "B1" "Button1" "B2" "Button2" \
	"B3" "Button3" "B4" "Button4" "B5" "Button5" "Mod1" "M1" "Command" \
	"Mod2" "M2" "Option" "Mod3" "M3" "Mod4" "M4" "Mod5" "M5" "Double" \
	"Triple" "Any" \
    ]

    variable validEvents [list \
	"Key" "KeyPress" "KeyRelease" "Button" "ButtonPress" "ButtonRelease" \
	"Motion" "Enter" "Leave" "FocusIn" "FocusOut" "Expose" "Visibility" \
	"Destroy" "Unmap" "Map" "Reparent" "Configure" "Gravity" "Circulate" \
	"Property" "Colormap" "Activate" "Deactivate" "MouseWheel" \
    ]
    variable builtinBitmaps [list \
	"error" "gray75" "gray50" "gray25" "gray12" "hourglass" "info" \
	"questhead" "question" "warning" "document" "stationery" "edition" \
	"application" "accessory" "folder" "pfolder" "trash" "floppy" "ramdisk" \
	"cdrom" "preferences" "querydoc" "stop" "note" "caution" \
    ]

    variable builtinMasks [list \
        "best" "directcolor" "grayscale" "greyscale" "pseudocolor" \
	"staticcolor" "staticgray" "staticgrey" "truecolor" "default"
    ]

}

# coreTk::init --
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

proc coreTk::init {ver} {
    foreach name [lsort [info vars ::coreTk::checkers*]] {
	analyzer::addCheckers [set $name]
	if {$name == "::coreTk::checkers$ver"} {
	    break
	}
    }
    
    # Add the Tk specific set of widget options.

    analyzer::addWidgetOptions $coreTk::tkWidgetOptions
    return
}

# coreTk::getMessage --
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

proc coreTk::getMessage {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lindex $messages($mid) 0]
    } else {
	return $mid
    }
}

# coreTk::getTypes --
#
#	Convert the message id into a list of message types.
#
# Arguments:
#	mid	The messageID to look up.
#
# Results:
#	Return the list of message type keywords.

proc coreTk::getTypes {mid} {
    variable messages

    if {[info exists messages($mid)]} {
	return [lrange $messages($mid) 1 end]
    } else {
	return err
    }
}

# Checkers for specific types --
#
#	Each type checker performs one or more checks on the type
#	of a given word.  If the word is not a literal value, then
#	it falls through to the generic checkWord procedure.
#
# Arguments:
#	tokens		The list of word tokens for the current command.
#	index		The index of the next word to be checked.
#
# Results:
#	Returns the index of the next token to be checked.


proc coreTk::checkTag {tokens index} {
    # Bindtags - either a window or an arbitrary string
    
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[string index $literal 0] == "."} {
	    return [checkWinName $tokens $index]
	}
    }
    return [checkWord $tokens $index]
}

proc coreTk::checkFontCreateCmd {tokens index} {
    set argc [llength $tokens]
    if {$argc < 3} {
	return 3
    }

    # If the first argument is not a switch, it is an arbitrary word.

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[string index $literal 0] != "-"} {
	    set index [checkWord $tokens $index]
	}
    } else {
	return [checkCommand $tokens $index]
    }
    return [checkConfigure 0 {
	{-family checkWord}
	{-size checkInt}
	{-weight {checkKeyword 1 {normal bold}}}
	{-slant {checkKeyword 1 {roman italic}}}
	{-underline checkBoolean}
	{-overstrike checkBoolean}
    } $tokens $index]
}

proc coreTk::checkWmProtocol {tokens index} {
    # Everything but WM_DELETE_WINDOW is nonportable.
    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {$literal != "WM_DELETE_WINDOW"} {
	    logError nonPortOption [getTokenRange $word] {}
	}
	return [incr index]
    }
    return [checkWord $tokens $index]
}

proc coreTk::checkMessageBox {tokens index} {
    catch {unset ::coreTk::saved}
    set index [checkConfigure 0 {
	{-default {coreTk::SaveValue -default}}
	{-icon {checkKeyword 1 {error info question warning}}}
	{-message checkWord}
	{-parent checkWinName}
	{-title checkWord}
	{-type {coreTk::SaveValue -type}}
    } $tokens $index]

    # Check for type and default consistency
    if {![info exists ::coreTk::saved(-type)] \
	    || ![getLiteral [lindex $tokens $::coreTk::saved(-type)] type]} {
	return $index
    }

    if {[info exists ::coreTk::saved(-default)]} {
	switch -- $type {
	    abortretryignore {
		checkKeyword 1 {abort retry ignore} $tokens \
			$::coreTk::saved(-default)
	    }
	    ok {
		checkKeyword 1 {ok} $tokens \
			$::coreTk::saved(-default)
	    }
	    okcancel {
		checkKeyword 1 {ok cancel} $tokens \
			$::coreTk::saved(-default)
	    }
	    retrycancel {
		checkKeyword 1 {retry cancel} $tokens \
			$::coreTk::saved(-default)
	    }
	    yesno {
		checkKeyword 1 {yes no} $tokens \
			$::coreTk::saved(-default)
	    }
	    yesnocancel {
		checkKeyword 1 {yes no cancel} $tokens \
			$::coreTk::saved(-default)
	    }
	    default {
		checkKeyword 1 {\
		    abortretryignore ok okcancel retrycancel yesno yesnocancel\
	        } $tokens $::coreTk::saved(-default)
	    }
	}
    } else {
	checkKeyword 1 {\
	    abortretryignore ok okcancel retrycancel yesno yesnocancel\
        } $tokens $::coreTk::saved(-type)
    }
    return $index
}

# Save the switch value in ::coreTk::saved if it is a literal

proc coreTk::SaveValue {name tokens index} {
    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    } else {
	set ::coreTk::saved($name) $index
	return [incr index]
    }
}

proc coreTk::checkGeometry {tokens index} {
    # Std. axa+a+a
    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    
    if {($literal != {}) && \
	    (![regexp {^(([0-9])+x([0-9])+)?([-+](-?[0-9]+)[-+](-?[0-9]+))?$} \
	    $literal geom size w h pos x y] \
	    || ($geom == "") \
	    || (($size != "") && ([catch {incr w}] || [catch {incr h}])) \
	    || (($pos != "") && ([catch {incr x}] || [catch {incr y}])))} {
	logError coreTk::badGeometry [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::checkBitmap {tokens index} {
    # Verify the @foo.xbm works in Windows.
    # Flag non-built-in bitmaps as non portable.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }

    # Search for non-portable bitmaps if the literal does not begin 
    # with an @ (filename) or empty string.

    if {([string index $literal 0] != "@") && ($literal != {})} {
	if {[lsearch -exact $coreTk::builtinBitmaps $literal] < 0} {
	    logError coreTk::nonPortBitmap [getTokenRange $word]
	}
    }
    return [incr index]
}

proc coreTk::checkVirtual {tokens index} {
    # Verify the existence of chevrons.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    
    # Make sure the literal matches the Virtual event format and
    # the name of the event is not an empty string.

    if {![regexp {^<<[^<>]+>>$} $literal]} {
	logError coreTk::badVirtual [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::checkEvent {tokens index} {
    # Std. Event for bind. (Version Specific)

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }

    coreTk::CheckEventString $word 0 $literal
    return [incr index]
}

proc coreTk::checkKeysym {tokens index} {
    variable validKeysyms

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {[lsearch -exact $validKeysyms $literal] < 0} {
	logError coreTk::nonPortKeysym [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::checkSequence {noVirtual tokens index} {
    # Check for a sequence of events.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }

    # Skip over all chars until the first "<".  All prior
    # chars are considered keysyms.
    
    set end [string length $literal]
    if {$end > 0} {
	while {[set i [string first "<" $literal]] >= 0} {
	    set startEvent   $i
	    set virtualBegin 0
	    set virtualEnd   0
	    incr i
	    if {[string index $literal $i] == "<"} {
		set virtualBegin 1
	    }
	    
	    # Find the end of the event description.  Log errors
	    # if an ending ">" is not found or a virtual event 
	    # was partially specified or completely specified.
	    
	    set i [string first ">" $literal]
	    if {$i < 0} {
		logError coreTk::badEvent \
			[list [getLiteralPos $word $startEvent] 1]
		break
	    }
	    
	    set endEvent $i
	    incr i
	    if {[string index $literal $i] == ">"} {
		set virtualEnd 1
		incr endEvent
	    }

	    if {$virtualBegin && $virtualEnd && !$noVirtual} {
		# No-op, this is just a valid virtual event.
	    } elseif {$virtualBegin && $virtualEnd && $noVirtual} {
		logError coreTk::noVirtual [list [getLiteralPos $word $i] 1]
	    } elseif {$virtualBegin || $virtualEnd} {
		logError coreTk::badEvent \
			[list [getLiteralPos $word $endEvent] 1]
	    } else {
		coreTk::CheckEventString $word $startEvent \
			[string range $literal $startEvent $endEvent]
	    }
	    set literal [string range $literal $i end]
	}
    } else {
	logError coreTk::noEvent [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::CheckEventString {word offset literal} {
    variable validEvents
    variable validKeysyms
    variable validModifiers

    # Loop over the event string, parsing the individual patterns.
    # An error is logged for any of the following patterns:
    # 
    # <word				(missing ">")
    # <modifier>			(missing event)
    # <... event-modifier>		(modifier after event)
    # <... event-event ...>		(more then one event)
    # <... button-badButtonInteger ...>	(invalid button)
    # <... keypress-badKeysym ...>	(invalid keysym)

    if {[string index $literal 0] != "<"} {
	# Simple string
	return
    }

    if {[regexp {^<<[^<>]+>>$} $literal]} {
	# Valid virtual event
	return
    }
    
    # Verify the "angle-bracket" event type is formed properly

    set pos [expr {[string length $literal]-1}]
    if {[string index $literal $pos] != ">"} {
	logError coreTk::badEvent [list [getLiteralPos $word \
		[expr {$pos + $offset}]] 1]
	return
    }
    
    # Drop the <> from the event string.

    incr pos -1
    set literal [string range $literal 1 $pos]
    incr offset

    set prevType ""

    # Pos will point to the end of each part, so to start we need
    # to set pos to -2 to simulate jumping past the "-".

    set pos -2

    # Skip over any leading modifiers

    while {1} {
	set pat [GetNextEventPart pos offset literal]
	if {$pos == [string length $literal]} {
	    break
	}
	if {[lsearch -exact $validModifiers $pat] < 0} {
	    break
	}
    }

    # Skip the event specifier, if present

    if {[lsearch -exact $validEvents $pat] >= 0} {
	set eventType $pat
	set pat [GetNextEventPart pos offset literal]
    } else {
	set eventType ""
    }

    if {$pat != ""} {
	if {[regexp {^[1-5]$} $pat]} {
	    if {$eventType == ""} {
		# ButtonPress event
	    } elseif {[regexp {^(Key|KeyPress|KeyRelease)$} $eventType]} {
		# KeyPress
		if {[lsearch -exact $validKeysyms $pat] < 0} {
		    logError coreTk::nonPortKeysym [list [getLiteralPos $word \
			    $offset] 1]
		    return
		}
	    } elseif {![regexp {^(Button|ButtonPress|ButtonRelease)$} $eventType]} {
		# Button detail for non-button event
		logError coreTk::badEvent [list [getLiteralPos $word \
			$offset] 1]
		return
	    }
	} else {
	    # Verify this is a valid keysym associated with a key event
	    if {![regexp {^(|Key|KeyPress|KeyRelease)$} $eventType]} {
		logError coreTk::badEvent [list [getLiteralPos $word \
			$offset] 1]
		return
	    } elseif {[lsearch -exact $validKeysyms $pat] < 0} {
		logError coreTk::nonPortKeysym [list [getLiteralPos $word \
			$offset] 1]
		return
	    }
	}
    } elseif {$eventType == ""} {
	# No event type, button number, or keysym was found

	logError coreTk::badEvent [list [getLiteralPos $word \
		$offset] 1]
	return
    }
    
    set pat [GetNextEventPart pos offset literal]
    if {$pat != ""} {
	# Extra characters at end

	logError coreTk::badEvent [list [getLiteralPos $word \
		$offset] 1]
    }
    return
}

proc coreTk::GetNextEventPart {posVar offsetVar literalVar} {
    upvar $posVar pos
    upvar $offsetVar offset
    upvar $literalVar literal

    incr pos 2
    incr offset $pos
    set literal [string range $literal $pos end]

    if {[regexp -indices {.[- ]} $literal match]} {
	set pos [lindex $match 0]
    } else {
	set pos [string length $literal]
    }

    return [string range $literal 0 $pos]
}

proc coreTk::checkGridOptions {tokens index} {
    # Check the grid syntax for implicit row/col placement 
    # then check the grid options.

    set argc [llength $tokens]
    set windowFound  0
    set gridRelFound 0
    set prev ""

    while {$index < $argc} {
	# If it is not a literal, it is assumed to be a
	# variable name.  Call the window name checker.

	set word [lindex $tokens $index]
	if {![getLiteral $word literal]} {
	    set index [checkWinName $tokens $index]
	    set prev ""
	    set windowFound 1
	    continue
	}

	# If the literal begins with a "-" and is not only
	# a "-" then it is an option.  Break out of the loop.

	if {([string index $literal 0] == "-") \
		&& ([string length $literal] > 1)} {
	    break
	}

	# Check to see if the literal is an implicit placement 
	# marker, if not assume it is a window name.

	switch -- $literal {
	    "-" -
	    "x" -
	    "^" {
		# A - may not follow a ^ or a x. 

		if {($literal == "-") && (($prev == "^") || ($prev == "x"))} {
		    logError coreTk::badGridRel [getTokenRange $word]
		}
		set prev $literal
		set gridRelFound 1
		incr index
	    }
	    default {
		# Assumed to be a window name.

		set index [checkWinName $tokens $index]
		set windowFound 1
		set prev ""
	    }
	}
    }

    if {(!$windowFound) && ($gridRelFound)} {
	logError coreTk::badGridMaster [getTokenRange $word]
	return [checkCommand $tokens $index]
    } elseif {!$windowFound} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }

    return [checkWidgetOptions 0 {
	-padx -pady
    } {
	{-column checkWholeNum}
	{-columnspan checkWholeNum}
	{-in checkWinName}
	{-ipadx checkPixels}
	{-ipady checkPixels}
	{-row checkWholeNum}
	{-rowspan checkWholeNum}
	{-sticky coreTk::checkSticky}
    } $tokens $index]
}

proc coreTk::checkSticky {tokens index} {
    # Verify the string is composed of one or more
    # of the following chars: n,w,s, or e.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {![regexp {^([news]+)$} $literal]} {
	logError coreTk::badSticky [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::checkTabs {tokens index} {
    # Check the list of tab stops for valid screen distances followed by
    # an optional position of the tab stop.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {[catch {llength $literal}]} {
	logError coreTk::badTab [getTokenRange $word] 
	return [incr index]
    }

    set errIndex [lindex [getTokenRange $word] 0]
    set errLen   [lindex [getTokenRange $word] 1]
    set errPos   0
    set position 0

    foreach tab $literal {
	# See if the next tab value is a screen distance first.  Strip 
	# off any of the screen distance chars first.  If the value is
	# not a valid float, then (a) check position keywords if the
	# next value can be a position, otherwise log an error.

	set len  [string length $tab]
	set last [expr {$len - 1}]
	if {[regexp {^([0-9\.]+)([cmpi])?$} $tab dummy float]} {
	    if {[catch {expr {abs($float)}}]} {
		set errRange [list [expr {$errIndex + $errPos}] $errLen]
		logError badPixel $errRange
	    }
	    set position 1
	} elseif {$position} {
	    if {![matchKeyword {left right center numeric} $tab 0 x]} {
		set errRange [list [expr {$errIndex + $errPos}] $errLen]
		logError coreTk::badTabJust $errRange $tab
	    }
	    set position 0
	} else {
	    set errRange [list [expr {$errIndex + $errPos}] $errLen]
	    logError badPixel $errRange
	}
	incr errPos [expr {$len + 1}]
    }
    return [incr index]
}

proc checkColormap {tokens index} {
    # Check to see if the literal is "new" or the name of a window.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    
    if {[string compare $literal "new"] == 0} {
	# No-op.
    } elseif {[string index $literal 0] == "."} {
	analyzer::CheckWinNameInternal $literal $word
    } else {
	logError coreTk::badColormap [getTokenRange $word] $literal
    }
    return [incr index]
}

proc coreTk::checkVisual {tokens index} {
    # Check to see if the visual is composed of a valid mask component 
    # and optional depth value.  Valid mask components are: a window 
    # name, a visual ID, or one of the following strings in "builtinMasks"

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    
    if {[catch {llength $literal}]} {
	logError coreTk::badVisual [getTokenRange $word] 
	return [incr index]
    }
    set mask  [lindex $literal 0]
    set depth [lindex $literal 1]
    
    if {[string index $literal 0] == "."} {
	analyzer::CheckWinNameInternal $literal $word
    } elseif {[string compare $literal "default"] == 0} {
	# No-op.
    } elseif {![catch {incr literal}]} {
	# No-op.
    } elseif {[matchKeyword $coreTk::builtinMasks $mask 0 script]} {
	if {($depth != {}) && ([catch {incr depth}])} {
	    set errIndex [lindex [getTokenRange $word] 0]
	    set errLen   [lindex [getTokenRange $word] 1]
	    set errPos   [expr {[string length $mask] + 1}]

	    set errRange [list [expr {$errIndex + $errPos}] $errLen]
	    logError coreTk::badVisualDepth $errRange
	}
    } else {
	logError coreTk::badVisual [getTokenRange $word]
    }
    return [incr index]
}

proc coreTk::checkScreen {tokens index} {
    # First warn because this is a non-portable command (in that it does 
    # nothing useful on any platform but UNIX.)  The check to verify
    # the screen format is valid: <name>:<int>?.<int>?

    set word [lindex $tokens [expr {$index - 1}]]
    logError nonPortOption [getTokenRange $word]
    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    set badScreen 0
    if {[catch {llength $literal}]} {
	set badScreen 1
    } else {
	set parts [split $literal :]
	set coord [lindex $parts 1]

	if {([llength $parts] != 2) \
		|| (![regexp {^([0-9]+)(\.([0-9]+))?$} $coord c x dummy y]) \
		|| ($c == "") \
		|| (($x != "") && [catch {incr x}]) \
		|| (($y != "") && [catch {incr y}])} {
	    set badScreen 1
	}
    }
    if {$badScreen} {
	logError coreTk::badScreen [getTokenRange $word] 
    }
    return [incr index]
}

proc coreTk::checkNameAndPairs {pairs tokens index} {
    set argc [llength $tokens]
    set start $index

    while {$index < $argc} {
	set word [lindex $tokens $index]
	if {![getLiteral $word literal]} {
	    return [checkCommand $tokens $index]
	}
	
	# If this is the first word and it does not begin with a 
	# "-" then it is the name for the image.  Continue checking
	# the next word.

	if {($index == $start) && ([string index $literal 0] != "-")} {
	    incr index
	    continue
	}
	set script ""
	if {![matchKeyword $pairs $literal 0 script]} {
	    set options {}
	    foreach opt $pairs {
		lappend options [lindex $opt 0]
	    }
	    logError badOption [getTokenRange $word] $options $literal 
	    incr index
	    continue
	}
	if {$script == ""} {
	    set script checkWord
	}
	incr index
	if {$index < $argc} {
	    set index [eval $script {$tokens $index}]
	} else {
	    logError noSwitchArg [getTokenRange $word] $literal
	}
    }
    return $argc
}
proc coreTk::checkPalette {tokens index} {
    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }

    # This expression *should* match <float>?/<float>/<float>?

    set exp {^[-+]?([0-9]+(\.[0-9]+)?)(/[-+]?([0-9]+(\.[0-9]+)?)/[-+]?([0-9]+(\.[0-9]+)?))?$}
    if {(![regexp $exp $literal c x x1 sub y y1 z z2]) \
	    || ($c == "") \
	    || (($x != "") && [catch {expr {abs($x)}}]) \
	    || (($sub != "") && [catch {expr {abs($y)}}] && [catch {expr {abs($z)}}])} {
	logError coreTk::badPalette [getTokenRange $word]
    }
    return [incr index]
}
proc coreTk::checkWinThenOptions {options tokens index} {
    # Scan all arguments checking each window name unil the first
    # non-window word is found.  At this point check the configure 
    # options.

    set argc [llength $tokens]
    if {$argc == $index} {
	logError numArgs {}
	return [incr index]
    }

    set start $index
    while {$index < $argc} {
	set word [lindex $tokens $index]
	if {![getLiteral $word literal]} {
	    return [checkCommand $tokens $index]
	}
	if {[string index $literal 0] != "."} {
	    break
	}
	analyzer::CheckWinNameInternal $literal $word
	incr index
    }
    if {$index == $argc} {
	return $index
    } else {
	return [checkConfigure 0 $options $tokens $index]
    }
}

proc coreTk::checkPriority {tokens index} {
    # The priortiy should be widgetDefault, startupFile, userDefault,
    # interactive or an integer between 0 and 100.

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    set priority {widgetDefault startupFile userDefault interactive}
    if {(![matchKeyword $priority $literal 0 x]) \
	    && ([catch {incr literal 0}] \
	    || ($literal < 0) || ($literal > 100))} {
	logError coreTk::badPriority [getTokenRange $word]	    
    }
    return [incr index]
}

proc coreTk::checkSetPalette {tokens index} {
    set argc [llength $tokens]
    if {$argc < 1} {
	logError numArgs {}
	return [checkCommand $tokens $index]
    }
    while {$index < $argc} {
	set index [checkKeyword 1 {\
		activeBackground foreground selectColor\
		activeForeground highlightBackground selectBackground\
		background highlightColor selectForeground\
		disabledForeground insertBackground troughColor\
	    } $tokens $index]
	if {$index == $argc} {
	    logError numArgs {}
	    break
	}
	set index [checkColor $tokens $index]
    }
    return $index
}

proc coreTk::checkNullOrType {type tokens index} {
    # Verify the word is empty string or <type>

    set word [lindex $tokens $index]
    if {![getLiteral $word literal]} {
	return [checkWord $tokens $index]
    }
    if {$literal != {}} {
	return [eval $type {$tokens $index}]
    }
    return [incr index]
}

    
proc coreTk::checkState {tokens index} {
    # Either an integer or a Visibility keyword

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[catch {incr literal}]} {
	    return [checkKeyword 1 {\
		    VisibilityUnobscured VisibilityPartiallyObscured\
		    VisibilityFullyObscured\
		} $tokens $index]
	}
    }
    return [checkWord $tokens $index]
}

proc coreTk::checkRoot {tokens index} {
    # Either an integer or a window name

    set word [lindex $tokens $index]
    if {[getLiteral $word literal]} {
	if {[catch {incr literal}]} {
	    return [checkWinName $tokens $index]
	}
    }
    return [checkWord $tokens $index]
}
