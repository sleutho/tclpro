# licenseWin.tcl --
#
#	This is the module that creates the GUI for entering
#	and verifying the license key.
#
# Copyright (c) 1998-2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: licenseWin.tcl,v 1.6 2000/08/04 22:42:56 welch Exp $

package provide licenseWin 1.0
package require lic

namespace eval licenseWin {
    # Vwait variable that is used when verifying the license key.
    
    variable licWin .licenseWin

    variable buttonInfo
    array set buttonInfo {
	errorDenied {
	    "Quit" licenseWin::licenseWindowDone
	}
	errorNoKey {
	    "Ok" licenseWin::licenseWindowEnterKey
	    "Quit" licenseWin::licenseWindowDone
	}
	errorInvalid {
	    "Change Key" licenseWin::licenseWindowEnterKey
	    "Quit" licenseWin::licenseWindowDone
	}
	errorNoServer {
	    "Change Server" licenseWin::licenseWindowEnterKey
	    "Quit" licenseWin::licenseWindowDone
	}
	warnTempKey {
	    "Continue" licenseWin::licenseWindowDone
	    "Upgrade Key" licenseWin::licenseWindowEnterKey
	}
	warnOverdraft {
	    "Continue" licenseWin::licenseWindowDone
	}
    }

    if {$tcl_platform(platform) == "windows"} {
	variable keyFont {Courier 10}
    } else {
	variable keyFont {courier 12}
    }

    # licCompany Registered name of the licensed user.  We cache this value
    #		so that the "About" box doesn't need to ping the server
    #		again to look it up.

    variable licCompany {}
}

# licenseWin::verifyLicense --
#
# 	Verify the license exists and that it has not expired.
# 	If the license expires in a week, display a warning and
# 	let the user continue.  If the license has expired, 
# 	display the expiration message and exit.
#
# Arguments:
#	args	Ignored
#
# Results:
#	None.

proc licenseWin::verifyLicense {args} {
    variable licCompany
    set status [lic::getMsg dbg {} msg $projectInfo::productName registeredName]
    set licCompany $registeredName

    switch -exact -- $status {
	0 {
	     set status ok
	}
    }
    if {$status == "ok"} {
	return
    }
    licenseWin::showWindow $status $msg
    vwait licenseWin::continue
    if {[string match error* $status]} {
	exit
    }
    return
}

# licenseWin::showWindow --
#
#	Show a standard message that will dissappear when
#	the OK button is pressed.  If there is a URL in the 
#	message (beginning with "http://") it is turned into
#	a hyperlink.
#
# Arguments:
#	type	The type of buttons to show: entercancel or okenter.
#	title	The title of the toplevel.
#	msg	The message to display.
#
# Results:
#	None.

proc licenseWin::showWindow {status msg} {
    variable buttonInfo

    set pad 6

    set top [toplevel $licenseWin::licWin]

    # Set the title
    switch -glob $status {
	errorNoKey {
	    wm title $top "Welcome!"
	}
	error* {
	    wm title $top "Error"
	}
	warn* {
	    wm title $top "Warning"
	}
    }	

    wm resizable $top 0 0
    wm protocol $top WM_DELETE_WINDOW {exit}

    # Create a label widget that wrap the message.  Use the 
    # size of the label to set the size of the text widget.

    set width  330
    set lbl    [label $top.lbl -wraplength $width -text $msg]
    set height [expr {(4 * $pad) + [winfo reqheight $lbl]}]

    # Create the text widget, insert the message and create 
    # hyperlinks if necessary.

    set msgFrm  [frame $top.msgFrm -height $height -width $width]
    set msgText [text $msgFrm.msgText -width 40 -wrap word -cursor {} \
	    -relief flat -bg [$msgFrm cget -bg]]
    bindtags $msgText [list $msgText $top all]
    $msgText tag configure url -underline on -foreground blue

    if {[regexp "(.*)<(http://\[^>\]+)>(.*)" $msg dummy start url end]} {
	$msgText insert end $start
	if {0} {
	    # Bug - the OpenURL binding doesn't work at this early stage
	    # because the preferences have not been initialized.
	    # So, no URL bindings
	    $msgText insert end $url url
	}
	$msgText insert end $url
	$msgText insert end $end
    } else {
	$msgText insert end $msg
    }

    pack $msgText -fill both -expand 1
    pack propagate $msgFrm 0

    $msgText tag bind url <Enter> {
	%W configure -cursor hand2
    }
    $msgText tag bind url <Leave> {
	%W configure -cursor {}
    }
    $msgText tag bind url <ButtonRelease-1> {
	system::openURL [%W get url.first url.last]
    }

    set butFrm [frame $top.butFrm]

    set i 0
    foreach {name action} $buttonInfo($status) {
	incr i
	set but [button $butFrm.but$i -text $name -width 13 -command $action \
		-default normal]
	pack $but -side right -padx $pad
    }
    $butFrm.but1 conf -default active
    bind $top <Return> "$butFrm.but1 invoke"
    focus -force $butFrm.but1

    pack $butFrm  -side bottom -fill x -pady $pad
    pack $msgFrm  -side bottom -fill both -expand 1 -padx $pad -pady $pad

    set width  [winfo reqwidth  $top]
    set height [winfo reqheight $top]
    set w [winfo screenwidth .]
    set h [winfo screenheight .]
    wm geometry $top +[expr {($w/2)-($width/2)}]+[expr {($h/2)-($height/2)}]
    return
}

# licenseWin::licenseWindowDone --
#
#	Either OK or Cancel was selected.  Set the vwait variable
#	and let the app figure out if it should exit or continue
#	to run the app.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc licenseWin::licenseWindowDone {} {
    destroy $licenseWin::licWin
    set licenseWin::continue 1
    return
}

# licenseWin::licenseWindowEnterKey --
#
#	Launch TclPro License and exit.
#
# Arguments:
#	None.
#
# Results:
#	None.

proc licenseWin::licenseWindowEnterKey {} {
    destroy $licenseWin::licWin
    set dir  [file dirname [info nameofexecutable]]

    foreach file  [list \
	    [file join $dir prolicense.exe] \
	    [file join $dir prolicense] \
	    [file join $dir prolicense.bin]] {
	if {[file executable $file]} {
	    exec $file &
	    exit
	}
    }
    tk_messageBox -icon error -type ok \
	     -title $lic::prolicense(title,gui) \
	     -message $lic::prolicense(msg,dbg)
    exit
}

